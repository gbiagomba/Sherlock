use crate::model::{Finding, Mode, RunContext, TargetSpec};
use anyhow::{Context, Result};
use futures::future::join_all;
use regex::Regex;
use serde_json::json;
use std::path::PathBuf;
use tokio::process::Command;
use tokio::sync::Semaphore;
use tokio::time::{timeout, Duration};

mod tool_amass;
mod tool_gobuster;
mod tool_nmap;
mod tool_nuclei;
mod tool_httpx;
#[cfg(test)]
mod tests;

pub trait ToolRunner: Send + Sync {
    fn name(&self) -> &'static str;
    fn category(&self) -> &'static str;
    fn available_hint(&self) -> &'static str { self.name() }
    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob>;
    fn command_for(&self, job: &ToolJob, ctx: &RunContext) -> (String, Vec<String>);
    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, stderr: &str) -> Vec<Finding>;
}

pub struct ToolJob {
    pub target: String,
    pub extra: serde_json::Value,
}

pub fn build_plan(ctx: &RunContext, targets: &[TargetSpec], _exclusions: &[String]) -> String {
    let mut steps: Vec<String> = vec![];
    match ctx.mode {
        Mode::Recon => steps.push("Subdomain enumeration (passive)".into()),
        Mode::Investigate => steps.extend([
            "Subdomain enumeration (brute+passive)".into(),
            "Host discovery (nmap -sn)".into(),
            "Service detection (nmap -sV -sC)".into(),
        ]),
        Mode::Hound => steps.push("Aggressive hunting (nuclei/metasploit if installed)".into()),
    }
    format!("Mode: {:?}\nTargets: {}\nSteps:\n - {}", ctx.mode, targets.len(), steps.join("\n - "))
}

pub async fn execute_plan(ctx: &RunContext, targets: &[TargetSpec], _exclusions: &[String]) -> Result<Vec<Finding>> {
    let mut runners: Vec<std::sync::Arc<dyn ToolRunner>> = vec![];

    match ctx.mode {
        Mode::Recon => {
            runners.push(std::sync::Arc::new(tool_amass::Amass { brute: false }));
        }
        Mode::Investigate => {
            runners.push(std::sync::Arc::new(tool_amass::Amass { brute: true }));
            runners.push(std::sync::Arc::new(tool_gobuster::Gobuster));
            runners.push(std::sync::Arc::new(tool_nmap::NmapHostDiscovery));
            runners.push(std::sync::Arc::new(tool_nmap::NmapServiceScan));
            if ctx.use_httpx { runners.push(std::sync::Arc::new(tool_httpx::Httpx)); }
        }
        Mode::Hound => {
            // Aggressive mode: service detection followed by nuclei
            runners.push(std::sync::Arc::new(tool_nmap::NmapServiceScan));
            if ctx.use_httpx { runners.push(std::sync::Arc::new(tool_httpx::Httpx)); }
            runners.push(std::sync::Arc::new(tool_nuclei::Nuclei));
        }
    };

    let sem = std::sync::Arc::new(Semaphore::new(ctx.concurrency));
    let mut all_findings: Vec<Finding> = vec![];
    let mut current_targets: Vec<TargetSpec> = targets.to_vec();

    for r in runners {
        let category = r.category().to_string();
        let jobs = r.build_jobs(&current_targets);
        if jobs.is_empty() { continue; }

        let mut handles = vec![];
        for job in jobs {
            let permit = sem.clone().acquire_owned().await.unwrap();
            let rref = r.clone();
            let ctx = ctx.clone();
            let job_clone = ToolJob { target: job.target.clone(), extra: job.extra.clone() };
            let handle = tokio::spawn(async move {
                let _p = permit;
                let (prog, args) = rref.command_for(&job_clone, &ctx);
                let res = run_command_timeout(&prog, &args, ctx.timeout_secs).await;
                match res {
                    Ok((stdout, stderr)) => rref.parse_output(&job_clone, &ctx, &stdout, &stderr),
                    Err(e) => vec![Finding::new(rref.name(), rref.category(), &job_clone.target, json!({"error": e.to_string()}), Some("low"), &ctx.timestamp)],
                }
            });
            handles.push(handle);
        }
        let batches = join_all(handles).await;
        let mut new_findings: Vec<Finding> = vec![];
        for b in batches.into_iter().flatten() { new_findings.extend(b); }
        // Feed-forward:
        // - subdomain -> add subdomain to targets
        // - service_scan -> add inferred URLs for common web ports
        if category == "subdomain" {
            for f in &new_findings {
                if let Some(sd) = f.data.get("subdomain").and_then(|v| v.as_str()) {
                    current_targets.push(TargetSpec { raw: sd.to_string() });
                }
            }
        } else if category == "service_scan" {
            for f in &new_findings {
                let host = &f.target;
                if let Some(port) = f.data.get("port").and_then(|v| v.as_str()) {
                    if let Ok(p) = port.parse::<u16>() {
                        if matches!(p, 80 | 8000 | 8080 | 8081) {
                            current_targets.push(TargetSpec { raw: format!("http://{}:{}", host, p) });
                        } else if matches!(p, 443 | 8443) {
                            current_targets.push(TargetSpec { raw: format!("https://{}:{}", host, p) });
                        }
                    }
                }
            }
        }
        all_findings.extend(new_findings);
    }

    Ok(all_findings)
}

async fn run_command_timeout(prog: &str, args: &[String], timeout_secs: u64) -> Result<(String, String)> {
    let mut cmd = Command::new(prog);
    cmd.args(args);
    let child = cmd.output();
    let out = timeout(Duration::from_secs(timeout_secs), child)
        .await
        .context("timeout")??;
    Ok((String::from_utf8_lossy(&out.stdout).to_string(), String::from_utf8_lossy(&out.stderr).to_string()))
}

pub fn binary_exists(bin: &str) -> bool {
    which::which(bin).is_ok()
}

pub fn sanitize_filename(s: &str) -> String {
    let re = Regex::new(r"[^A-Za-z0-9_.-]+").unwrap();
    re.replace_all(s, "_").to_string()
}

pub fn doctor() {
    println!("Sherlock doctor: checking tool availability\n");
    let tools = [
        ("nmap", ["--version"].as_slice()),
        ("amass", ["-version"].as_slice()),
        ("gobuster", ["-V"].as_slice()),
        ("httpx", ["-version"].as_slice()),
        ("nuclei", ["-version"].as_slice()),
    ];
    for (bin, ver) in tools {
        if !binary_exists(bin) {
            println!("- {}: NOT FOUND", bin);
        } else {
            match std::process::Command::new(bin).args(ver).output() {
                Ok(o) => {
                    let mut v = String::from_utf8_lossy(&o.stdout).to_string();
                    if v.trim().is_empty() { v = String::from_utf8_lossy(&o.stderr).to_string(); }
                    let preview = v.lines().next().unwrap_or("").trim().to_string();
                    println!("- {}: {}", bin, if preview.is_empty() { "OK".into() } else { preview });
                }
                Err(_) => println!("- {}: FOUND (version unknown)", bin),
            }
        }
    }
    println!("\nIf a tool is missing, install via:\n- macOS (brew): brew install nmap gobuster amass && brew install projectdiscovery/tap/httpx projectdiscovery/tap/nuclei\n- Debian/Ubuntu (apt): sudo apt-get install nmap gobuster amass golang-go && go install github.com/projectdiscovery/httpx/cmd/httpx@latest && go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest\n- Windows (winget/choco): winget install -e --id Nmap.Nmap; install others via project sites or Scoop/Chocolatey.");
}
