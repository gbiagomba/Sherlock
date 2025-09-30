use crate::model::Finding;
use anyhow::{Context, Result};
use csv::WriterBuilder;
use serde_json::{json, Value};
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};

pub fn generate_reports(out_dir: &Path) -> Result<()> {
    let findings_path = out_dir.join("findings.jsonl");
    let findings = read_findings(findings_path)?;

    let json_out = out_dir.join("report.json");
    serde_json::to_writer_pretty(File::create(json_out)?, &findings)?;

    let csv_out = out_dir.join("report.csv");
    let mut wtr = WriterBuilder::new().from_path(csv_out)?;
    wtr.write_record(["tool", "category", "target", "severity", "timestamp", "data"])?;
    for f in &findings {
        wtr.write_record([
            f.tool.as_str(),
            f.category.as_str(),
            f.target.as_str(),
            f.severity.as_deref().unwrap_or(""),
            f.timestamp.as_str(),
            f.data.to_string().as_str(),
        ])?;
    }
    wtr.flush()?;

    let txt_out = out_dir.join("report.txt");
    let mut txt = File::create(txt_out)?;
    for f in &findings {
        writeln!(
            txt,
            "[{}] {} {} {}\n  {}\n",
            f.timestamp,
            f.tool,
            f.category,
            f.target,
            f.data
        )?;
    }

    let html_out = out_dir.join("report.html");
    let mut html = File::create(html_out)?;
    html.write_all(render_html(&findings).as_bytes())?;

    // Service inventory CSV
    let mut svc = WriterBuilder::new().from_path(out_dir.join("services.csv"))?;
    svc.write_record(["target", "host", "port", "proto", "state", "service"])?;
    for f in &findings {
        if f.category == "service_scan" {
            let host = f.target.as_str();
            let port = f.data.get("port").and_then(|v| v.as_str()).unwrap_or("");
            let proto = f.data.get("proto").and_then(|v| v.as_str()).unwrap_or("");
            let state = f.data.get("state").and_then(|v| v.as_str()).unwrap_or("");
            let service = f.data.get("service").and_then(|v| v.as_str()).unwrap_or("");
            svc.write_record([host, host, port, proto, state, service])?;
        }
    }
    svc.flush()?;
    Ok(())
}

pub fn generate_mindpalace(out_dir: &Path) -> Result<()> {
    let findings_path = out_dir.join("findings.jsonl");
    let findings = read_findings(findings_path)?;
    let graph = build_graph(&findings);
    let graph_path = out_dir.join("graph.json");
    serde_json::to_writer_pretty(File::create(&graph_path)?, &graph)?;
    let mut html = File::create(out_dir.join("mindpalace.html"))?;
    html.write_all(render_graph_html().as_bytes())?;
    Ok(())
}

fn read_findings(path: PathBuf) -> Result<Vec<Finding>> {
    let f = File::open(path).context("opening findings.jsonl")?;
    let r = BufReader::new(f);
    let mut out = vec![];
    for line in r.lines() {
        let l = line?;
        if l.trim().is_empty() { continue; }
        let f: Finding = serde_json::from_str(&l)?;
        out.push(f);
    }
    Ok(out)
}

fn render_html(findings: &[Finding]) -> String {
    let mut rows = String::new();
    for f in findings {
        rows.push_str(&format!(
            "<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td><td><pre>{}</pre></td></tr>\n",
            h(&f.tool), h(&f.category), h(&f.target), h(f.severity.as_deref().unwrap_or("")), h(&f.data.to_string())
        ));
    }
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\"><title>Sherlock Report</title>
        <style>body{{font-family:sans-serif}} table{{border-collapse:collapse;width:100%}} td,th{{border:1px solid #ccc;padding:4px}} pre{{white-space:pre-wrap;word-wrap:break-word}}</style>
        </head><body><h1>Sherlock Report</h1><table><thead><tr><th>Tool</th><th>Category</th><th>Target</th><th>Severity</th><th>Data</th></tr></thead><tbody>{}</tbody></table></body></html>",
        rows
    )
}

fn build_graph(findings: &[Finding]) -> Value {
    let mut nodes: Vec<Value> = vec![];
    let mut edges: Vec<Value> = vec![];
    use std::collections::{HashMap, HashSet};
    let mut idx: HashMap<String, usize> = HashMap::new();
    let mut ensure = |key: String, kind: &str| {
        if let Some(i) = idx.get(&key) { return *i; }
        let i = nodes.len();
        nodes.push(json!({"id": i, "label": key, "kind": kind}));
        idx.insert(key, i);
        i
    };
    for f in findings {
        let t_id = ensure(f.target.clone(), "target");
        match f.category.as_str() {
            "subdomain" => {
                if let Some(sd) = f.data.get("subdomain").and_then(|v| v.as_str()) {
                    let s_id = ensure(sd.to_string(), "subdomain");
                    edges.push(json!({"source": t_id, "target": s_id}));
                }
            }
            "host_discovery" => {
                if let Some(h) = f.data.get("host").and_then(|v| v.as_str()) {
                    let h_id = ensure(h.to_string(), "host");
                    edges.push(json!({"source": t_id, "target": h_id}));
                }
            }
            "service_scan" => {
                if let Some(p) = f.data.get("port").and_then(|v| v.as_str()) {
                    let svc_label = format!("{}:{}", f.target, p);
                    let s_id = ensure(svc_label, "service");
                    edges.push(json!({"source": t_id, "target": s_id}));
                }
            }
            _ => {}
        }
    }
    json!({"nodes": nodes, "edges": edges})
}

fn render_graph_html() -> String {
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>Sherlock Mindpalace</title><style>
    body{font-family:sans-serif} #stage{display:flex} #list{width:30%;overflow:auto} #viz{width:70%;height:80vh;border-left:1px solid #ccc}
    circle{fill:#4e79a7} line{stroke:#bbb}
    </style></head><body><h1>Sherlock Mindpalace</h1>
    <div id=stage><div id=list></div><svg id=viz></svg></div>
    <script>
    async function load(){
      const resp = await fetch('graph.json');
      const g = await resp.json();
      const list = document.getElementById('list');
      list.innerHTML = '<h3>Nodes</h3>' + g.nodes.map(n=>`<div>[${n.kind}] ${n.label}</div>`).join('');
      const svg = document.getElementById('viz');
      const w = svg.clientWidth, h = svg.clientHeight; svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
      const nodes = g.nodes.map((n,i)=>({x:Math.random()*w,y:Math.random()*h,id:n.id,label:n.label,kind:n.kind}));
      const edges = g.edges.map(e=>({source:nodes.find(n=>n.id===e.source), target:nodes.find(n=>n.id===e.target)}));
      function tick(){
        for(let i=0;i<200;i++){
          for(const e of edges){
            const dx=e.target.x-e.source.x, dy=e.target.y-e.source.y; const d=Math.hypot(dx,dy)||1; const f= (d-120)/d*0.01; e.source.x+=dx*f; e.source.y+=dy*f; e.target.x-=dx*f; e.target.y-=dy*f;
          }
        }
        draw();
      }
      function draw(){
        svg.innerHTML = '';
        for(const e of edges){ let l=document.createElementNS('http://www.w3.org/2000/svg','line'); l.setAttribute('x1',e.source.x); l.setAttribute('y1',e.source.y); l.setAttribute('x2',e.target.x); l.setAttribute('y2',e.target.y); svg.appendChild(l); }
        for(const n of nodes){ let c=document.createElementNS('http://www.w3.org/2000/svg','circle'); c.setAttribute('cx',n.x); c.setAttribute('cy',n.y); c.setAttribute('r',6); svg.appendChild(c);
          let t=document.createElementNS('http://www.w3.org/2000/svg','text'); t.textContent=n.label; t.setAttribute('x',n.x+8); t.setAttribute('y',n.y+4); t.setAttribute('font-size','10'); svg.appendChild(t); }
      }
      tick();
    }
    load();
    </script></body></html>".to_string()
}

fn h(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}
