mod model;
mod report;
mod tools;

use anyhow::{bail, Context, Result};
use clap::{Arg, ArgAction, Command};
use model::{Finding, Mode, RunContext, TargetSpec};
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::time::SystemTime;
use time::format_description::well_known::Rfc3339;

fn read_lines<P: AsRef<Path>>(filename: P) -> io::Result<Vec<String>> {
    let f = File::open(filename)?;
    let r = BufReader::new(f);
    r.lines().collect()
}

fn now_rfc3339() -> String {
    let now = SystemTime::now();
    let dt: time::OffsetDateTime = now.into();
    dt.format(&Rfc3339).unwrap_or_else(|_| "".to_string())
}

#[tokio::main]
async fn main() -> Result<()> {
    let matches = Command::new("Sherlock")
        .version("2.0")
        .about("Web application recon automation tool")
        .subcommand_required(true)
        .arg(
            Arg::new("project")
                .short('p')
                .long("project")
                .value_name("NAME")
                .help("Project name used to group outputs"),
        )
        .arg(
            Arg::new("out")
                .short('o')
                .long("out")
                .value_name("DIR")
                .help("Output directory (default: work/<timestamp>_<project>)"),
        )
        .arg(
            Arg::new("timeout")
                .long("timeout")
                .value_name("SECS")
                .default_value("600")
                .help("Per-tool timeout in seconds"),
        )
        .arg(
            Arg::new("concurrency")
                .long("concurrency")
                .value_name("N")
                .default_value("8")
                .help("Max concurrent tasks"),
        )
        .arg(
            Arg::new("wordlist")
                .long("wordlist")
                .short('w')
                .value_name("FILE")
                .help("Wordlist for DNS bruteforce (gobuster)"),
        )
        .arg(
            Arg::new("dry_run")
                .long("dry-run")
                .action(ArgAction::SetTrue)
                .help("Print the plan without executing tools"),
        )
        .arg(
            Arg::new("use_httpx")
                .long("use-httpx")
                .action(ArgAction::SetTrue)
                .help("Enable httpx probing and feed results into nuclei"),
        )
        .arg(
            Arg::new("nuclei_templates")
                .long("nuclei-templates")
                .value_name("PATH")
                .help("Path to nuclei templates directory or file"),
        )
        .arg(
            Arg::new("nuclei_severity")
                .long("nuclei-severity")
                .value_name("LIST")
                .help("Comma-separated nuclei severities to include (e.g., critical,high,medium)"),
        )
        .subcommand(
            Command::new("recon")
                .about("Passive reconnaissance: subdomain enumeration without intrusive brute force")
                .arg(target_arg())
                .arg(target_file_arg())
                .arg(exclude_arg()),
        )
        .subcommand(
            Command::new("investigate")
                .about("Full automated scan: recon to basic service discovery")
                .arg(target_arg())
                .arg(target_file_arg())
                .arg(exclude_arg()),
        )
        .subcommand(
            Command::new("hound")
                .about("Aggressive hunting leveraging known weaknesses. Requires external tools if installed.")
                .arg(target_arg())
                .arg(target_file_arg())
                .arg(exclude_arg()),
        )
        .subcommand(
            Command::new("report")
                .about("Generate consolidated reports (json, csv, html, txt) from findings")
                .arg(
                    Arg::new("source")
                        .long("source")
                        .short('s')
                        .value_name("DIR")
                        .help("Directory containing findings.jsonl (defaults to --out)"),
                ),
        )
        .subcommand(
            Command::new("mindpalace")
                .about("Create a visual map from findings")
                .arg(
                    Arg::new("source")
                        .long("source")
                        .short('s')
                        .value_name("DIR")
                        .help("Directory containing findings.jsonl (defaults to --out)"),
                ),
        )
        .subcommand(
            Command::new("doctor")
                .about("Check environment for required external tools and print versions"),
        )
        .get_matches();

    let project = matches.get_one::<String>("project").map(|s| s.to_string());
    let out = matches.get_one::<String>("out").map(PathBuf::from);
    let timeout_secs = matches
        .get_one::<String>("timeout")
        .unwrap()
        .parse::<u64>()
        .unwrap_or(600);
    let concurrency = matches
        .get_one::<String>("concurrency")
        .unwrap()
        .parse::<usize>()
        .unwrap_or(8);
    let mut wordlist = matches.get_one::<String>("wordlist").map(PathBuf::from);
    if wordlist.is_none() {
        let default = PathBuf::from("rsc/subdomains.list");
        if default.exists() { wordlist = Some(default); }
    }
    let dry_run = matches.get_flag("dry_run");
    let use_httpx = matches.get_flag("use_httpx");
    let nuclei_templates = matches.get_one::<String>("nuclei_templates").map(PathBuf::from);
    let nuclei_severity = matches.get_one::<String>("nuclei_severity").cloned();

    match matches.subcommand() {
        Some((cmd, sub_m)) if ["recon", "investigate", "hound"].contains(&cmd) => {
            let mode = match cmd { "recon" => Mode::Recon, "investigate" => Mode::Investigate, _ => Mode::Hound };
            let (targets, exclusions) = collect_targets(sub_m)?;
            if targets.is_empty() {
                bail!("No targets provided. Use -t/--target or -f/--target-file.");
            }
            let out_dir = resolve_out_dir(out, &project)?;
            if !dry_run { fs::create_dir_all(&out_dir).ok(); }
            let findings_path = out_dir.join("findings.jsonl");
            let ctx = RunContext {
                project: project.clone().unwrap_or_else(|| "default".into()),
                mode,
                out_dir: out_dir.clone(),
                timeout_secs,
                concurrency,
                wordlist,
                timestamp: now_rfc3339(),
                dry_run,
                use_httpx,
                nuclei_templates,
                nuclei_severity,
            };

            let plan = tools::build_plan(&ctx, &targets, &exclusions);
            if dry_run {
                println!("Plan:\n{}", plan);
                return Ok(());
            }

            let mut writer = File::create(&findings_path).context("creating findings.jsonl")?;
            let results = tools::execute_plan(&ctx, &targets, &exclusions).await?;
            for f in results {
                serde_json::to_writer(&mut writer, &f)?;
                writer.write_all(b"\n")?;
            }
            println!("Findings written to {}", findings_path.display());
        }
        Some(("report", sub_m)) => {
            let out_dir = sub_m
                .get_one::<String>("source")
                .map(PathBuf::from)
                .or(out)
                .context("provide --source or --out to locate findings")?;
            report::generate_reports(&out_dir)?;
            println!("Report generated in {}", out_dir.display());
        }
        Some(("mindpalace", sub_m)) => {
            let out_dir = sub_m
                .get_one::<String>("source")
                .map(PathBuf::from)
                .or(out)
                .context("provide --source or --out to locate findings")?;
            report::generate_mindpalace(&out_dir)?;
            println!("Mindpalace generated in {}", out_dir.display());
        }
        Some(("doctor", _)) => {
            tools::doctor();
        }
        _ => unreachable!(),
    }

    Ok(())
}

fn target_arg() -> Arg {
    Arg::new("target")
        .short('t')
        .long("target")
        .value_name("TARGET")
        .help("Single target (hostname/IP/CIDR). Repeatable.")
        .action(ArgAction::Append)
}

fn target_file_arg() -> Arg {
    Arg::new("target_file")
        .short('f')
        .long("target-file")
        .value_name("FILE")
        .help("File with list of targets")
}

fn exclude_arg() -> Arg {
    Arg::new("exclude")
        .short('e')
        .long("exclude")
        .value_name("FILE")
        .help("File with exclusions")
}

fn resolve_out_dir(out: Option<PathBuf>, project: &Option<String>) -> Result<PathBuf> {
    if let Some(p) = out { return Ok(p); }
    let ts = chrono_like_ts();
    let p = project.clone().unwrap_or_else(|| "default".into());
    Ok(PathBuf::from(format!("work/{}_{}", ts, p)))
}

fn chrono_like_ts() -> String {
    let now = SystemTime::now();
    let dt: time::OffsetDateTime = now.into();
    let fmt = time::format_description::parse("[year].[month].[day]-[hour].[minute].[second]").unwrap();
    dt.format(&fmt).unwrap_or_else(|_| "now".into())
}

fn collect_targets(m: &clap::ArgMatches) -> Result<(Vec<TargetSpec>, Vec<String>)> {
    let mut targets: Vec<String> = vec![];
    if let Some(vals) = m.get_many::<String>("target") {
        for v in vals { targets.push(v.to_string()); }
    }
    if let Some(file) = m.get_one::<String>("target_file") {
        for line in read_lines(file)? { if !line.trim().is_empty() { targets.push(line.trim().to_string()); } }
    }
    let exclusions = if let Some(exf) = m.get_one::<String>("exclude") {
        read_lines(exf)?.into_iter().map(|s| s.trim().to_string()).collect()
    } else { vec![] };
    let targets: Vec<TargetSpec> = targets
        .into_iter()
        .filter(|t| !exclusions.iter().any(|e| e == t))
        .map(|t| TargetSpec{ raw: t })
        .collect();
    Ok((targets, exclusions))
}
