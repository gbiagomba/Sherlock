use crate::model::{Finding, RunContext, TargetSpec};
use crate::tools::{binary_exists, ToolJob, ToolRunner};
use regex::Regex;
use serde_json::json;

pub struct Gobuster;

impl ToolRunner for Gobuster {
    fn name(&self) -> &'static str { "gobuster" }
    fn category(&self) -> &'static str { "subdomain" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets
            .iter()
            .filter(|t| t.raw.contains('.'))
            .map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) })
            .collect()
    }

    fn command_for(&self, job: &ToolJob, ctx: &RunContext) -> (String, Vec<String>) {
        let mut args = vec!["dns".into(), "-d".into(), job.target.clone(), "-q".into(), "-t".into(), "25".into()];
        if let Some(w) = &ctx.wordlist { args.extend(["-w".into(), w.display().to_string()]); }
        ("gobuster".into(), args)
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("gobuster") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "gobuster not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let re = Regex::new(r"(?i)found:\s*([A-Za-z0-9_.-]+)").unwrap();
        let mut findings = vec![];
        for line in stdout.lines() {
            if let Some(cap) = re.captures(line) {
                if let Some(m) = cap.get(1) {
                    let sub = m.as_str();
                    findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"subdomain": sub, "raw": line}), Some("info"), &ctx.timestamp));
                }
            }
        }
        if findings.is_empty() {
            findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no results or parse failure"}), Some("info"), &ctx.timestamp));
        }
        findings
    }
}

