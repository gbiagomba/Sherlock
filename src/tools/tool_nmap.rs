use crate::model::{Finding, RunContext, TargetSpec};
use crate::tools::{binary_exists, ToolJob, ToolRunner};
use quick_xml::events::Event;
use quick_xml::Reader;
use regex::Regex;
use serde_json::json;

pub struct NmapHostDiscovery;
pub struct NmapServiceScan;

impl ToolRunner for NmapHostDiscovery {
    fn name(&self) -> &'static str { "nmap" }
    fn category(&self) -> &'static str { "host_discovery" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets.iter().map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) }).collect()
    }

    fn command_for(&self, job: &ToolJob, _ctx: &RunContext) -> (String, Vec<String>) {
        let args = vec!["-sn".into(), "-oX".into(), "-".into(), job.target.clone()];
        ("nmap".into(), args)
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("nmap") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "nmap not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let mut findings = vec![];
        // Prefer XML parsing
        if stdout.trim_start().starts_with("<?xml") || stdout.contains("<nmaprun") {
            let mut reader = Reader::from_str(stdout);
            reader.trim_text(true);
            let mut buf = Vec::new();
            let mut current_addr: Option<String> = None;
            let mut host_up = false;
            loop {
                match reader.read_event_into(&mut buf) {
                    Ok(Event::Start(ref e)) if e.name().as_ref() == b"host" => { current_addr = None; host_up = false; }
                    Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) if e.name().as_ref() == b"address" => {
                        let mut addr = None;
                        let mut typ = None;
                        for a in e.attributes().flatten() {
                            if a.key.as_ref() == b"addr" { addr = Some(a.unescape_value().unwrap_or_default().to_string()); }
                            if a.key.as_ref() == b"addrtype" { typ = Some(a.unescape_value().unwrap_or_default().to_string()); }
                        }
                        if typ.as_deref() == Some("ipv4") || typ.as_deref() == Some("ipv6") {
                            current_addr = addr;
                        }
                    }
                    Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) if e.name().as_ref() == b"status" => {
                        for a in e.attributes().flatten() {
                            if a.key.as_ref() == b"state" {
                                if a.unescape_value().unwrap_or_default().as_ref() == "up" { host_up = true; }
                            }
                        }
                    }
                    Ok(Event::End(ref e)) if e.name().as_ref() == b"host" => {
                        if host_up {
                            if let Some(h) = current_addr.take() {
                                findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"host": h, "status": "up"}), Some("info"), &ctx.timestamp));
                            }
                        }
                    }
                    Ok(Event::Eof) => break,
                    Err(_) => break,
                    _ => {}
                }
                buf.clear();
            }
        }
        if findings.is_empty() {
            findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no live hosts detected"}), Some("info"), &ctx.timestamp));
        }
        findings
    }
}

impl ToolRunner for NmapServiceScan {
    fn name(&self) -> &'static str { "nmap" }
    fn category(&self) -> &'static str { "service_scan" }

    fn build_jobs(&self, targets: &[TargetSpec]) -> Vec<ToolJob> {
        targets.iter().map(|t| ToolJob { target: t.raw.clone(), extra: json!({}) }).collect()
    }

    fn command_for(&self, job: &ToolJob, _ctx: &RunContext) -> (String, Vec<String>) {
        let args = vec!["-sV".into(), "-sC".into(), "--host-timeout".into(), "120s".into(), "-oX".into(), "-".into(), job.target.clone()];
        ("nmap".into(), args)
    }

    fn parse_output(&self, job: &ToolJob, ctx: &RunContext, stdout: &str, _stderr: &str) -> Vec<Finding> {
        if !binary_exists("nmap") {
            return vec![Finding::new(self.name(), self.category(), &job.target, json!({"warning": "nmap not found in PATH"}), Some("info"), &ctx.timestamp)];
        }
        let mut findings = vec![];
        // Parse XML service details
        if stdout.trim_start().starts_with("<?xml") || stdout.contains("<nmaprun") {
            let mut reader = Reader::from_str(stdout);
            reader.trim_text(true);
            let mut buf = Vec::new();
            let mut current_host: Option<String> = None;
            let mut in_host = false;
            loop {
                match reader.read_event_into(&mut buf) {
                    Ok(Event::Start(ref e)) if e.name().as_ref() == b"host" => { in_host = true; current_host = None; }
                    Ok(Event::End(ref e)) if e.name().as_ref() == b"host" => { in_host = false; }
                    Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) if e.name().as_ref() == b"address" && in_host => {
                        let mut addr = None;
                        let mut typ = None;
                        for a in e.attributes().flatten() {
                            if a.key.as_ref() == b"addr" { addr = Some(a.unescape_value().unwrap_or_default().to_string()); }
                            if a.key.as_ref() == b"addrtype" { typ = Some(a.unescape_value().unwrap_or_default().to_string()); }
                        }
                        if typ.as_deref() == Some("ipv4") || typ.as_deref() == Some("ipv6") { current_host = addr; }
                    }
                    Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) if e.name().as_ref() == b"port" && in_host => {
                        let mut port: Option<String> = None;
                        let mut proto: Option<String> = None;
                        for a in e.attributes().flatten() {
                            if a.key.as_ref() == b"portid" { port = Some(a.unescape_value().unwrap_or_default().to_string()); }
                            if a.key.as_ref() == b"protocol" { proto = Some(a.unescape_value().unwrap_or_default().to_string()); }
                        }
                        // We need to peek nested children for state and service
                        let mut state: Option<String> = None;
                        let mut service: Option<String> = None;
                        let mut depth = 1;
                        let mut inner_buf = Vec::new();
                        loop {
                            match reader.read_event_into(&mut inner_buf) {
                                Ok(Event::Start(ref ee)) if ee.name().as_ref() == b"state" => {
                                    for a in ee.attributes().flatten() {
                                        if a.key.as_ref() == b"state" { state = Some(a.unescape_value().unwrap_or_default().to_string()); }
                                    }
                                }
                                Ok(Event::Empty(ref ee)) if ee.name().as_ref() == b"state" => {
                                    for a in ee.attributes().flatten() {
                                        if a.key.as_ref() == b"state" { state = Some(a.unescape_value().unwrap_or_default().to_string()); }
                                    }
                                }
                                Ok(Event::Start(ref ee)) if ee.name().as_ref() == b"service" => {
                                    for a in ee.attributes().flatten() {
                                        if a.key.as_ref() == b"name" { service = Some(a.unescape_value().unwrap_or_default().to_string()); }
                                    }
                                }
                                Ok(Event::Empty(ref ee)) if ee.name().as_ref() == b"service" => {
                                    for a in ee.attributes().flatten() {
                                        if a.key.as_ref() == b"name" { service = Some(a.unescape_value().unwrap_or_default().to_string()); }
                                    }
                                }
                                Ok(Event::Start(_)) => { depth += 1; }
                                Ok(Event::End(_)) => { depth -= 1; if depth == 0 { break; } }
                                Ok(Event::Eof) => break,
                                Err(_) => break,
                                _ => {}
                            }
                            inner_buf.clear();
                        }
                        if let (Some(h), Some(p), Some(pr), Some(st)) = (current_host.clone(), port, proto, state) {
                            findings.push(Finding::new(self.name(), self.category(), &h, json!({
                                "port": p,
                                "proto": pr,
                                "state": st,
                                "service": service.unwrap_or_default()
                            }), Some(if st=="open" {"medium"} else {"info"}), &ctx.timestamp));
                        }
                    }
                    Ok(Event::Eof) => break,
                    Err(_) => break,
                    _ => {}
                }
                buf.clear();
            }
        }
        if findings.is_empty() {
            findings.push(Finding::new(self.name(), self.category(), &job.target, json!({"note": "no open services parsed"}), Some("info"), &ctx.timestamp));
        }
        findings
    }
}
