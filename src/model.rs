use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TargetSpec {
    pub raw: String,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Mode {
    Recon,
    Investigate,
    Hound,
}

#[derive(Clone, Debug)]
pub struct RunContext {
    pub project: String,
    pub mode: Mode,
    pub out_dir: PathBuf,
    pub timeout_secs: u64,
    pub concurrency: usize,
    pub wordlist: Option<PathBuf>,
    pub timestamp: String,
    pub dry_run: bool,
    pub use_httpx: bool,
    pub nuclei_templates: Option<PathBuf>,
    pub nuclei_severity: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Finding {
    pub tool: String,
    pub category: String,
    pub target: String,
    pub data: serde_json::Value,
    pub severity: Option<String>,
    pub timestamp: String,
}

impl Finding {
    pub fn new(tool: &str, category: &str, target: &str, data: serde_json::Value, severity: Option<&str>, ts: &str) -> Self {
        Self {
            tool: tool.to_string(),
            category: category.to_string(),
            target: target.to_string(),
            data,
            severity: severity.map(|s| s.to_string()),
            timestamp: ts.to_string(),
        }
    }
}
