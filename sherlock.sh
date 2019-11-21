#!/usr/bin/env bash
# Author: Gilles Biagomba
# Program: Sherlock.sh
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specficailly recon).\n

# for debugging purposes
# set -eux
trap "echo Booh!" SIGINT SIGTERM

# Checking if the user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Declaring variables
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"
wrktmp=$(mktemp -d)
targets=$1
API_AK="" #Tenable Access Key
API_SK="" #Tenable Secret Key

# Setting Envrionment
mkdir -p  $wrkpth/Halberd/ $wrkpth/Sublist3r/ $wrkpth/Harvester/ $wrkpth/Metagoofil/
mkdir -p $wrkpth/Nikto/ $wrkpth/Gobuster/ $wrkpth/Nmap/ $wrkpth/Wappalyzer/ 
mkdir -p $wrkpth/Masscan/ $wrkpth/Arachni/ $wrkpth/TestSSL/ $wrkpth/SSLScan/
mkdir -p $wrkpth/JexBoss/ $wrkpth/XSStrike/ $wrkpth/Grabber/ $wrkpth/GOLismero/
mkdir -p $wrkpth/EyeWitness/ $wrkpth/DNS_Recon/ $wrkpth/SSH/ $wrkpth/RetieJS/

# Moving back to original workspace & loading logo
cd $pth
echo "
 _____  _               _            _    _ 
/ ____ | |             | |          | |  | |
| (___ | |__   ___ _ __| | ___   ___| | _| |
\___  \| '_ \ / _ \ '__| |/ _ \ / __| |/ / |
____)  | | | |  __/ |  | | (_) | (__|   <| |
|_____/|_| |_|\___|_|  |_|\___/ \___|_|\_(_)
"
echo "Web application scanning is elementary my dear Watson!"
echo

# Requesting target file name or checking the target file exists & requesting the project name
if [ -z $targets ]; then
    echo "What is the name of the targets file? The file with all the IP addresses or sites"
    read targets
    echo
elif [ ! -e $targets ]; then
    echo "File not found! Try again!"
    exit
fi

echo "What is the name of the project?"
read prj_name
echo

# Recording screen output
# exec >|$PWD/$prj_name-term_output.log 2>&1

# Parsing the target file
cat $pth/$targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" > $wrktmp/WebTargets
cat $pth/$targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $wrktmp/TempTargets
cat $pth/$targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> $wrktmp/TempTargets
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
echo

# Using sublist3r 
echo "--------------------------------------------------"
echo "Performing scan using Sublist3r (1 of 25)"
echo "--------------------------------------------------"
# consider replacing with  gobuster -m dns -o gobuster_output.txt -u example.com -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt"
# gobuster -m dns -cn -e -i -r -t 25 -w /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o "$wrkpth/Gobuster/$prj_name-gobuster_dns_output-$web.txt" -u example.com
for web in $(cat $wrktmp/WebTargets); do
	sublist3r -d $web -v -t 25 -o "$wrkpth/Sublist3r/$prj_name-$web-sublist3r_output.txt"
    if [ -r wrkpth/Sublist3r/$prj_name-$web-sublist3r_output.txt ] || [ -s wrkpth/Sublist3r/$prj_name-$web-sublist3r_output.txt ]; then
        cat $wrkpth/Sublist3r/$prj_name-$web-sublist3r_output.txt >> $wrktmp/TempWeb
        cat $wrktmp/WebTargets >> $wrktmp/TempWeb
        cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
    fi
done
echo 

# Using halberd
echo "--------------------------------------------------"
echo "Performing scan using Halberd (2 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/WebTargets); do
	timeout 900 halberd $web -p 25 -t 90 -v | tee $wrkpth/Halberd/$prj_name-$web-halberd_output.txt
    if [ -r $wrkpth/Halberd/$prj_name-$web-halberd_output.txt ] || [ -s $wrkpth/Halberd/$prj_name-$web-halberd_output.txt ]; then
        cat $wrkpth/Halberd/$prj_name-$web-halberd_output.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
    fi
done
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
echo

# Some house cleaning
cat $wrktmp/WebTargets >> $wrktmp/TempWeb
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets

# ---------------------------------
# Ping Sweep with Masscan and Nmap
# ---------------------------------

# Masscan - Pingsweep
echo
echo "--------------------------------------------------"
echo "Masscan Pingsweep (3 of 25)"
echo "--------------------------------------------------"
timeout 3600 masscan --ping --rate 10000 -iL $wrktmp/IPtargets -oL $wrkpth/Masscan/$prj_name-masscan_pingsweep
if [ -r $wrkpth/Masscan/$prj_name-masscan_pingsweep ] || [ -s $wrkpth/Masscan/$prj_name-masscan_pingsweep ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_pingsweep | cut -d " " -f 4 | grep -v masscan |grep -v end | sort | uniq >> $wrkpth/Masscan/live
fi

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
echo
echo "--------------------------------------------------"
echo "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP (4 of 25)"
echo "--------------------------------------------------"
nmap -PE -PM -PP -PS"21,22,23,25,53,80,88,110,111,135,139,443,445,8080" -PU"53,111,135,137,161,500" -PY"22,80" -T4 -R --reason --resolve-all -sn -iL $targets -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
# nmap -PE -PM -PP -R --reason --resolve-all -sP -iL $targets -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
# nmap --append-output -PS 21,22,23,25,53,80,88,110,111,135,139,443,445,8080 -PU 53,111,135,137,161,500-R --reason --resolve-all -sP -iL $targets -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ] || [ -s $wrkpth/Nmap/live ]; then
    if [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ] || [ -r $wrkpth/Nmap/live ]; then
        cat $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
        cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponse
        xsltproc $wrkpth/Nmap/$prj_name-nmap_pingsweep.xml -o $wrkpth/Nmap/$prj_name-nmap_pingsweep.html
    fi
fi
echo

# Combining targets
echo "--------------------------------------------------"
echo "Merging all targets files (5 of 25)"
echo "--------------------------------------------------"
if [ -s $wrkpth/Masscan/live ] || [ -s $wrkptWebTargetsh/Nmap/live ] || [ -s $wrktmp/TempTargets ] || [ -s $wrktmp/WebTargets ]; then
    if [ -r $wrkpth/Masscan/live ] || [ -r $wrkpth/Nmap/live ] || [ -r $wrktmp/TempTargets ] || [ -r $wrktmp/WebTargets ]; then
        cat $wrkpth/Masscan/live | sort | uniq > $wrktmp/TempTargets
        cat $wrkpth/Nmap/live | sort | uniq >> $wrktmp/TempTargets
        cat $wrktmp/TempTargets | sort | uniq > $wrktmp/FinalTargets
        cat $wrktmp/WebTargets >> $wrktmp/FinalTargets
    fi
fi
echo

# Using masscan to perform a quick port sweep
echo "--------------------------------------------------"
echo "Performing portknocking scan using Masscan (6 of 25)"
echo "--------------------------------------------------"
masscan -iL $wrktmp/IPtargets -p 0-65535 --rate 10000 --open-only -oL $wrkpth/Masscan/$prj_name-masscan_portknock
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock" ] && [ -s "$wrkpth/Masscan/$prj_name-masscan_portknock" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknock | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
fi
echo 

# Using Nmap
echo "--------------------------------------------------"
echo "Performing portknocking scan using Nmap (7 of 25)"
echo "--------------------------------------------------"
# Nmap - Full TCP SYN & UDP scan on live targets
# nmap http scripts: http-backup-finder,http-cookie-flags,http-cors,http-default-accounts,http-iis-short-name-brute,http-iis-webdav-vuln,http-internal-ip-disclosure,http-ls,http-malware-host 
# nmap http scripts: http-method-tamper,http-mobileversion-checker,http-ntlm-info,http-open-redirect,http-passwd,http-referer-checker,http-rfi-spider,http-robots.txt,http-robtex-reverse-ip,http-security-headers
# nmap http scripts: http-server-header,http-slowloris-check,http-sql-injection,http-stored-xss,http-svn-enum,http-svn-info,http-trace,http-traceroute,http-unsafe-output-escaping,http-userdir-enum
# nmap http scripts: http-vhosts,membase-http-info,http-headers,http-methods
echo
echo "Full TCP SYN & UDP scan on live targets"
nmap -A -Pn -R --reason --resolve-all -sSUV -T4 --top-ports 250 --script=rdp-enum-encryption,ssl-enum-ciphers,vulners -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock
if [ -s $wrkpth/Nmap/$prj_name-nmap_portknock.xml ] && [ -s $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap ] && [ -s $wrkpth/Nmap/$prj_name-nmap_portknock.nmap ]; then
    if [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.xml ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.nmap ]; then
        xsltproc $wrkpth/Nmap/$prj_name-nmap_portknock.xml -o $wrkpth/Nmap/$prj_name-nmap_portknock.html
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 21/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/FTP
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 25/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMTP
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 53/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/DNS
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 23/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/telnet
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 445/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMB
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 3389/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/RDP
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 139/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/NBT
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep http | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/HTTP
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ssh | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/SSH
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/SSL
        python /opt/nmaptocsv/nmaptocsv.py -x $wrkpth/Nmap/$prj_name-nmap_portknock.xml -S -d "," -n -o $wrkpth/Nmap/$prj_name-nmap_portknock.csv
    fi
else
    echo "Something want wrong, the nmap output files either do not exist or were empty
    I recommend chacking the $wrkpth/Nmap/
    Then check your network connection & re-run the script"
    exit
fi
echo

# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | grep -iw http | grep -iw tcp | cut -d "/" -f 1))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | grep -iw ssl | grep -iw tcp | cut -d "/" -f 1))
NEW=$(echo "${HTTPPort[@]}" "${SSLPort[@]}" | sort | uniq)

# Using Eyewitness to take screenshots
echo "--------------------------------------------------"
echo "Performing scan using EyeWitness (8 of 25)"
echo "--------------------------------------------------"
eyewitness -f $wrktmp/FinalTargets --web --threads 25 --prepend-https --cycle all --no-prompt --resolve --only-ports "$(echo ${NEW[*]} | sed 's/ /,/g')" -d $wrkpth/EyeWitness/
# cp -r /usr/share/eyewitness/$(date +%m%d%Y)* $wrkpth/EyeWitness/
echo 

# Using Wappalyzer
echo "--------------------------------------------------"
echo "Performing scan using Wappalyzer (9 of 25)"
echo "--------------------------------------------------"
service docker start
for web in $(cat $wrktmp/FinalTargets); do
    echo Scanning $web
    echo "--------------------------------------------------"
    docker run --rm wappalyzer/cli https://$web | python -m json.tool | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output.json
    docker run --rm wappalyzer/cli http://$web | python -m json.tool | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output.json
    echo "--------------------------------------------------"
done
echo

# Using Tenable
echo "--------------------------------------------------"
echo "Performing scan using Tenable (10 of 25)"
echo "--------------------------------------------------"
echo "Code to be added later"
# curl -sH "X-ApiKeys: accessKey=$API_AK; secretKey=$API_SK" https://cloud.tenable.com/scans
# curl -sH "X-ApiKeys:accessKey=$API_AK;secretKey=$API_SK" -H 'Content-Type: application/json' -d '{"uuid": "$Template-UUID", , "settings": { "name": "new_scan", "file_targets": "'"$wrkpth/targets"'",  "folder_id":"264" } }'  https://cloud.tenable.com/scans | python -m json.tool
echo

# Using testssl & sslcan
echo "--------------------------------------------------"
echo "Performing scan using testssl (11 of 25)"
echo "--------------------------------------------------"
testssl --assume-http --csv --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | tee -a $wrkpth/TestSSL/$prj_name-TestSSL_output.txt
mv $pth/*.html $wrkpth/TestSSL/
mv $pth/*.csv $wrkpth/TestSSL/
mv $pth/*.json $wrkpth/TestSSL/
mv $pth/*.log $wrkpth/TestSSL/
mv $PWD/*.csv $wrkpth/SSLScan/
echo

# Using XSStrike
echo "--------------------------------------------------"
echo "Performing scan using XSStrike (12 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u https://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u http://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
        fi
    done
done
echo

# Using DNS Recon
# Will revise this later to account for other ports one might use for dns
echo "--------------------------------------------------"
echo "Performing scan using DNS Scan (13 of 25)"
echo "--------------------------------------------------"
if [ -s $wrkpth/Nmap/DNS ]; then
    for IP in $(cat $wrkpth/Nmap/DNS); do
        echo Scanning $IP
        echo "--------------------------------------------------"
        nmap -A -Pn -R --reason --resolve-all -sSUV -T4 -p domain --script=*dns* -oA $wrkpth/Nmap/$prj_name-nmap_dns $IP
        echo "--------------------------------------------------"
        dnsrecon -d $IP -a | tee -a $wrkpth/DNS_Recon/$prj_name-$IP-$web-DNSRecon_output.txt
        echo "--------------------------------------------------"
    done
fi
echo

# # Using SSH Audit
echo "--------------------------------------------------"
echo "Performing scan using SSH Audit (14 of 25)"
echo "--------------------------------------------------"
if [ -s $wrkpth/Nmap/SSH ]; then
    nmap -A -Pn -R --reason --resolve-all -sSUV -T4 -p ssh --script=ssh* -iL $wrkpth/Nmap/SSH -oA $wrkpth/Nmap/$prj_name-nmap_ssh
    for IP in $(cat $wrkpth/Nmap/SSH); do
        echo Scanning $IP
        echo "--------------------------------------------------"
        ssh-audit $IP | aha -t "SSH Audit" > $wrkpth/SSH/$prj_name-$IP-ssh-audit_output.html
        echo "--------------------------------------------------"
        ssh_scan -t $IP -o $wrkpth/SSH/$prj_name-$IP-ssh-scan_output.json
        echo "--------------------------------------------------"
        service postgresql start
        msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS file:targets; set USER_FILE /usr/share/seclists/Usernames/cirt-default-usernames.txt; set THREADS 25; exploit; exit -y" 2> /dev/null | tee -a $wrkpth/SSH/$prj_name-ssh-msf-$web.txt
    done
fi
echo

# Need to troubleshoot this
# Using nikto
echo "--------------------------------------------------"
echo "Performing scan using Nikto (15 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    nikto -C all -h $web -port $(echo ${NEW[*]} | sed 's/ /,/g') -output $wrkpth/Nikto/$prj_name-$web-nikto_output.csv | tee $wrkpth/Nikto/$prj_name-$web-nikto_output.txt
done
echo

# Using dirbuster
# Switching back to dirb, it is the most stable
# Need to do more troubleshooting gobuster
echo "--------------------------------------------------"
echo "Performing scan using Gobuster (16 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            dirb $web /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o $wrkpth/Gobuster/$prj_name-$web-$PORTNUM-dirb_output.txt -w
            # echo "--------------------------------------------------"
            # gobuster dir -o $wrkpth/Gobuster/$prj_name-$web-$PORTNUM-gobuster_https_output.txt -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt" -e -f -k -r --wildcard -u https://$web:$PORTNUM
            # echo "--------------------------------------------------"
            # gobuster dir -o $wrkpth/Gobuster/$prj_name-$web-$PORTNUM-gobuster_http_output.txt -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt" -e -f -k -r --wildcard -u http://$web:$PORTNUM
            # echo "--------------------------------------------------"
        fi
    done
done
echo

# Using arachni
echo "--------------------------------------------------"
echo "Performing scan using arachni (17 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            arachni_multi https://$web:$PORTNUM http://$web:$PORTNUM --report-save-path=$wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr 2> /dev/null
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=html:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-$web-$PORTNUM-HTML_Report.zip 2> /dev/null
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=json:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-$web-$PORTNUM-JSON_Report.json 2> /dev/null
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=txt:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-$web-$PORTNUM-TXT_Report.txt 2> /dev/null
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=xml:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-$web-$PORTNUM-XML_Report.xml 2> /dev/null
            echo "--------------------------------------------------"
        fi
    done
done
echo

# Using theharvester & metagoofil
echo "--------------------------------------------------"
echo "Performing scan using Theharvester and Metagoofil (18 of 25)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theharvester -d https://$web:$PORTNUM -l 500 -b all -h | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_https_output.txt
            timeout 900 metagoofil -d https://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_https_output.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
            echo "--------------------------------------------------"
            timeout 900 theharvester -d http://$web:$PORTNUM -l 500 -b all -h | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_http_output.txt
            timeout 900 metagoofil -d http://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_http_output.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
            # if [ -r wrkpth/Harvester/$prj_name-harvester_output-$web.txt ] || [ -r $wrkpth/Metagoofil/$prj_name-metagoofil_output-$web.html ]; then
            #     cat $wrkpth/Harvester/$prj_name-harvester_output-$web.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
            #     # cat $wrkpth/Metagoofil/$prj_name-metagoofil_output-$web.html |grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" | cut -d ":" -f 1 >> $wrktmp/TempWeb
            # fi
            # echo "--------------------------------------------------"
        fi
    done
done
if [ -d $wrkpth/Harvester/Evidence/ ]; then
    for files in $(ls $wrkpth/Harvester/Evidence/ | grep pdf); do
        pdfinfo $files.pdf | grep Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
    done
    cat $wrkpth/Harvester/tempusr | sort | uniq > $wrkpth/Harvester/Usernames
    rm $wrkpth/Harvester/tempusr
fi
echo

# FTP Testing
# echo "--------------------------------------------------"
# echo "Performing further FTP testing (19 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# Using GOLismero
# echo "--------------------------------------------------"
# echo "Performing scan using GOLismero (20 of 25)"
# echo "--------------------------------------------------"
# golismero scan -i $wrkpth/Nmap/$prj_name-nmap_portknock.xml audit-name "$prj_name" -o "$wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.html $wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.txt" -db $wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.db
# echo

# # Using RetireJS
# echo "--------------------------------------------------"
# echo "Performing scan using RetireJS (21 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# SMTP Testing
# echo "--------------------------------------------------"
# echo "Performing further SMTP testing (22 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# SMB Testing
# echo "--------------------------------------------------"
# echo "Performing further SMB testing (23 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# RDP Testing
# echo "--------------------------------------------------"
# echo "Performing further RDP testing (24 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# SQL Testing
# echo "--------------------------------------------------"
# echo "Performing further RDP testing (24 of 25)"
# echo "--------------------------------------------------"
# for IP in $(cat $wrktmp/FinalTargets); do
#     for PORTNUM in ${NEW[*]}; do
#         STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ] && [ "$PORTNUM" != 80 ]; then
#             echo Scanning $web:$PORTNUM
#             echo "--------------------------------------------------"
#             docker run --rm -v $(pwd):/usr/src/app fhunii/retire.js
#             cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
#             cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
#             echo "--------------------------------------------------"
#         fi
#     done
# done
# mv $PWD/*.csv $wrkpth/SSLScan/
# echo

# Add zipping of all content and sending it via some medium (e.g., email, ftp, etc)
echo "--------------------------------------------------"
echo "Gift wrapping everything and putting a bowtie on it!"
echo "--------------------------------------------------"
zip -ru9 $pth/$prj_name-$TodaysYEAR.zip $pth/$TodaysYEAR

# Goodbye Message
echo "
___________________________¶¶¶
_______________________¶¶¶¶¶¶¶¶¶¶¶¶
______________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
____________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
__________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
___________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
__________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶___¶¶¶
____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
___________¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
__________¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_________¶¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_________¶¶¶____¶¶¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶¶¶¶¶¶__¶¶______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_¶¶¶¶¶__¶¶_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_¶¶¶¶¶__¶¶______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
__¶¶¶¶¶¶¶_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
___¶¶¶¶¶_________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_________________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
________________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
______________________¶¶¶¶¶¶¶¶¶¶¶¶¶
_____________________¶¶¶¶¶¶¶¶¶¶¶
____________________¶¶¶¶¶¶¶¶¶¶
____________________¶¶¶¶¶¶¶¶
___________________¶¶¶¶¶
If you eliminate all other possibilities, the one that remains, however unlikely, is the right answer."

# Empty file cleanup
find $wrkpth -size 0c -type d,f -exec rm -rf {} \;

# Stopping services we turned on
service postgresql stop
service docker stop

# Removing unnessary files
rm $wrktmp/IPtargets -f
rm $wrktmp/TempTargets -f
rm $wrktmp/TempWeb -f
rm $wrktmp/WebTargets -f

# Uninitializing variables
# do later
set -u
