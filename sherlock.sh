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

# Checking if running the latest version
# curl --connect-timeout 5 -s https://api.github.com/repos/gbiagomba/Sherlock/tags | grep -eo '^(\d+\.)?(\d+\.)?(\*|\d+)$'| head -1 | cut -c11-13
# https://www.regextester.com/95064

# Declaring variables
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"
wrktmp=$(mktemp -d)
targets=$1
API_AK="" #Tenable Access Key
API_SK="" #Tenable Secret Key
diskMax=95
diskSize=$(df | grep /dev/sda1 | cut -d " " -f 13 | cut -d "%" -f 1)
OS_CHK=$(cat /etc/os-release | grep -o debian)

# Ensuring system is debian based
if [ "$OS_CHK" != "debian" ]; then
    echo "Unfortunately this install script was written for debian based distributions only, sorry!"
    exit
fi

# Checking system resources (HDD space)
if [[ "$diskSize" -ge "$diskMax" ]]; then
	clear
	echo 
	echo "You are using $diskSize% and I am concerned you might run out of space"
	echo "Remove some files and try again, you will thank me later, trust me :)"
	exit
fi

# Setting Envrionment
mkdir -p  $wrkpth/Halberd/ $wrkpth/SubDomainEnum/ $wrkpth/Harvester/ $wrkpth/Metagoofil/
mkdir -p $wrkpth/Nikto/ $wrkpth/PathEnum/ $wrkpth/Nmap/ $wrkpth/Wappalyzer/ 
mkdir -p $wrkpth/Masscan/ $wrkpth/WebVulnScan/ $wrkpth/SSL/ $wrkpth/XSStrike/
mkdir -p $wrkpth/GOLismero/ $wrkpth/DNS_Recon/ $wrkpth/SSH/ $wrkpth/RetieJS/
mkdir -p $wrkpth/EyeWitness/  $wrkpth/Batea/

# Loadfing in support scripts
source gift_wrapper.sh

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
echo "Web app scanning? Elementary my dear $USER!"
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

if [ -z $prj_name ]; then
    prj_name=`echo $RANDOM`
fi

# Recording screen output
# exec >|$PWD/$prj_name-term_output.log 2>&1

# Parsing the target file
cat $pth/$targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info)" > $wrktmp/WebTargets
cat $pth/$targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $wrktmp/TempTargets
cat $pth/$targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> $wrktmp/TempTargets
cat $pth/$targets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" >> $wrktmp/TempTargetsv6
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq > $wrktmp/IPtargetsv6
echo

# Using sublist3r 
echo "--------------------------------------------------"
echo "Performing Subdomain enum (1 of 20)"
echo "--------------------------------------------------"
# consider replacing with  gobuster -m dns -o gobuster_output.txt -u example.com -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
# gobuster -m dns -cn -e -i -r -t 25 -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt -o "$wrkpth/PathEnum/$prj_name-gobuster_dns_output-$web.txt" -u example.com
for web in $(cat $wrktmp/WebTargets); do
	sublist3r -d $web -v -t 25 -o "$wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt"
    amass enum -brute -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt -d $web -ip -o "$wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt"
    gobuster dns -i -t 25 -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt -o "$wrkpth/PathEnum/$prj_name-$web-gobuster_dns_output.txt" -d $web
    shuffledns -d cars.com -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt -o "$wrkpth/PathEnum/$prj_name-$web-shuffledns_output.txt" -r /opt/Sherlock/rsc/ressolvers.txt -massdns `which massdns`
done
echo

# Checking subdomains against subdomainizer
cat $wrktmp/WebTargets | httprobe | tee -a $wrkpth/SubDomainEnum/SubDomainizer_feed.txt
for i in `cat $wrkpth/SubDomainEnum/SubDomainizer_feed.txt`; do python3 /opt/SubDomainizer/SubDomainizer.py -u $i -k -o $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt 2> /dev/null; done
echo

# Pulling out all the web targets
cat $wrkpth/PathEnum/$prj_name-$web-shuffledns_output.txt $wrkpth/PathEnum/$prj_name-$web-gobuster_dns_output.tx $wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt $wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | sort | uniq >> $wrktmp/TempWeb
cat $wrkpth/PathEnum/$prj_name-$web-shuffledns_output.txt $wrkpth/PathEnum/$prj_name-$web-gobuster_dns_output.tx $wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt $wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
cat $wrkpth/PathEnum/$prj_name-$web-shuffledns_output.txt $wrkpth/PathEnum/$prj_name-$web-gobuster_dns_output.tx $wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt $wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info)" >> $wrktmp/WebTargets
cat $wrkpth/PathEnum/$prj_name-$web-shuffledns_output.txt $wrkpth/PathEnum/$prj_name-$web-gobuster_dns_output.tx $wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt $wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" >> $wrktmp/TempTargetsv6
cat $wrktmp/WebTargets >> $wrktmp/TempWeb
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets

# Using amass
# amass enum -brute -w /usr/local/share/sec_lists/Discovery/Web_Content/raft-large-directories.txt -d www.cars.com

# Using halberd
echo "--------------------------------------------------"
echo "Performing scan using Halberd (2 of 20)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/WebTargets); do
	timeout 300 halberd $web -p 25 -t 90 -v | tee $wrkpth/Halberd/$prj_name-$web-halberd_output.txt
    if [ -r $wrkpth/Halberd/$prj_name-$web-halberd_output.txt ] && [ -s $wrkpth/Halberd/$prj_name-$web-halberd_output.txt ]; then
        cat $wrkpth/Halberd/$prj_name-$web-halberd_output.txt | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
    fi
done
echo

echo
echo "--------------------------------------------------"
echo "Some house cleaning (3 of 20)"
echo "--------------------------------------------------"
# Some house cleaning
cat $wrktmp/WebTargets >> $wrktmp/TempWeb
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
cat $wrktmp/IPtargetsv6 >> $wrktmp/TempTargetsv6
cat $wrktmp/TempWeb | sort | uniq | tee -a $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort | uniq | tee $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq | tee $wrktmp/IPtargetsv6
cat  $wrktmp/TempTargets $wrktmp/IPtargets $wrktmp/IPtargetsv6 $wrktmp/WebTargets | sort | uniq | tee $wrktmp/tempFinal

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
echo
echo "--------------------------------------------------"
echo "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP (4 of 20)"
echo "--------------------------------------------------"
nmap -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PE -PM -PP -PO -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -T5 -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
if [ -z `$wrktmp/tempFinal | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    nmap -6 -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -T5 -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweepv6
elif [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
    cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponse
elif [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/livev6
    cat $wrkpth/Nmap/livev6 | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponsev6
fi
echo

# Combining targets
echo "--------------------------------------------------"
echo "Merging all targets files (5 of 20)"
echo "--------------------------------------------------"
if [ -s $wrkpth/Masscan/live ] || [ -s $wrkptWebTargetsh/Nmap/live ] || [ -s $wrktmp/TempTargets ] || [ -s $wrktmp/WebTargets ]; then
    if [ -r $wrkpth/Masscan/live ] || [ -r $wrkpth/Nmap/live ] || [ -r $wrktmp/TempTargets ] || [ -r $wrktmp/WebTargets ]; then
        # cat $wrkpth/Masscan/live | sort | uniq > $wrktmp/TempTargets
        cat $wrkpth/Nmap/live | sort | uniq >> $wrktmp/TempTargets
        cat $wrktmp/tempFinal  >> $wrktmp/TempTargets
        cat $wrktmp/WebTargets $wrktmp/tempFinal $wrktmp/TempTargets | sort | uniq >> $wrktmp/FinalTargets
        cat $wrktmp/TempTargets | sort | uniq | tee $wrktmp/IPtargets
    fi
fi
echo
echo "Printing final list of targets to be used"
cat $wrktmp/FinalTargets $wrktmp/IPtargets | sort | uniq
echo

# Using masscan to perform a quick port sweep
# Consider switcing to unicornscan
# unicornscan -i eth1 -Ir 160 -E 192.168.1.0/24:1-4000 gateway:a
echo "--------------------------------------------------"
echo "Performing portknocking scan using Masscan (6 of 20)"
echo "--------------------------------------------------"
masscan -iL $wrktmp/IPtargets -p 0-65535 --rate 1000 --open-only -oL $wrkpth/Masscan/$prj_name-masscan_portknock
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock" ] && [ -s "$wrkpth/Masscan/$prj_name-masscan_portknock" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknock | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
fi
echo 

# Using Nmap
echo "--------------------------------------------------"
echo "Performing portknocking scan using Nmap (7 of 20)"
echo "--------------------------------------------------"
# Nmap - Full TCP SYN & UDP scan on live targets
echo
echo "Full TCP SYN & UDP scan on live targets"
nmap -A -Pn -R --reason --resolve-all -sSUV -T4 --open --top-ports 250 --script=rdp-enum-encryption,ssl-enum-ciphers,vulners,vulscan --script-args "userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly" -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    nmap -6 -A -Pn -R --reason --resolve-all -sSUV -T4 --open --top-ports 250 --script=rdp-enum-encryption,ssl-enum-ciphers,vulners,vulscan --script-args "userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly" -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknockv6
elif [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.xml ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap ]; then
    for i in smtp domain telnet microsoft-ds netbios-ssn http ssh ssl ms-wbt-server imap; do
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $i | grep open | cut -d ' ' -f 2 | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`
        cat $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $i | grep open | cut -d ' ' -f 2 | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`
    done
else
    echo "Something want wrong, ethier the nmap output files do not exist or it is were empty
    I recommend chacking the $wrkpth/Nmap/
    Then check your network connection & re-run this script"
    gift_wrap
    exit
fi
echo

# Using testssl & sslcan
# switch back to for loop, testssl doesnt properly parse gnmap
echo "--------------------------------------------------"
echo "Performing scan using testssl (8 of 20)"
echo "--------------------------------------------------"
# SSLCHECK=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap) # Revisit this line, there may be a logic err here
# if [ $SSLCHECK == "tcp//ssl" ] || [ $SSLCHECK == "tcp//http" ]; then
testssl --assume-http --csv --full --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_output.txt
mv $pth/*.html $wrkpth/SSL/
mv $pth/*.csv $wrkpth/SSL/
mv $pth/*.json $wrkpth/SSL/
mv $pth/*.log $wrkpth/SSL/
# fi
echo

# Using DNS Recon
# Will revise this later to account for other ports one might use for dns
echo "--------------------------------------------------"
echo "Performing scan using DNS Scan (9 of 20)"
echo "--------------------------------------------------"
if [ -s $wrkpth/Nmap/DOMAIN ]; then
    nmap -A -Pn -R --reason --resolve-all -sSUV -T4 -p domain --open --script=*dns* -oA $wrkpth/Nmap/$prj_name-nmap_dns -iL $wrkpth/Nmap/DOMAIN
    nmap -6 -A -Pn -R --reason --resolve-all -sSUV -T4 -p domain --open --script=*dns* -oA $wrkpth/Nmap/$prj_name-nmap_dnsv6 -iL $wrkpth/Nmap/DOMAIN
    for IP in $(cat $wrkpth/Nmap/DOMAIN); do
        echo Scanning $IP
        echo "--------------------------------------------------"
        dnsrecon -d $IP -a | tee -a $wrkpth/DNS_Recon/$prj_name-$IP-$web-DNSRecon_output.txt
        dnsrecon -d $IP  -t zonewalk | tee -a $wrkpth/DNS_Recon/$prj_name-$IP-$web-DNSRecon_output.txt
        echo "--------------------------------------------------"
    done
fi
echo

# Using SSH Audit
echo "--------------------------------------------------"
echo "Performing scan using SSH Audit (10 of 20)"
echo "--------------------------------------------------"
SSHPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | egrep -v "^#|Status: Up" $NMAP_FILE | cut -d' ' -f4- | sed -n -e 's/Ignored.*//p' | tr ',' '\n' | sed -e 's/^[ \t]*//' | sort -n | uniq -c | sort -k 1 -r | head -n 10 | cut -d " " -f 7 | grep -iw ssh | cut -d "/" -f 1 | sort | uniq)
if [ -s $wrkpth/Nmap/SSH ]; then
    nmap -A -Pn -R --reason --resolve-all -sSUV -T4 -p "$(echo ${SSHPort[*]} | sed 's/ /,/g')" --open --script=ssh* --script-args "userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly" -iL $wrkpth/Nmap/SSH -oA $wrkpth/Nmap/$prj_name-nmap_ssh
    nmap -6 -A -Pn -R --reason --resolve-all -sSUV -T4 -p "$(echo ${SSHPort[*]} | sed 's/ /,/g')" --open --script=ssh* --script-args "userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly" -iL $wrkpth/Nmap/SSH -oA $wrkpth/Nmap/$prj_name-nmap_sshv6
    for IP in $(cat $wrkpth/Nmap/SSH); do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/open/tcp//ssh" -m 1 -o | grep "ssh" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $IP | grep "$PORTNUM/filtered/tcp//ssh" -m 1 -o | grep "ssh" -o) # Check to see if the port is filtered & is a web service
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "ssh" ] || [ "$STAT3" == "ssh" ]; then
            for PORTNUM in ${SSHPort[*]}; do
                echo Scanning $IP
                echo "--------------------------------------------------"
                ssh-audit -n $IP -p  $PORTNUM | aha -t "SSH Audit" > $wrkpth/SSH/$prj_name-$IP:$PORTNUM-ssh-audit_output.html
                echo "--------------------------------------------------"
                docker run --rm mozilla/ssh_scan -t $IP -p $PORTNUM -o $wrkpth/SSH/$prj_name-$IP:$PORTNUM-ssh-scan_output.json
                echo "--------------------------------------------------"
                msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS file:$wrkpth/Nmap/SSH; set RPORT $PORTNUM; set USER_FILE /usr/share/seclists/Usernames/cirt-default-usernames.txt; set THREADS 25; exploit; exit -y" 2> /dev/null | tee -a $wrkpth/SSH/$prj_name-ssh-msf-$web.txt
            done
        fi
    done
    service postgresql start
fi
echo

# Using batea
echo "--------------------------------------------------"
echo "Ranking nmap output using batea (11 of 20)"
echo "--------------------------------------------------"
batea -v $wrkpth/Nmap/*.xml | tee -a  $wrkpth/Batea/$prj_name-batea_output.json 2> /dev/null
echo

# Combining ports
# echo "--------------------------------------------------"
# echo "Combining ports
# echo "--------------------------------------------------"
# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | egrep -v "^#|Status: Up"  | cut -d' ' -f4- | sed -n -e 's/Ignored.*//p' | tr ',' '\n' | sed -e 's/^[ \t]*//' | sort -n | uniq -c | sort -k 1 -r | head -n 10 | cut -d " " -f 7 | grep -iw http | cut -d "/" -f 1 | sort | uniq))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.nmap | egrep -v "^#|Status: Up" | cut -d' ' -f4- | sed -n -e 's/Ignored.*//p' | tr ',' '\n' | sed -e 's/^[ \t]*//' | sort -n | uniq -c | sort -k 1 -r | head -n 10 | cut -d " " -f 7 | grep -iw ssl | cut -d "/" -f 1 | sort | uniq))
if [ ${#HTTPPort[@]} -eq 0 ] || [ ${#SSLPort[@]} -eq 0 ]; then
    echo "There are no open web or ssl ports, exiting now"
    gift_wrap
    exit
fi
NEW=$(echo "${HTTPPort[@]}" "${SSLPort[@]}" | awk '/^[0-9]/' | sort | uniq) # Will need testing
# Consider using the below script to parse for ports (https://github.com/superkojiman/scanreport)
# ./scanreport.sh -f ~/Documents/Projects/XPC/2020Q1/2020/01-22/Nmap/XPC-2020Q1-nmap_portknock.gnmap -s http | grep -v Host | cut -d$'\t' -f 1 | sort | uniq

# Using Eyewitness to take screenshots
echo "--------------------------------------------------"
echo "Performing scan using EyeWitness (12 of 20)"
echo "--------------------------------------------------"
eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock.xml --resolve --web --prepend-https --threads 25 --no-prompt --resolve -d $wrkpth/EyeWitness/
# cp -r /usr/share/eyewitness/$(date +%m%d%Y)* $wrkpth/EyeWitness/
echo 

# Using Wappalyzer
echo "--------------------------------------------------"
echo "Performing scan using Wappalyzer (13 of 20)"
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
echo "Performing scan using Tenable (14 of 20)"
echo "--------------------------------------------------"
echo "Code to be added later"
# curl -sH "X-ApiKeys: accessKey=$API_AK; secretKey=$API_SK" https://cloud.tenable.com/scans
# curl -sH "X-ApiKeys:accessKey=$API_AK;secretKey=$API_SK" -H 'Content-Type: application/json' -d '{"uuid": "$Template-UUID", , "settings": { "name": "new_scan", "file_targets": "'"$wrkpth/targets"'",  "folder_id":"264" } }'  https://cloud.tenable.com/scans | python -m json.tool
echo

# Using XSStrike
echo "--------------------------------------------------"
echo "Performing scan using XSStrike (15 of 20)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u https://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
        elif [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u http://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
        fi
    done
done
echo

echo "--------------------------------------------------"
echo "Performing scan using aquatone (16 of 20)"
echo "--------------------------------------------------"
cat $wrkpth/Nmap/$prj_name-nmap_portknock.xml | aquatone -nmap -out $wrkpth/Aquatone/$prj_name-$web-$PORTNUM-aquatone_output.txt -ports xlarge -threads 10

# Testing HTTP pages further
echo "--------------------------------------------------"
echo "Performing scan using HTTP Audit (17 of 20)"
echo "--------------------------------------------------"
# nmap http scripts: http-backup-finder,http-cookie-flags,http-cors,http-default-accounts,http-iis-short-name-brute,http-iis-webdav-vuln,http-internal-ip-disclosure,http-ls,http-malware-host 
# nmap http scripts: http-method-tamper,http-mobileversion-checker,http-ntlm-info,http-open-redirect,http-passwd,http-referer-checker,http-rfi-spider,http-robots.txt,http-robtex-reverse-ip,http-security-headers
# nmap http scripts: http-server-header,http-slowloris-check,http-sql-injection,http-stored-xss,http-svn-enum,http-svn-info,http-trace,http-traceroute,http-unsafe-output-escaping,http-userdir-enum
# nmap http scripts: http-vhosts,membase-http-info,http-headers,http-methods
if [ -s $wrkpth/Nmap/SSL ]; then
    nmap -A -Pn -R --reason --resolve-all -sSUV -T4 -p "$(echo ${NEW[*]} | sed 's/ /,/g')" --open --script=http*,ssl*,vulners --script-args "userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly" -iL $wrkpth/Nmap/HTTP -oA $wrkpth/Nmap/$prj_name-nmap_http
fi
echo

# Using nikto
echo "--------------------------------------------------"
echo "Performing scan using Nikto (18 of 20)"
echo "--------------------------------------------------"
# for web in $(cat $wrktmp/FinalTargets); do
#     nikto -C all -h $web -port $(echo ${NEW[*]} | sed 's/ /,/g') -output $wrkpth/Nikto/$prj_name-$web-nikto_output.csv -Display 1,2,3,4 -maxtime 90m | tee $wrkpth/Nikto/$prj_name-$web-nikto_output.txt
# done
nikto -C all -h $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output.txt
echo

# Using gospider
echo "--------------------------------------------------"
echo "Performinging path traversal enumeration (19 of 20)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            gospider -s "http://$web:$PORTNUM" -o $wrkpth/PathEnum/GoSpider -c 10 -d 5 -t 10 -a | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-gospider_output.log
            hakrawler --url $web:$PORTNUM -js -linkfinder -robots -subs -urls -usewayback -insecure -outdir $wrkpth/PathEnum/Hakcrawler | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-hakrawler_output.log
        elif [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            gospider -s "https://$web:$PORTNUM" -o $wrkpth/PathEnum/GoSpider -c 10 -d 5 -t 10 -a | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-gospider_output.log
            hakrawler --url $web:$PORTNUM -js -linkfinder -robots -subs -urls -usewayback -insecure -outdir $wrkpth/PathEnum/Hakcrawler | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-hakrawler_output.log
        fi
    done
done
echo

# Using Wapiti, arjun and ffuf
echo "--------------------------------------------------"
echo "Performing scan using Wapiti (20  of 20)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o) # Check to see if the port is filtered & is a web service
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            wapiti -u "http://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_http_result.html -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            wapiti -u "https://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_https_result.html -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            pythoon3 /opt/Arjun/arjun.py -u "https://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_https_output.txt 2> /dev/null
            pythoon3 /opt/Arjun/arjun.py -u "http://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_http_output.txt 2> /dev/null
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt" -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_https_output -c -u "https://$web:$PORTNUM/FUZZ"
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt" -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_http_output -c -u "http://$web:$PORTNUM/FUZZ"
            echo "--------------------------------------------------"
        fi
    done
done
echo

# Using theharvester & metagoofil
echo "--------------------------------------------------"
echo "Performing scan using Theharvester and Metagoofil (21 of 20)"
echo "--------------------------------------------------"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theHarvester -d http://$web:$PORTNUM -l 500 -b all | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_http_output.txt
            timeout 900 metagoofil -d http://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_http_output.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
         elif [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theHarvester -d https://$web:$PORTNUM -l 500 -b all | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_https_output.txt
            timeout 900 metagoofil -d https://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_https_output.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
            echo "--------------------------------------------------"
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

# WRapping up assessment
gift_wrap