#[cfg(test)]
mod tests {
    use crate::model::{Finding, RunContext, TargetSpec, Mode};
    use crate::tools::{tool_amass::Amass, tool_gobuster::Gobuster, tool_nmap::{NmapHostDiscovery, NmapServiceScan}, tool_nuclei::Nuclei, tool_httpx::Httpx, ToolJob, ToolRunner};
    use serde_json::json;
    use std::path::PathBuf;

    fn ctx() -> RunContext {
        RunContext { project: "test".into(), mode: Mode::Investigate, out_dir: PathBuf::from("/tmp"), timeout_secs: 5, concurrency: 2, wordlist: None, timestamp: "2025-01-01T00:00:00Z".into(), dry_run: true, use_httpx: true, nuclei_templates: None, nuclei_severity: None }
    }

    #[test]
    fn amass_parse_json_lines() {
        let a = Amass { brute: false };
        let job = ToolJob { target: "example.com".into(), extra: json!({}) };
        let out = r#"{"name":"a.example.com"}
{"name":"b.example.com"}"#;
        let f = a.parse_output(&job, &ctx(), out, "");
        assert!(f.iter().any(|x| x.data["subdomain"]=="a.example.com"));
        assert!(f.iter().any(|x| x.data["subdomain"]=="b.example.com"));
    }

    #[test]
    fn gobuster_parse_found_lines() {
        let g = Gobuster;
        let job = ToolJob { target: "example.com".into(), extra: json!({}) };
        let out = "Found: admin.example.com\nFound: api.example.com";
        let f = g.parse_output(&job, &ctx(), out, "");
        assert!(f.iter().any(|x| x.data["subdomain"]=="admin.example.com"));
        assert!(f.iter().any(|x| x.data["subdomain"]=="api.example.com"));
    }

    #[test]
    fn nmap_host_discovery_xml() {
        let n = NmapHostDiscovery;
        let job = ToolJob { target: "example.com".into(), extra: json!({}) };
        let xml = r#"<?xml version='1.0'?>
<nmaprun><host><status state='up'/><address addr='192.0.2.10' addrtype='ipv4'/></host></nmaprun>"#;
        let f = n.parse_output(&job, &ctx(), xml, "");
        assert!(f.iter().any(|x| x.data["host"]=="192.0.2.10"));
    }

    #[test]
    fn nmap_service_scan_xml() {
        let n = NmapServiceScan;
        let job = ToolJob { target: "example.com".into(), extra: json!({}) };
        let xml = r#"<?xml version='1.0'?>
<nmaprun><host><address addr='192.0.2.20' addrtype='ipv4'/><ports>
<port protocol='tcp' portid='80'><state state='open'/><service name='http'/></port>
<port protocol='tcp' portid='22'><state state='closed'/><service name='ssh'/></port>
</ports></host></nmaprun>"#;
        let f = n.parse_output(&job, &ctx(), xml, "");
        assert!(f.iter().any(|x| x.data["port"]=="80" && x.data["service"]=="http"));
        assert!(f.iter().any(|x| x.data["port"]=="22" && x.data["service"]=="ssh"));
    }

    #[test]
    fn nuclei_jsonl_parse() {
        let nu = Nuclei;
        let job = ToolJob { target: "https://example.com".into(), extra: json!({}) };
        let out = r#"{"template":"cve-2021-XXXXX","severity":"medium","matched-at":"https://example.com/login"}
{"template":"misconfig","severity":"low","host":"https://example.com"}"#;
        let f = nu.parse_output(&job, &ctx(), out, "");
        assert!(f.len()>=2);
        assert!(f.iter().any(|x| x.severity.as_deref()==Some("medium")));
    }

    #[test]
    fn httpx_jsonl_parse() {
        let h = Httpx;
        let job = ToolJob { target: "example.com".into(), extra: json!({}) };
        let out = r#"{"url":"https://example.com","host":"example.com","port":443,"scheme":"https","status-code":200}
{"url":"http://example.com:8080","host":"example.com","port":8080,"scheme":"http","status-code":302}"#;
        let f = h.parse_output(&job, &ctx(), out, "");
        assert!(f.iter().any(|x| x.data["url"]=="https://example.com"));
        assert!(f.iter().any(|x| x.data["port"]==8080));
    }
}
