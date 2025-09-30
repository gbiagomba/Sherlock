use crate::model::{Finding, RunContext, TargetSpec};
use crate::tools::{binary_exists, ToolJob, ToolRunner};
use serde_json::json;

pub struct Httpx;

impl ToolRunner for Httpx {
    fn name(&self) -> &'static str { "httpx" }
    fn category(&self) -> &'static str { "http_probe" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets
            .iter()
            .filter(|t| {
                let s = t.raw.as_str();
                s.starts_with("http://") || s.starts_with("https://") || s.contains('.')
            })
            .map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) })
            .collect()
    }

    fn command_for(&self, job: &ToolJob, _ctx: &RunContext) -> (String, Vec<String>) {
        // httpx supports -u <target> -json -silent
        ("httpx".into(), vec!["-u".into(), job.target.clone(), "-json".into(), "-silent".into()])
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("httpx") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "httpx not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let mut out = vec![];
        for line in stdout.lines() {
            if line.trim().is_empty() { continue; }
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(line) {
                // Prefer url field
                let url = v.get("url").and_then(|x| x.as_str()).unwrap_or("");
                let status = v.get("status-code").and_then(|x| x.as_i64()).unwrap_or(0);
                let scheme = v.get("scheme").and_then(|x| x.as_str()).unwrap_or("");
                let host = v.get("host").and_then(|x| x.as_str()).unwrap_or("");
                let port = v.get("port").and_then(|x| x.as_i64()).unwrap_or(0);
                out.push(Finding::new(self.name(), self.category(), &job.target, json!({
                    "url": url,
                    "status": status,
                    "scheme": scheme,
                    "host": host,
                    "port": port
                }), Some("info"), &ctx.timestamp));
            }
        }
        if out.is_empty() {
            out.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no httpx results"}), Some("info"), &ctx.timestamp));
        }
        out
    }
}

