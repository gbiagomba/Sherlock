use clap::{Arg, Command};
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::collections::HashSet;
use std::process::Command as ProcessCommand;

/// Reads lines from a given file and returns them as a Vec of strings
fn read_lines<P>(filename: P) -> io::Result<Vec<String>>
where
    P: AsRef<Path>,
{
    let file = File::open(filename)?;
    let reader = io::BufReader::new(file);
    reader.lines().collect()
}

fn main() {
    let matches = Command::new("Sherlock")
        .version("2.0")
        .author("Gilles Biagomba <your-email@example.com>")
        .about("Web application recon automation tool")
        .arg(
            Arg::new("target")
                .short('t')
                .long("target")
                .value_parser(clap::value_parser!(String))
                .help("Specifies a single target (hostname or IP address)")
        )
        .arg(
            Arg::new("target_file")
                .short('f')
                .long("target-file")
                .value_parser(clap::value_parser!(String))
                .help("File containing a list of targets to scan")
        )
        .arg(
            Arg::new("exclude")
                .short('e')
                .long("exclude")
                .value_parser(clap::value_parser!(String))
                .help("File containing targets to exclude from the scan")
        )
        .get_matches();

    let mut targets = HashSet::new();
    
    // Handle single target
    if let Some(target) = matches.get_one::<String>("target") {
        targets.insert(target.to_string());
    }

    // Handle multiple targets from file
    if let Some(file) = matches.get_one::<String>("target_file") {
        match read_lines(file) {
            Ok(lines) => {
                for line in lines {
                    targets.insert(line);
                }
            },
            Err(err) => eprintln!("Error reading target file: {}", err),
        }
    }

    // Handle exclusion file
    let mut exclusions = HashSet::new();
    if let Some(exclude_file) = matches.get_one::<String>("exclude") {
        match read_lines(exclude_file) {
            Ok(lines) => {
                for line in lines {
                    exclusions.insert(line);
                }
            },
            Err(err) => eprintln!("Error reading exclusion file: {}", err),
        }
    }

    // Filter out the excluded targets
    let filtered_targets: Vec<_> = targets.difference(&exclusions).collect();

    // If no targets, show error
    if filtered_targets.is_empty() {
        eprintln!("No valid targets to scan after exclusions.");
        return;
    }

    // Execute scan for each target
    for target in filtered_targets {
        println!("Scanning target: {}", target);

        // Running nmap as an example external command (can be substituted with other tools)
        let output = ProcessCommand::new("nmap")
            .arg("-sS")
            .arg(target)
            .output()
            .expect("Failed to execute scan");

        if output.status.success() {
            println!("nmap output:\n{}", String::from_utf8_lossy(&output.stdout));
        } else {
            eprintln!("Error scanning {}: {}", target, String::from_utf8_lossy(&output.stderr));
        }
    }
}