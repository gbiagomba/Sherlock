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
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"
API_AK="" #Tenable Access Key
API_SK="" #Tenable Secret Key
NMAP_SCRIPTARG="newtargets,userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly"
NMAP_SCRIPTS="vulners,vulscan/vulscan.nse"
OS_CHK=$(cat /etc/os-release | grep -o debian)
WORDLIST="/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
diskMax=95
diskSize=$(df | grep /dev/sda1 | cut -d " " -f 13 | cut -d "%" -f 1)
targets=$1
prj_name=$2
wrktmp=$(mktemp -d)

# Functions
function Banner
{
    echo
    echo "--------------------------------------------------"
    echo "$1
    Current Time : $current_time"
    echo "--------------------------------------------------"
}

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

# Starting services
service postgresql start
service docker start

{
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

    if [ ! -r $targets ]; then
        echo "File not found! Try again!"
        exit
    fi
fi

if [ -z $prj_name ]; then
    echo "What is the name of the project?
    Leave blank and hit enter if you do not have one"
    read prj_name
    echo

    if [ -z $prj_name ]; then
        prj_name=$RANDOM
    fi
fi

# Recording screen output
# exec >|$PWD/$prj_name-term_output.log 2>&1

# Parsing the target file
cat $pth/$targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv)" > $wrktmp/WebTargets
cat $pth/$targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $wrktmp/TempTargets
cat $pth/$targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> $wrktmp/TempTargets
cat $pth/$targets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" >> $wrktmp/TempTargetsv6
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq > $wrktmp/IPtargetsv6
echo

# Using sublist3r 
Banner "Performing Subdomain enum"
# consider replacing with  gobuster -m dns -o gobuster_output.txt -u example.com -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
# gobuster -m dns -cn -e -i -r -t 25 -w $WORDLIST -o "$wrkpth/PathEnum/$prj_name-gobuster_dns_output-$web.txt" -u example.com
if [ ! -z $wrktmp/WebTargets ]; then
    for web in $(cat $wrktmp/WebTargets); do
        sublist3r -d $web -v -t 25 -o "$wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output.txt"
        amass enum -brute -w $WORDLIST -d $web -ip -o "$wrkpth/SubDomainEnum/$prj_name-$web-amass_output.txt"
        gobuster dns -i -t 25 -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-gobuster_dns_output.txt" -d $web
        shuffledns -d $web -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-shuffledns_output.txt" -r /opt/Sherlock/rsc/ressolvers.txt -massdns `which massdns`
    done
fi
echo

# Checking subdomains against subdomainizer
cat $wrktmp/WebTargets | httprobe | tee -a $wrkpth/SubDomainEnum/SubDomainizer_feed.txt
for i in `cat $wrkpth/SubDomainEnum/SubDomainizer_feed.txt`; do python3 /opt/SubDomainizer/SubDomainizer.py -u $i -k -o $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output.txt 2> /dev/null; done
echo

# Pulling out all the web targets
for i in `ls $wrkpth/SubDomainEnum/`; do
    if [ ! -z $wrkpth/SubDomainEnum/$i ]; then
        cat $wrkpth/SubDomainEnum/$i | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | sort | uniq >> $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
        cat $wrkpth/SubDomainEnum/$i | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info)" >> $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" >> $wrktmp/TempTargetsv6
    fi
done
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets

# Using amass
# amass enum -brute -w /usr/local/share/sec_lists/Discovery/Web_Content/raft-large-directories.txt -d www.cars.com

# Using halberd
Banner "Performing scan using Halberd"
cat $wrktmp/WebTargets | parallel -j 10 -k "timeout 300 halberd {} -p 25 -t 90 -v | tee $wrkpth/Halberd/$prj_name-{}-halberd_output.txt"
for web in $(ls $wrkpth/Halberd/); do
    if [ ! -z $wrkpth/Halberd/$i ]; then
        cat $wrkpth/Halberd/$i | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrktmp/TempTargets
    fi
done

Banner "Some house cleaning"
# Some house cleaning
cat $wrktmp/WebTargets >> $wrktmp/TempWeb
cat $wrktmp/IPtargets >> $wrktmp/TempTargets
cat $wrktmp/IPtargetsv6 >> $wrktmp/TempTargetsv6
cat $wrktmp/TempWeb | sort | uniq | tee -a $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort | uniq | tee $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq | tee $wrktmp/IPtargetsv6
cat  $wrktmp/TempTargets $wrktmp/IPtargets $wrktmp/IPtargetsv6 $wrktmp/WebTargets | tr "," "\n" | sort | uniq | tee -a $wrktmp/tempFinal

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
Banner "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP"
nmap -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PE -PM -PP -PO -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -T5 -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep
if [ -z `$wrktmp/tempFinal | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    nmap -6 -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -T5 -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweepv6
fi

if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweep.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
    cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponse
fi

if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweepv6.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/livev6
    cat $wrkpth/Nmap/livev6 | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponsev6
fi
echo

# Combining targets
Banner "Merging all targets files"
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

Banner "Printing final list of targets to be used"
cat $wrktmp/FinalTargets $wrktmp/IPtargets | sort | uniq
echo

# Using masscan to perform a quick port sweep
# Consider switcing to unicornscan
# unicornscan -i eth1 -Ir 160 -E 192.168.1.0/24:1-4000 gateway:a
Banner "Performing portknocking scan using Masscan"
masscan -iL $wrktmp/IPtargets -p 0-65535 --rate 1000 --open-only -oL $wrkpth/Masscan/$prj_name-masscan_portknock
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock" ] && [ -s "$wrkpth/Masscan/$prj_name-masscan_portknock" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknock | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
fi
echo 

# Nmap - Full TCP SYN & UDP scan on live targets
Banner "Performing portknocking scan using Nmap"
echo "Full TCP SYN & UDP scan on live targets"
nmap --min-rate 300 -P0 -R --reason --resolve-all -sSU -T4 --open -p- -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    nmap --min-rate 300 -6 -P0 -R --reason --resolve-all -sSU -T4 --open -p- -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknockv6
fi

# Enumerating the services discovered by nmap
if [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.xml ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap ]; then
    for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d "/" -f 5 | tr "|" "\n" | sort | uniq`; do # smtp domain telnet microsoft-ds netbios-ssn http ssh ssl ms-wbt-server imap; do
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep $i | grep open | cut -d ' ' -f 2 | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`
        cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv)" | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`
        cat $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $i | grep open | cut -d ' ' -f 2 | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`-v6
        cat $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv)" | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`
    done
else
    echo "Something want wrong, ethier the nmap output files do not exist or it is were empty
    I recommend chacking the $wrkpth/Nmap/
    Then check your network connection & re-run this script"
    gift_wrap
    exit
fi
echo

# Checking all the services discovery by nmap
for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d "/" -f 5 | tr "|" "\n" | sort | uniq`; do
    Banner "Performing targeted scan of $i"
    PORTNUM=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d ":" -f 3 | tr "," "\n" | grep -iv nmap | grep -i $i | cut -d "/" -f 1 | tr -d " " | sort | uniq))
    nmap --min-rate 300 -A -P0 -R --reason --resolve-all -sSUV -T4 --open -p "$(echo ${PORTNUM[*]} | tr  " " ",")" --script="$(ls /usr/share/nmap/scripts/ | grep $i | tr "\n" ","),$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'` -oA $wrkpth/Nmap/$prj_name-nmap_$i
    nmap -6 --min-rate 300 -A -P0 -R --reason --resolve-all -sSUV -T4 --open -p "$(echo ${PORTNUM[*]} | sed 's/ /,/g')" --script="$(ls /usr/share/nmap/scripts/ | grep $i | tr "\n" ","),$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`-v6 -oA $wrkpth/Nmap/$prj_name-nmap_$i-v6
    unset PORTNUM
done
echo

# Using testssl & sslcan
# switch back to for loop, testssl doesnt properly parse gnmap
Banner "Performing scan using testssl"
cd $wrkpth/SSL/
testssl --assume-http --csv --full --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_output.txt
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    testssl -6 --assume-http --csv --full --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_outputv6.txt
fi
cd $pth
echo

# Using DNS Recon
# Will revise this later to account for other ports one might use for dns
Banner "Performing scan using DNS Scan"
if [ -s $wrkpth/Nmap/DOMAIN ]; then
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
Banner "Performing scan using SSH Audit"
SSHPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d ":" -f 3 | tr "," "\n" | grep -iv nmap | grep -i ssh | cut -d "/" -f 1 | tr -d " " | sort | uniq))
if [ -s $wrkpth/Nmap/SSH ]; then
    for IP in $(cat $wrkpth/Nmap/SSH); do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $IP | grep "$PORTNUM/open/tcp//ssh" -m 1 -o | grep "ssh" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $IP | grep "$PORTNUM/filtered/tcp//ssh" -m 1 -o | grep "ssh" -o) # Check to see if the port is filtered & is a web service
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
fi
echo

# Using batea
Banner "Ranking nmap output using batea"
for i in `ls $wrkpth/Nmap/ | grep -i xml`; do
    batea -v $wrkpth/Nmap/$i | tee -a  $wrkpth/Batea/$prj_name-batea_output.json 2> /dev/null
done
echo

# Combining ports
# echo "--------------------------------------------------"
# echo "Combining ports
# echo "--------------------------------------------------"
# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d ":" -f 3 | tr "," "\n" | grep -iv nmap | grep -i http | cut -d "/" -f 1 | tr -d " " | sort | uniq))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep Ports | cut -d ":" -f 3 | tr "," "\n" | grep -iv nmap | grep -i ssl | cut -d "/" -f 1 | tr -d " " | sort | uniq))
if [ -z ${#HTTPPort[@]} ] && [ -z ${#SSLPort[@]} ]; then
    echo "There are no open web or ssl ports, exiting now"
    gift_wrap
    exit
fi
NEW=$(echo "${HTTPPort[@]}" "${SSLPort[@]}" | awk '/^[0-9]/' | sort | uniq) # Will need testing
# Consider using the below script to parse for ports (https://github.com/superkojiman/scanreport)
# ./scanreport.sh -f XPC-2020Q1-nmap_portknock.gnmap -s http | grep -v Host | cut -d$'\t' -f 1 | sort | uniq

# Using Eyewitness to take screenshots
Banner "Performing scan using EyeWitness & aquafone"
eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock.xml --resolve --web --prepend-https --threads 25 --no-prompt --resolve -d $wrkpth/EyeWitness/
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknockv6.xml --resolve --web --prepend-https --threads 25 --no-prompt --resolve -d $wrkpth/EyeWitnessv6/
fi
# Using aquafone
cat $wrkpth/Nmap/$prj_name-nmap_portknock.xml | aquatone -nmap -out $wrkpth/Aquatone/ -ports xlarge -threads 10
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_portknockv6.xml | aquatone -nmap -out $wrkpth/Aquatone/ -ports xlarge -threads 10
fi
echo 

# converting HTTP targets into weblinks
cat $wrktmp/FinalTargets | httprobe | tee -a $wrktmp/FinalWeb

# Using Wappalyzer
Banner "Performing scan using Wappalyzer"
for web in $(cat $wrktmp/FinalWeb); do
    echo Scanning $web
    echo "--------------------------------------------------"
    if wappalyzer; then
        wappalyzer $web | python -m json.tool | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output.json
    elif docker; then
        docker run --rm wappalyzer/cli $web | python -m json.tool | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output.json
    fi
    echo "--------------------------------------------------"
done
echo

# Using XSStrike
Banner "Performing scan using XSStrike"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u https://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
        fi

        if [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u http://$web:$PORTNUM --crawl | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output.txt
            echo "--------------------------------------------------"
        fi
    done
done
echo

# Using nikto
Banner "Performing scan using Nikto"
nikto -C all -h $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -IgnoreCode 302,301 -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output.txt
if [ -z `$wrktmp/FinalTargets | grep -oE "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" ` ]; then
    nikto -C all -h $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -IgnoreCode 302,301 -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output.txt
fi

echo

# Using gospider
Banner "Performing path traversal enumeration"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            gospider -s "http://$web:$PORTNUM" -o $wrkpth/PathEnum/GoSpider -c 10 -d 5 -t 10 -a | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-gospider_output.log
            hakrawler --url $web:$PORTNUM -js -linkfinder -robots -subs -urls -usewayback -insecure -outdir $wrkpth/PathEnum/Hakcrawler | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-hakrawler_output.log
        fi

        if [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            gospider -s "https://$web:$PORTNUM" -o $wrkpth/PathEnum/GoSpider -c 10 -d 5 -t 10 -a | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-gospider_output.log
            hakrawler --url $web:$PORTNUM -js -linkfinder -robots -subs -urls -usewayback -insecure -outdir $wrkpth/PathEnum/Hakcrawler | tee -a $wrkpth/PathEnum/$prj_name-$web-$PORTNUM-hakrawler_output.log
        fi
    done
done
echo

# Using Wapiti, arjun and ffuf
Banner "Performing scan using Wapiti, arjun, and ffuf"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open" -m 1 -o | grep "open" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o) # Check to see if the port is filtered & is a web service
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            wapiti -u "http://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_http_result.html -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            wapiti -u "https://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_https_result.html -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            pythoon3 /opt/Arjun/arjun.py -u "https://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_https_output.txt 2> /dev/null
            pythoon3 /opt/Arjun/arjun.py -u "http://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_http_output.txt 2> /dev/null
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w  $WORDLIST -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_https_output -c -u "https://$web:$PORTNUM/FUZZ"
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w  $WORDLIST -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_http_output -c -u "http://$web:$PORTNUM/FUZZ"
            echo "--------------------------------------------------"
        fi
    done
done
echo

# Using theharvester & metagoofil
Banner "Performing scan using Theharvester and Metagoofil"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//http" -m 1 -o | grep "http" -o) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/open/tcp//ssl" | grep "ssl" -o) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock.gnmap $wrkpth/Nmap/$prj_name-nmap_portknockv6.gnmap | grep $web | grep "$PORTNUM/filtered/tcp//ssl" | grep "ssl" -o) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theHarvester -d http://$web:$PORTNUM -l 500 -b all | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_http_output.txt
            timeout 900 metagoofil -d http://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_http_output.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
         fi

        if [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
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
} | tee -a $pth/$prj_name-$current_time-sherlock_output.txt