#!/bin/sh
# Author: Gilles Biagomba
# Program:Web Inspector
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specficailly recon).\n

# for debugging purposes
# set -eux

# Declaring variables
n=0
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
x=0
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"

# Setting Envrionment
mkdir -p  $wrkpth/Halberd/ $wrkpth/Sublist3r/ $wrkpth/Harvester $wrkpth/Metagoofil
mkdir -p $wrkpth/Nikto/ $wrkpth/Dirb/ $wrkpth/Nmap/ $wrkpth/Sniper/
mkdir -p $wrkpth/Masscan/ $wrkpth/Arachni/ $wrkpth/TestSSL/ $wrkpth/SSLScan/

# Moving back to original workspace & loading logo
cd $pth

echo "
_____ _               _            _    _ 
/ ____| |             | |          | |  | |
| (___ | |__   ___ _ __| | ___   ___| | _| |
\___ \| '_ \ / _ \ '__| |/ _ \ / __| |/ / |
____) | | | |  __/ |  | | (_) | (__|   <|_|
|_____/|_| |_|\___|_|  |_|\___/ \___|_|\_(_)
"                                        
echo "Web application scanning is elementary my dear Watson!"
echo

# Requesting target file name & project name
echo "What is the name of the targets file? The file with all the IP addresses or sites"
read targets
echo
echo "What is the name of the project?"
read prj_name
echo

if [ "$targets" != "$(ls $pth | grep $targets)" ]; then
    echo "File not found! Try again!"
    exit
fi

# Parsing the target file
cat $pth/$targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" > $wrkpth/WebTargets
cat $pth/$targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $wrkpth/TempTargets
cat $pth/$targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> $wrkpth/TempTargets
cat $wrkpth/TempTargets | sort | uniq > $wrkpth/IPtargets
echo

# Using sublist3r 
echo "--------------------------------------------------"
echo "Performing scan using Sublist3r"
echo "--------------------------------------------------"
n=0
for web in $(cat $wrkpth/WebTargets);do
    echo $((++n))
	sublist3r -d $web -v -t 5 -o "$wrkpth/Sublist3r/$prj_name-sublist3r_output-$((n))"
    cat $wrkpth/Sublist3r/$prj_name-sublist3r_output-$((n)) > $wrkpth/TempWeb
done
cat $wrkpth/WebTargets >> $wrkpth/TempWeb
cat $wrkpth/TempWeb | sort | uniq > $wrkpth/WebTargets
echo 

# Using halberd
echo "--------------------------------------------------"
echo "Performing scan using Halberd"
echo "--------------------------------------------------"
n=0
for web in $(cat $wrkpth/WebTargets);do
    echo $((++n))
	halberd $web -p 5 -t 90 -v | tee $wrkpth/Halberd/$prj_name-halberd_output-$((n))
    cat $wrkpth/Halberd/$prj_name-halberd_output-$((n)) | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrkpth/TempTargets
done
cat $wrkpth/TempTargets | sort | uniq > $wrkpth/IPtargets
echo

# Using theharvester & metagoofil
echo "--------------------------------------------------"
echo "Performing scan using Theharvester and Metagoofil"
echo "--------------------------------------------------"
n=0
x=0
for web in $(cat $wrkpth/WebTargets);do    
    echo $((++n))
    echo $((++x))
    theharvester -d $web -l 500 -b all -h | tee $wrkpth/Harvester/$prj_name-harvester_output-$((n))
    metagoofil -d $web -l 500 -o $wrkpth/Harvester/Evidence -f $wrkpth/Harvester/$prj_name-metagoofil_output-$((x)).html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
    cat $prj_name-harvester_output-$((n)) | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> $wrkpth/TempTargets
    cat $prj_name-harvest_output-$((x)) |grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" | cut -d ":" -f 1 >> $wrkpth/TempWeb
done
cat $wrkpth/WebTargets >> $wrkpth/TempWeb
cat $wrkpth/IPtargets >> $wrkpth/TempTargets
cat $wrkpth/TempWeb | sort | uniq > $wrkpth/WebTargets
cat $wrkpth/TempTargets | sort | uniq > $wrkpth/IPtargets

# Parsing PDF documents
echo "--------------------------------------------------"
echo "Parsing all the PDF documents found"
echo "--------------------------------------------------"
#add a if statement to make sure the directory isnt empty, so if it is you can skip this step
for files in $(ls $wrkpth/Harvester/Evidence/ | grep pdf);do
    pdfinfo $files.pdf | grep Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
done
cat $wrkpth/Harvester/tempusr | sort | uniq > $wrkpth/Harvester/Usernames
echo

# Using masscan to perform a quick port sweep
echo "--------------------------------------------------"
echo "Performing scan using Masscan"
echo "--------------------------------------------------"
masscan -iL $wrkpth/IPtargets -p 0-65535 --open-only --banners -oL $wrkpth/Masscan/$prj_name-masscan_output
cat $wrkpth/Masscan/$prj_name-masscan_output | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
OpenPORT=($(cat $wrkpth/Masscan/$prj_name-masscan_output | cut -d " " -f 3 | grep -v masscan | sort | uniq))
#OpenPORT=($(cat $wrkpth/Masscan/$prj_name-masscan_output | cut -d " " -f 3 | grep -v masscan | sort | uniq))
echo 

# Combining targets
echo "--------------------------------------------------"
echo "Merging all targets files"
echo "--------------------------------------------------"
cat $wrkpth/IPtargets > $pth/FinalTargets
cat $wrkpth/WebTargets >> $pth/FinalTargets
echo

# Using Nmap
echo "--------------------------------------------------"
echo "Performing scan using Nmap"
echo "--------------------------------------------------"

# Nmap - Pingsweep using ICMP echo
nmap -sP -PE -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmpecho
cat $wrkpth/Nmap/icmpecho.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmpecho.xml -o $wrkpth/Nmap/icmpecho.html
echo

# Nmap - Pingsweep using ICMP timestamp
nmap -sP -PP -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmptimestamp
cat $wrkpth/Nmap/icmptimestamp.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmptimestamp.xml -o $wrkpth/Nmap/icmptimestamp.html
echo

# Nmap - Pingsweep using ICMP netmask
nmap -sP -PM -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmpnetmask
cat $wrkpth/Nmap/icmpnetmask.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmpnetmask.xml -o $wrkpth/Nmap/icmpnetmask.html
echo

# Systems that respond to ping (finding)
cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/pingresponse
echo

# Nmap - Pingsweep using TCP SYN and UDP
nmap -sP -PS 21,22,23,25,53,80,88,110,111,135,139,443,445,8080 -iL $pth/FinalTargets -oA $wrkpth/Nmap/pingsweepTCP
nmap -sP -PU 53,111,135,137,161,500 -iL $pth/FinalTargets -oA $wrkpth/Nmap/pingsweepUDP
cat $wrkpth/Nmap/pingsweepTCP.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
cat $wrkpth/Nmap/pingsweepUDP.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/pingsweepTCP.xml -o $wrkpth/Nmap/pingsweepTCP.html
xsltproc $wrkpth/Nmap/pingsweepUDP.xml -o $wrkpth/Nmap/pingsweepUDP.html
echo

# Nmap - Full TCP SYN scan on live targets
# nmap http scripts: http-backup-finder,http-cookie-flags,http-cors,http-default-accounts,http-iis-short-name-brute,http-iis-webdav-vuln,http-internal-ip-disclosure,http-ls,http-malware-host 
# nmap http scripts: http-method-tamper,http-mobileversion-checker,http-ntlm-info,http-open-redirect,http-passwd,http-referer-checker,http-rfi-spider,http-robots.txt,http-robtex-reverse-ip,http-security-headers
# nmap http scripts: http-server-header,http-slowloris-check,http-sql-injection,http-stored-xss,http-svn-enum,http-svn-info,http-trace,http-traceroute,http-unsafe-output-escaping,http-userdir-enum
# nmap http scripts: http-vhosts,membase-http-info,http-headers,http-methods
nmap -A -Pn -R -sS -sV -p $(echo ${OpenPORT[*]} | sed 's/ /,/g') --script=ssl-enum-ciphers,vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/TCPdetails
xsltproc $wrkpth/Nmap/TCPdetails.xml -o $wrkpth/Nmap/Nmap_Output.html
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 25/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMTP
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 53/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/DNS
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 23/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/telnet
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 445/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMB
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 139/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/netbios
cat $wrkpth/Nmap/TCPdetails.gnmap | grep http | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/http
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/ssh
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/ssl
cat $wrkpth/Nmap/TCPdetails.gnmap | grep Up | cut -d ' ' -f 2 > $wrkpth/Nmap/live
cat $wrkpth/Nmap/live | sort | uniq >> $wrkpth/livehosts
echo

# Nmap - Default UDP scan on live targets
nmap -sU -PN -T4 -iL $pth/FinalTargets -oA $wrkpth/Nmap/UDPdetails
cat $pth/UDPdetails.gnmap | grep ' 161/open\?\!|' | cut -d ' ' -f 2 > $pth/SNMP
cat $pth/UDPdetails.gnmap | grep ' 500/open\?\!|' | cut -d ' ' -f 2 > $pth/isakmp
xsltproc $wrkpth/Nmap/UDPdetails.xml -o $wrkpth/Nmap/UDPdetails.html
echo

# Nmap - Firewall evasion
nmap -f -mtu 24 --spoof-mac Dell --randomize-hosts -A -Pn -R -sS -sU -sV --script=vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/FW_Evade
nmap -D RND:10 --badsum --data-length 24 --randomize-hosts -A -Pn -R -sS -sU -sV --script=vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/FW_Evade2
xsltproc $wrkpth/Nmap/FW_Evade.xml -o $wrkpth/Nmap/FW_Evade.html
xsltproc $wrkpth/Nmap/FW_Evade2.xml -o $wrkpth/Nmap/FW_Evade2.html
echo

# Using nikto
echo "--------------------------------------------------"
echo "Performing scan using Nikto"
echo "--------------------------------------------------"
n=0
for web in $(cat $pth/FinalTargets);do
    echo $((++n))
    nikto -C all -h https://$web -port $(echo ${OpenPORT[*]} | sed 's/ /,/g') -o $wrkpth/Nikto/$prj_name-nikto_https_output-$((n)).csv | tee $wrkpth/Nikto/$prj_name-nikto_https_output-$((n)).txt &
    nikto -C all -h http://$web -port $(echo ${OpenPORT[*]} | sed 's/ /,/g') -o $wrkpth/Nikto/$prj_name-nikto_http_output-$((++n)).csv | tee $wrkpth/Nikto/$prj_name-nikto_http_output-$((n)).txt &
    wait
done
echo

# Using dirb
echo "--------------------------------------------------"
echo "Performing scan using Dirb"
echo "--------------------------------------------------"
n=0
for web in $(cat $pth/FinalTargets);do
    for PORTNUM in ${OpenPORT[*]}; do
        STAT1=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo $((++n))
            dirb https://$web:$PORTNUM /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o $wrkpth/Dirb/$prj_name-dirb_https_output-$((n)) -w &
            dirb http://$web:$PORTNUM /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o $wrkpth/Dirb/$prj_name-dirb_http_output-$((++n)) -w &
            wait
        fi
    done
done
echo

# Using arachni
echo "--------------------------------------------------"
echo "Performing scan using arachni"
echo "--------------------------------------------------"
n=0
x=0
for web in $(cat $pth/FinalTargets);do    
    echo $((++n))
    echo $((++x))
    arachni_multi https://$web http://$web --report-save-path=$wrkpth/Arachni/$prj_name-$((n)).afr
    arachni_reporter $wrkpth/Arachni/$prj_name-$((n)).afr --reporter=html:outfile=$wrkpth/Arachni/$prj_name-Arachni/HTML_Report$((x)).zip
    arachni_reporter $wrkpth/Arachni/$prj_name-$((n)).afr --reporter=json:outfile=$wrkpth/Arachni/$prj_name-Arachni/JSON_Report$((x)).zip
    arachni_reporter $wrkpth/Arachni/$prj_name-$((n)).afr --reporter=txt:outfile=$wrkpth/Arachni/$prj_name-Arachni/TXT_Report$((x)).zip
    arachni_reporter $wrkpth/Arachni/$prj_name-$((n)).afr --reporter=xml:outfile=$wrkpth/Arachni/$prj_name-Arachni/XML_Report$((x)).zip
done

# Using testssl & sslcan
echo "--------------------------------------------------"
echo "Performing scan using arachni"
echo "--------------------------------------------------"
n=0
x=0
for IP in $(cat $pth/FinalTargets);do
    for PORTNUM in ${OpenPORT[*]}; do
        STAT1=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $wrkpth/Nmap/TCPdetails.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then            
            echo $((++n))
            echo $((++x))
            sslscan --xml=$wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$((n)).xml $IP:$PORTNUM | tee -a $wrkpth/SSLScan/$prj_name-$IP:$PORTNUM-sslscan_output-$((n)).txt
            testssl -oA "$wrkpth/TestSSL/TLS/$prj_name-$IP:$PORTNUM-testssl_output-$((x))" --append --parallel --sneaky $IP:$PORTNUM | tee -a $wrkpth/TestSSL/$prj_name-$IP:$PORTNUM-TestSSL_output-$((x)).txt
        fi
    done
done

# Using sniper
echo "--------------------------------------------------"
echo "Performing scan using Sn1per"
echo "--------------------------------------------------"
for web in $(cat $pth/FinalTargets);do
    sniper -w $prj_name -f $wrkpth/FinalTargets -m nuke -p $PORTNUM
done
echo

# Add zipping of all content and sending it via some medium (e.g., email, ftp, etc)

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
rm $wrkpth/IPtargets -f
rm $wrkpth/TempTargets -f
rm tempusr -f
rm $wrkpth/TempWeb -f
rm $wrkpth/WebTargets -f

# Uninitializing variables
# do later
set -u