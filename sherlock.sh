#!/usr/bin/env bash
# Author: Gilles Biagomba
# Program:Web Inspector
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specficailly recon).\n

# for debugging purposes
# set -eux
trap "echo Booh!" SIGINT SIGTERM

# Declaring variables
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"
wrktmp=$(mktemp -d)
targets=$1

# Setting Envrionment
mkdir -p  $wrkpth/Halberd/ $wrkpth/Sublist3r/ $wrkpth/Harvester/ $wrkpth/Metagoofil/
mkdir -p $wrkpth/Nikto/ $wrkpth/Dirb/ $wrkpth/Nmap/ $wrkpth/Sniper/
mkdir -p $wrkpth/Masscan/ $wrkpth/Arachni/ $wrkpth/TestSSL/ $wrkpth/SSLScan/
mkdir -p $wrkpth/JexBoss/ $wrkpth/XSStrike/ $wrkpth/Grabber/ $wrkpth/GOLismero/
mkdir -p $wrkpth/Wappalyzer/ $wrkpth/Gobuster/

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

# Parsing the target file
cat $pth/$targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" > $wrktmp/WebTargets
cat $pth/$targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $wrktmp/TempTargets
cat $pth/$targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> $wrktmp/TempTargets
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
echo

# Using sublist3r 
echo "--------------------------------------------------"
echo "Performing scan using Sublist3r"
echo "--------------------------------------------------"
# consider replacing with  gobuster -m dns -o gobuster_output.txt -u example.com -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt"
for web in $(cat $wrktmp/WebTargets);do
	sublist3r -d $web -v -t 10 -o "$wrkpth/Sublist3r/$prj_name-sublist3r_output-$web.txt"
    if [ -r wrkpth/Sublist3r/$prj_name-sublist3r_output-$web.txt ]; then
        cat $wrkpth/Sublist3r/$prj_name-sublist3r_output-$web.txt > $wrktmp/TempWeb
        cat $wrktmp/WebTargets >> $wrktmp/TempWeb
        cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
    fi
done
echo 

# Using halberd
echo "--------------------------------------------------"
echo "Performing scan using Halberd"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/WebTargets);do
	timeout 90 halberd $web -p 5 -t 90 -v | tee $wrkpth/Halberd/$prj_name-halberd_output-$web.txt
    if [ -r $wrkpth/Halberd/$prj_name-halberd_output-$web.txt ]; then
        cat $wrkpth/Halberd/$prj_name-halberd_output-$web.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
    fi
done
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
echo

# Using theharvester & metagoofil
echo "--------------------------------------------------"
echo "Performing scan using Theharvester and Metagoofil"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/WebTargets);do
    theharvester -d https://$web -l 500 -b all -h | tee $wrkpth/Harvester/$prj_name-harvester_output-$web.txt
    timeout 90 metagoofil -d https://$web -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-metagoofil_output-$web.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
    if [ -r wrkpth/Harvester/$prj_name-harvester_output-$web.txt ] || [ -r $wrkpth/Metagoofil/$prj_name-metagoofil_output-$web.html ]; then
        cat $wrkpth/Harvester/$prj_name-harvester_output-$web.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
        # cat $wrkpth/Metagoofil/$prj_name-metagoofil_output-$web.html |grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" | cut -d ":" -f 1 >> $wrktmp/TempWeb
    fi
done
echo

# Some house cleaning
cat $wrktmp/WebTargets >> $wrktmp/TempWeb
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets

# Parsing PDF documents
echo "--------------------------------------------------"
echo "Parsing all the PDF documents found"
echo "--------------------------------------------------"
if [ -d $wrkpth/Harvester/Evidence/ ]; then
    for files in $(ls $wrkpth/Harvester/Evidence/ | grep pdf);do
        pdfinfo $files.pdf | grep Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
    done
    cat $wrkpth/Harvester/tempusr | sort | uniq > $wrkpth/Harvester/Usernames
    rm $wrkpth/Harvester/tempusr
    echo
fi
echo

# ---------------------------------
# Ping Sweep with Masscan and Nmap
# ---------------------------------

# Masscan - Pingsweep
echo
echo "--------------------------------------------------"
echo "Masscan Pingsweep"
echo "--------------------------------------------------"
masscan --ping -iL $wrktmp/IPtargets -oL $wrkpth/Masscan/$prj_name-masscan_pingsweep
if [ -r $wrkpth/Masscan/$prj_name-masscan_pingsweep ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_pingsweep | cut -d " " -f 4 | grep -v masscan |grep -v end | sort | uniq >> $wrkpth/Masscan/live
fi

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
echo
echo "--------------------------------------------------"
echo "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP"
echo "--------------------------------------------------"
# nmap -PE -PM -PP -PS "21,22,23,25,53,80,88,110,111,135,139,443,445,8080" -PU "53,111,135,137,161,500" -R --reason --resolve-all -sP -iL $targets
nmap -PE -PM -PP -R --reason --resolve-all -sP -iL $targets -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
nmap --append-output -PS 21,22,23,25,53,80,88,110,111,135,139,443,445,8080 -PU 53,111,135,137,161,500-R --reason --resolve-all -sP -iL $targets -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
if [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ] || [ -r $wrkpth/Nmap/live ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
    cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/$prj_name-pingresponse
    xsltproc $wrkpth/Nmap/$prj_name-nmap_pingsweep.xml -o $wrkpth/Nmap/$prj_name-nmap_pingsweep.html
fi
echo

# Combining targets
echo "--------------------------------------------------"
echo "Merging all targets files"
echo "--------------------------------------------------"
if [ -r $wrkpth/Masscan/live ] || [ -r $wrkpth/Nmap/live ] || [ -r $wrktmp/TempTargets ] || [ -r $wrktmp/WebTargets ]; then
    cat $wrkpth/Masscan/live | sort | uniq > $wrktmp/TempTargets
    cat $wrkpth/Nmap/live | sort | uniq >> $wrktmp/TempTargets
    cat $wrktmp/TempTargets | sort | uniq > $wrktmp/TempTargets
    cat $wrktmp/WebTargets >> $wrktmp/TempTargets
fi
echo

# Using masscan to perform a quick port sweep
echo "--------------------------------------------------"
echo "Performing portknocking scan using Masscan"
echo "--------------------------------------------------"
masscan -iL $wrktmp/IPtargets -p 0-65535 --open-only -oL $wrkpth/Masscan/$prj_name-masscan_portknock
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock" ]; then # need to find out what is wrong with this line of code
    cat $wrkpth/Masscan/$prj_name-masscan_portknock | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
    # OpenPORT=($(cat $wrkpth/Masscan/$prj_name-masscan_portknock | cut -d " " -f 3 | grep -v masscan | sort | uniq))
fi
echo 

# Using Nmap
echo "--------------------------------------------------"
echo "Performing portknocking scan using Nmap"
echo "--------------------------------------------------"
# Nmap - Full TCP SYN & UDP scan on live targets
# nmap http scripts: http-backup-finder,http-cookie-flags,http-cors,http-default-accounts,http-iis-short-name-brute,http-iis-webdav-vuln,http-internal-ip-disclosure,http-ls,http-malware-host 
# nmap http scripts: http-method-tamper,http-mobileversion-checker,http-ntlm-info,http-open-redirect,http-passwd,http-referer-checker,http-rfi-spider,http-robots.txt,http-robtex-reverse-ip,http-security-headers
# nmap http scripts: http-server-header,http-slowloris-check,http-sql-injection,http-stored-xss,http-svn-enum,http-svn-info,http-trace,http-traceroute,http-unsafe-output-escaping,http-userdir-enum
# nmap http scripts: http-vhosts,membase-http-info,http-headers,http-methods
echo
echo "Full TCP SYN & UDP scan on live targets"
nmap -A -Pn -R --reason --resolve-all -sSUV -T4 --top-ports 200 --script=ssl-enum-ciphers,vulners -iL $wrktmp/TempTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock
if [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.xml ] && [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap ] && [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.nmap ]; then
    echo
    echo success
    xsltproc $wrkpth/Nmap/$prj_name-nmap_portknock.xml -o $wrkpth/Nmap/$prj_name-nmap_portknock.html
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 25/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMTP
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 53/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/DNS
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 23/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/telnet
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 445/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMB
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ' 139/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/NBT
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep http | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/HTTP
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/SSH
    cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/SSL
    # OpenPORT=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | grep open | cut -d "/" -f 1 | sort | uniq | grep -v cpe))
fi
echo

# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | grep -iw http | grep -iw tcp | cut -d "/" -f 1))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | grep -iw ssl | grep -iw tcp | cut -d "/" -f 1))
NEW=("${HTTPPort[@]}" "${SSLPort[@]}")

# Using Wappalyzer
echo "--------------------------------------------------"
echo "Performing scan using Wappalyzer"
echo "--------------------------------------------------"
service docker start
for web in $(cat $wrktmp/TempTargets);do
    docker run --rm wappalyzer/cli https://$web | python -m json.tool | tee -a $wrkpth/Wappalyzer/$prj_name-wappalyzer_output-$web.json
done
echo

# Using nikto
echo "--------------------------------------------------"
echo "Performing scan using Nikto"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            nikto -C all -h $web -port $PORTNUM -o $wrkpth/Nikto/$prj_name-nikto_https_output-$web.csv -ssl | tee $wrkpth/Nikto/$prj_name-nikto_https_output-$web.txt
        fi
    done
done
echo

# Using dirb
# consider switching to gobuster, works faster
echo "--------------------------------------------------"
echo "Performing scan using Dirb"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            # dirb https://$web:$PORTNUM /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o $wrkpth/Dirb/$prj_name-dirb_https_output-$web.txt -w
            # dirb http://$web:$PORTNUM /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o $wrkpth/Dirb/$prj_name-dirb_http_output-$web.txt -w
            gobuster -o $wrkpth/Gobuster/$prj_name-gobuster_output-$web:$PORTNUM.txt -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt" -u https://$web:$PORTNUM
            gobuster -o $wrkpth/Gobuster/$prj_name-gobuster_output-$web:$PORTNUM.txt -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-1.0.txt" -u http://$web:$PORTNUM
done
echo

# Using arachni
echo "--------------------------------------------------"
echo "Performing scan using arachni"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            arachni_multi https://$web:$PORTNUM http://$web:$PORTNUM --report-save-path=$wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=html:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-HTML_Report-$web-$PORTNUM.zip
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=json:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-JSON_Report-$web-$PORTNUM.zip
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=txt:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-TXT_Report-$web-$PORTNUM.zip
            arachni_reporter $wrkpth/Arachni/$prj_name-$web-$PORTNUM.afr --reporter=xml:outfile=$wrkpth/Arachni/$prj_name-Arachni/$prj_name-XML_Report-$web-$PORTNUM.zip
        fi
    done
done
echo

# Using XSStrike
echo "--------------------------------------------------"
echo "Performing scan using XSStrike"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            python3 /opt/XSStrike/xsstrike.py -u https://$web:$PORTNUM --crawl | tee $wrkpth/XSStrike/$prj_name-$web-$PORTNUM.txt
        fi
    done
done
echo

# Using GOLismero
echo "--------------------------------------------------"
echo "Performing scan using GOLismero"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            golismero scan "https://$web:$PORTNUM" audit-name "$prj_name" report "$wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.html $wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.txt $wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.rst" -db $wrkpth/GOLismero/$prj_name-$web-$PORTNUM-golismero_output.db
        fi
    done
done
echo

# Using testssl & sslcan
echo "--------------------------------------------------"
echo "Performing scan using sslscan & testssl"
echo "--------------------------------------------------"
for IP in $(cat $wrktmp/TempTargets);do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            sslscan --xml=$wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.xml $IP:$PORTNUM | tee -a $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt
            testssl --append --csv --parallel --sneaky $IP:$PORTNUM | tee -a $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt
            cat $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.txt | aha -t "TestSSL Output for $IP:$PORTNUM" > $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$web.html
            cat $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.txt | aha -t "SSLScan Output for $IP:$PORTNUM" > $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$web.html
        fi
    done
done
echo

# Add zipping of all content and sending it via some medium (e.g., email, ftp, etc)
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
find $pth -size 0c -type f -exec rm -rf {} \;

# Removing unnessary files
rm $wrktmp/IPtargets -f
rm $wrktmp/TempTargets -f
rm tempusr -f
rm $wrktmp/TempWeb -f
rm $wrktmp/WebTargets -f

# Uninitializing variables
# do later
set -u