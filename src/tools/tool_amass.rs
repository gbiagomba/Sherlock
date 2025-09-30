use crate::model::{Finding, RunContext, TargetSpec};
use crate::tools::{sanitize_filename, ToolJob, ToolRunner, binary_exists};
use serde_json::json;

pub struct Amass { pub brute: bool }

impl ToolRunner for Amass {
    fn name(&self) -> &'static str { "amass" }
    fn category(&self) -> &'static str { "subdomain" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets
            .iter()
            .filter(|t| t.raw.contains('.'))
            .map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) })
            .collect()
    }

    fn command_for(&self, job: &ToolJob, _ctx: &RunContext) -> (String, Vec<String>) {
        let mut args = vec!["enum".to_string(), "-d".into(), job.target.clone(), "-json".into(), "-".into()];
        if self.brute { args.push("-brute".into()); }
        ("amass".into(), args)
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("amass") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "amass not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let mut findings = vec![];
        for line in stdout.lines() {
            if line.trim().is_empty() { continue; }
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(line) {
                // amass JSON sometimes provides 'name'; fallback to 'fqdn'
                let name = v.get("name")
                    .and_then(|x| x.as_str())
                    .or_else(|| v.get("fqdn").and_then(|x| x.as_str()))
                    .unwrap_or("");
                findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"subdomain": name, "raw": v}), Some("info"), &ctx.timestamp));
            }
        }
        if findings.is_empty() {
            findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no results or parse failure"}), Some("info"), &ctx.timestamp));
        }
        findings
    }
}
