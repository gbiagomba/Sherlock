use crate::model::{Finding, RunContext, TargetSpec};
use crate::tools::{binary_exists, ToolJob, ToolRunner};
use serde_json::json;

pub struct Nuclei;

impl ToolRunner for Nuclei {
    fn name(&self) -> &'static str { "nuclei" }
    fn category(&self) -> &'static str { "vulnerability" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets
            .iter()
            .filter(|t| t.raw.starts_with("http://") || t.raw.starts_with("https://"))
            .map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) })
            .collect()
    }

    fn command_for(&self, job: &ToolJob, ctx: &RunContext) -> (String, Vec<String>) {
        let mut args = vec!["-u".into(), job.target.clone(), "-jsonl".into(), "-silent".into()];
        if let Some(tpl) = &ctx.nuclei_templates { args.extend(["-t".into(), tpl.display().to_string()]); }
        if let Some(sev) = &ctx.nuclei_severity { args.extend(["-severity".into(), sev.clone()]); }
        ("nuclei".into(), args)
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("nuclei") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "nuclei not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let mut findings = vec![];
        for line in stdout.lines() {
            if line.trim().is_empty() { continue; }
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(line) {
                let sev_owned = v.get("severity").and_then(|x| x.as_str()).unwrap_or("info").to_string();
                findings.push(Finding::new(self.name(), self.category(), &job.target, v, Some(&sev_owned), &ctx.timestamp));
            }
        }
        if findings.is_empty() {
            findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no nuclei findings"}), Some("info"), &ctx.timestamp));
        }
        findings
    }
}
