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
# curl --connect-timeout 5 -s https://api.github.com/repos/gbiagomba/Sherlock/tags | rg --engine -i -e o '^(\d+\.)?(\d+\.)?(\*|\d+)$'| head -1 | cut -c11-13
# https://www.regextester.com/95064

# Declaring variables
pth=$PWD
wrkpth="$PWD/Sherlock"
# KNOWN_UDP_PORTS="0,1,5,7,9,11,13,17,18,19,20,21-23,25-26,37,42,43,47,49,51,52,53,54,56,58,61,67–74,79-81,82,83,88,90,95,101,102,104,105,106,107,108,109,110-111,113,115,117,118,119,120,123,126,135-139,143-144,152,153,156,158,161-162,170,177,179,194,199,201,209,210,213,218,220,225–241,249–255,259,262,264,280,311,318,319,320,350,351,356,366,369,370,371,376,383,384,387,388,389,399,401,427,433,434,443-445,464,465,475,497,500,502,504,510,513-515,517,518,520,521,524,525,530,532,533,542,543-544,546,547,548,550,554,560,561,563,587,593,623,626,631,635,636,639,641,643,646,651,653,655,657,660,666,688,690,694,698,749,750,751,752,753,754,760,800,802,829,830,831,832,833,848,853,861,862,873,897,898,902,953,989,990,991,992,993,994,995,996-999,1011–1020,1022-1023,1024,1025-1030,1058,1059,1080,1085,1098,1099,1110,1113,1119,1167,1194,1198,1214,1218,1220,1234,1241,1270,1293,1311,1314,1341,1344,1352,1360,1414,1417,1418,1419,1420,1433-1434,1481,1494,1503,1512,1513,1521,1524,1527,1533,1534,1540,1541,1542,1545,1547,1550,1560–1590,1604,1626,1627,1628,1629,1645-1646,1701,1707,1716,1718-1720,1723,1755,1761,1801,1812-1813,1863,1880,1883,1900,1935,1965,1967,1970,1972,1984,1985,1998,2000-2001,2010,2033,2048-2049,2056,2080,2083,2086,2102,2103,2104,2121,2123,2142,2152,2159,2181,2210,2211-2223,2240,2261,2262,2302,2303,2305,2375,2376,2377,2379,2380,2389,2399,2401,2404,2427,2447,2459,2483,2484,2500,2501,2535,2541,2546–2548,2593,2599,2628,2638,2710,2717,2727,2775,2809,2811,2944,2945,2947,2948,2949,2967,3000,3020,3050,3052,3074,3128,3225,3233,3260,3268,3269,3283,3290,3305,3306,3323,3332,3351,3386,3389,3396,3412,3455,3456,3478,3479,3480,3483,3493,3516,3527,3544,3632,3645,3659,3667,3689,3690,3702,3703,3724,3725,3749,3768,3784,3785,3799,3804,3826,3830,3856,3880,3960,3962,3978,3979,3986,3999,4000,4018,4045,4069,4070,4089,4090,4093,4096,4105,4111,4116,4172,4198,4226,4244,4303,4444,4486,4488,4500,4534,4569,4662,4672,4730,4739,4753,4789,4791,4840,4843,4847,4894,4899,4944,4950,5000–5500,5554,5555,5556,5568,5631,5632,5666,5671,5672,5683,5684,5722,5741,5742,5800,5900,5931,5938,5984,6000–6063,6110,6111,6112,6244,6255,6257,6260,6343,6346,6347,6350,6444,6445,6464,6502,6515,6619,6622,6646,6653,6679,6771,6881–6968,6969,6970–6999,7000,7002,7004,7023,7070,7262,7272,7312,7400,7401,7402,7542,7547,7575,7624,7655,7707–7788,7880,7946,8000,8008-8010,8042,8074,8080-8081,8089,8090,8091,8092,8116,8194–8195,8222,8243,8280,8303,8443,8448,8530,8531,8580,8765,8767,8834,8840,8883,8887,8888,8889,8983,8997,8998,8999,9001,9080,9100,9101,9102,9103,9119,9200,9303,9309,9389,9392,9418,9535,9536,9600,9669,9675,9676,9695,9785,9800,9899,9987,9993,9999–20000,20031,20560,20582,20583,20595,20808,23513,24441,24465,24554,25575,25826,26000,27000–27015,27015–27030,27031,27036,27037,27960–27969,28015,28016,28770–28771,28785–28786,28852,28910,28960,29000,29070,29900–29901,29920,30000,30033,30718,31337,31416,32137,32768-32769,32771,32815,33281,33434,33848,34000,34197,37008,40000,41121,41794,41795,41796,41797,43594–43595,44818,47808–47823,49151-49157,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,60000–61000,64738,65024"
API_AK="" #Tenable Access Key
API_SK="" #Tenable Secret Key
# GRAB_FQDN=(rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys)")
# GRAB_IPV4=(rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
# GRAB_IPV4CIDR=$(grep -e "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}")
# GRAB_IPV6=(rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u)
NMAP_SCRIPTARG="newtargets,userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly"
NMAP_SCRIPTS="vulners,vulscan/vulscan.nse,vuln,auth,brute,targets-xml"
OS_CHK=$(cat /etc/os-release | rg -o debian)
WORDLIST="/opt/Sherlock/rsc/subdomains.list"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
diskMax=90
diskSize=$(df -kh $PWD | grep -iv filesystem | grep -o '[1-9]\+'% | cut -d "%" -f 1)
prj_name=$2
targets=$1
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
for i in Batea DNS_Recon EyeWitness GOLismero Halberd Harvester Masscan Metagoofil Nikto Nmap PathEnum SSH SSL SubDomainEnum SQLMap Wappalyzer WebVulnScan XSStrike l00tz; do
    if [ ! -e $wrkpth/$i ]; then
        mkdir -p $wrkpth/$i
    fi
done

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

# Parsing the target file
Banner "Parsing the target file"
cat $pth/$targets | rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys|\.ie)" | tee -a $wrktmp/WebTargets
cat $pth/$targets | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tee -a $wrktmp/TempTargets
cat $pth/$targets | grep -e "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}" | tee -a $wrktmp/TempTargets
cat $pth/$targets | rg --auto-hybrid-regex --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrktmp/TempTargetsv6
cat $wrktmp/TempTargets | sort -u | tee -a $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort -u | tee -a $wrktmp/IPtargetsv6
echo

# Performing Subdomain enum
Banner "Performing Subdomain enum"
if [ ! -z $wrktmp/WebTargets ]; then
    for web in $(cat $wrktmp/WebTargets); do
        Banner "with sublist3r"; sublist3r -d $web -v -t 25 -o "$wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output-$current_time.txt"
        Banner "with amass"; amass enum -brute -w $WORDLIST -d $web -ip -o "$wrkpth/SubDomainEnum/$prj_name-$web-amass_output-$current_time.txt"
        Banner "with gobuster"; gobuster dns -i -t 25 -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-gobuster_dns_output-$current_time.txt" -d $web
        Banner "with shuffledns"; shuffledns -t 25 -d $web -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-shuffledns_output-$current_time.txt" -r /opt/Sherlock/rsc/ressolvers.txt -massdns `which massdns`
        Banner "with fierce"; fierce --domain $web --subdomain-file $WORDLIST --traverse 255 2> /dev/null | tee -a "$wrkpth/SubDomainEnum/$prj_name-$web-fierce_output-$current_time.json"
    done
fi
echo

# Checking subdomains against subdomainizer & favfreak
cat $wrktmp/WebTargets | httprobe | tee -a $wrkpth/SubDomainEnum/SubDomainizer_feed-$current_time
for i in `cat $wrkpth/SubDomainEnum/SubDomainizer_feed-$current_time`; do
    timeout 1200 python3 /opt/SubDomainizer/SubDomainizer.py -u $i -k -o $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output-$current_time.txt 2> /dev/null
    cat $wrkpth/SubDomainEnum/SubDomainizer_feed-$current_time | favfreak -o $wrkpth/FavFreak
done
echo

# Pulling out all the web targets
for i in `ls $wrkpth/SubDomainEnum/ | rg "$current_time"`; do
    if [ ! -z $wrkpth/SubDomainEnum/$i ]; then
        cat $wrkpth/SubDomainEnum/$i | grep -vi "SOA:" | grep -vi "NS:" | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | tr -d ":" | tr -d "\'" | tr -d "[" | tr -d "]" | tr -d "{" | tr -d ":" | tr -d "}" | sort -u | tee -a $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tee -a $wrktmp/TempTargets
        cat $wrkpth/SubDomainEnum/$i | rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys)" | tee -a $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrktmp/TempTargetsv6
        cat $wrkpth/SubDomainEnum/$i | rg -a --auto-hybrid-regex -e '\b(https?|ftp|sql|mysql|mssql|ftp|sftp|ftps|pop3|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]' -o | sort -u | tee -a $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | rg --auto-hybrid-regex -e '(http|https|sql|mysql|mssql|ftp|sftp|ftps|pop3|file|ssh|smtp|sip|imap|rtp|ntp)://[^/"]+' -o | cut -d ":" -f 3 | cut -d "/" -f 3 | sort -u | tee -a $wrktmp/TempWeb
    fi
done
cat $wrktmp/TempWeb | sort -u | tee -a $wrktmp/WebTargets
echo

# Using halberd
Banner "Performing scan using Halberd"
cat $wrktmp/WebTargets | parallel -j 10 -k "timeout 300 halberd {} -p 25 -t 90 -v | tee $wrkpth/Halberd/$prj_name-{}-halberd_output-$current_time.txt"
for web in $(ls $wrkpth/Halberd/); do
    if [ ! -z $wrkpth/Halberd/$i ]; then
        cat $wrkpth/Halberd/$i | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tee -a $wrktmp/TempTargets
        cat $wrkpth/Halberd/$i | rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys)" | tee -a $wrktmp/TempWeb
    fi
done
echo

Banner "Some house cleaning"
# Some house cleaning
cat $wrktmp/WebTargets | rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys)" | tee -a $wrktmp/TempWeb
cat $wrktmp/IPtargets | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tee -a $wrktmp/TempTargets
cat $wrktmp/IPtargetsv6 | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrktmp/TempTargetsv6
cat $wrktmp/IPtargetsv6 | rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrktmp/TempTargetsv6
cat $wrktmp/TempWeb | sort -u | tee -a $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort -u | tee -a $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort -u | tee -a $wrktmp/IPtargetsv6
cat $wrktmp/IPtargets $wrktmp/IPtargetsv6 $wrktmp/WebTargets | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | rg -iv found | grep -vi "SOA:" | grep -vi "NS:" | rg -iv "Zone:" | tr -d ":" | tr -d "\'" | tr -d "[" | tr -d "]" | sort -u | tee -a $wrktmp/tempFinal

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
Banner "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP"
nmap -T5 --min-rate 300 --resolve-all -PA"21-23,25,53,79,80-83,88,110,111,135,139,161,179,443,445,497,515,535,548,993,1025,1028,1029,1917,2869,3389,5000,5060,6000,8080,9001,9100,49000" -PE -PM -PP -PO -PR -PS"21-23,25,53,79,80-83,88,110,111,135,139,161,179,443,445,497,515,535,548,993,1025,1028,1029,1917,2869,3389,5000,5060,6000,8080,9001,9100,49000" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time

# Nmap - IPv6 Pingsweep using TCP SYN, and UDP
Banner "Nmap - GRAB_IPV6 Pingsweep using TCP SYN, and UDP"
nmap -6 -T5 --min-rate 300 --resolve-all -PA"21-23,25,53,79,80-83,88,110,111,135,139,161,179,443,445,497,515,535,548,993,1025,1028,1029,1917,2869,3389,5000,5060,6000,8080,9001,9100,49000" -PS"21-23,25,53,79,80-83,88,110,111,135,139,161,179,443,445,497,515,535,548,993,1025,1028,1029,1917,2869,3389,5000,5060,6000,8080,9001,9100,49000" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time

# Nmap - Grabing live hosts
Banner "Grabbing livehosts from pingsweep"
if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap | rg Up | cut -d ' ' -f 2 | tee -a $wrkpth/Nmap/live-$current_time.list
    cat $wrkpth/Nmap/live-$current_time.list | sort -u > $wrkpth/Nmap/$prj_name-nmap_pingresponse-live-$current_time.list
fi

if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap | rg Up | cut -d ' ' -f 2 | tee -a $wrkpth/Nmap/$prj_name-livev6-$current_time.list
    cat $wrkpth/Nmap/$prj_name-livev6-$current_time.list | sort -u > $wrkpth/Nmap/$prj_name-nmap_pingresponsev6-live-$current_time.list
fi
echo

# Combining targets
Banner "Merging all targets files"
# cat $wrktmp/WebTargets | rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv|\.sh|\.sys)" | tee -a $wrktmp/TempWeb
# cat $wrktmp/IPtargets | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tee -a $wrktmp/TempTargets
# cat $wrktmp/IPtargetsv6 | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrktmp/TempTargetsv6
if [ -r $wrkpth/$prj_name-livehosts-$current_time.list ] || [ -r $wrkpth/Nmap/live-$current_time.list ] || [ -r $wrktmp/TempTargets ] || [ -r $wrktmp/WebTargets ]; then
    # cat $wrkpth/Masscan/live-$current_time | sort -u | tee -a $wrktmp/TempTargets
    cat $wrkpth/Nmap/live-$current_time.list | sort -u | tee -a $wrktmp/TempTargets
    cat $wrktmp/tempFinal | tee -a $wrktmp/TempTargets
    cat $wrktmp/WebTargets $wrktmp/tempFinal $wrktmp/TempTargets tee $wrktmp/IPtargets $wrktmp/IPtargetsv6 | tr " " "\n" | tr "," "\n"  | sort -u | tee -a $wrkpth/$prj_name-FinalTargets-$current_time.list
    cat $wrktmp/TempTargets | rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u | tee $wrktmp/IPtargets
    cat $wrktmp/IPtargetsv6 $wrktmp/TempTargetsv6 | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u | tee -a $wrkpth/$prj_name-FinalTargets-$current_time.list
fi
echo

# Using masscan to perform a quick port sweep
Banner "Performing portknocking scan using Masscan"
# Consider switcing to unicornscan
# unicornscan -i eth1 -Ir 160 -E 192.168.1.0/24:1-4000 gateway:a
# hostcount=$(wc -l $wrktmp/IPtargets | cut -d " " -f 4)
# nmapTimer=$(expr ((3*65535*$hostcount)/1000)*1.1)
# printf "This portion of the scan will take approx"
# convertAndPrintSeconds $nmapTimer
masscan --rate 1000 --banners --open-only --retries 3 -p 0-65535 -iL $wrktmp/IPtargets -oL $wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list
masscan --rate 1000 --banners --open-only --retries 3 -p 0-65535 -iL $wrktmp/IPtargetsv6 -oL $wrkpth/Masscan/$prj_name-masscan_portknockv6-$current_time.list
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list | cut -d " " -f 4 | rg -v masscan | sort -u | tee -a $wrkpth/$prj_name-livehosts-$current_time.list
elif [ -r "$wrkpth/Masscan/$prj_name-masscan_portknockv6-$current_time.list" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknockv6-$current_time.list | cut -d " " -f 4 | rg -v masscan | sort -u | tee -a $wrkpth/$prj_name-livehosts-$current_time.list
fi
echo

# Nmap - Full TCP SYN & UDP scan on live-$current_time targets
Banner "Performing portknocking scan using Nmap"
# time = (max-retries * ports * hosts) / min-rate
# -T4 has a max retry of 6
# hostcount=$(wc -l $wrkpth/$prj_name-FinalTargets-$current_time.list | cut -d " " -f 4)
# nmapTimer=$(expr ((6*65535*$hostcount)/300)*1.1)
# printf "This portion of the scan will take approx"
# convertAndPrintSeconds $nmapTimer
nmap -T4 --min-rate 300p -Pn -R --reason --resolve-all -sSV --open -p- --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time
nmap -T4 --min-rate 300p -Pn -R --reason --resolve-all -sTV --open -p- --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-connect-$current_time
nmap -T5 --min-rate 300p --defeat-icmp-ratelimit -Pn -R --reason --resolve-all -sUV --open --top-ports 1000 --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time

# Scanning for GRAB_IPV6
nmap -T4 --min-rate 300p -6 -Pn -R --reason --resolve-all -sSV --open -p- --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time
nmap -T4 --min-rate 300p -6 -Pn -R --reason --resolve-all -sTV --open -p- --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-connect-$current_time
nmap -T5 --min-rate 300p --defeat-icmp-ratelimit -6 -Pn -R --reason --resolve-all -sUV --open --top-ports 1000 --script $NMAP_SCRIPTS --script-args "newtargets,iX=$wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.xml" -oA $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time

# Enumerating the services discovered by nmap
# Fix the grepping
if [ -r $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap ]; then
    for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time | rg Ports | cut -d "/" -f 5 | tr "|" "\n" | sort -u`; do # smtp domain telnet microsoft-ds netbios-ssn http ssh ssl ms-wbt-server imap; do
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time.gnmap | rg $i | rg open | cut -d ' ' -f 2 | rg -iv nmap | sort -u | tee -a $wrkpth/Nmap/$prj_name-`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time.list
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time.gnmap | rg $i | cut -d " " -f 3 | cut -d "(" -f 2 | cut -d ")" -f 1 | rg -iv nmap | sort -u | tee -a $wrkpth/Nmap/$prj_name-`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time.list
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
for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-connect-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-connect-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time | rg Ports | cut -d "/" -f 5 | tr "|" "\n" | sort -u`; do
    Banner "Performing targeted scan of $i"
    PORTNUM=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i $i | cut -d "/" -f 1 | tr -d " " | sort -u))
    nmap -T4 --min-rate 300p -A -Pn -R --reason --resolve-all -sSUV --open -p "$(echo ${PORTNUM[*]} | tr  " " ",")" --script="$(ls /usr/share/nmap/scripts/ | rg $i | rg -iv brute | tr "\n" ",")$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/$prj_name-`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time.list -oA $wrkpth/Nmap/$prj_name-nmap_$i-$current_time
    nmap -6 -T4 --min-rate 300p -A -Pn -R --reason --resolve-all -sSUV --open -p "$(echo ${PORTNUM[*]} | sed 's/ /,/g')" --script="$(ls /usr/share/nmap/scripts/ | rg $i | rg -iv brute | tr "\n" ",")$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/$prj_name-`echo $i | tr '[:lower:]' '[:upper:]'`v6-$current_time.list -oA $wrkpth/Nmap/$prj_name-nmapv6_$i-$current_time
done
unset PORTNUM
echo

# Using DNS Recon
# Will revise this later to account for other ports one might use for dns
Banner "Performing scan using DNS Scan"
if [ -s $wrkpth/Nmap/$prj_name-DOMAIN-$current_time ]; then
    for IP in $(cat $wrkpth/Nmap/$prj_name-DOMAIN-$current_time); do
        echo Scanning $IP
        echo "--------------------------------------------------"
        dnsrecon -d $IP -a | tee -a $wrkpth/DNS_Recon/$prj_name-$IP-$web-DNSRecon_output-$current_time.txt
        dnsrecon -d $IP  -t zonewalk | tee -a $wrkpth/DNS_Recon/$prj_name-$IP-$web-DNSRecon_output-$current_time.txt
        echo "--------------------------------------------------"
    done
fi
echo

# Using SSH Audit
Banner "Performing scan using SSH Audit"
if [ -s $wrkpth/Nmap/$prj_name-SSH-$current_time ]; then
    SSHPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i ssh | cut -d "/" -f 1 | tr -d " " | sort -u))
        for PORTNUM in ${SSHPort[*]}; do
            echo Scanning $IP
            echo "--------------------------------------------------"
            ssh-audit -n -p $PORTNUM -T $wrkpth/Nmap/SSH-$current_time | aha -t "SSH Audit" > $wrkpth/SSH/$prj_name-$PORTNUM-ssh-audit_output-$current_time.html
            echo "--------------------------------------------------"
            ssh_scan -f $wrkpth/Nmap/SSH-$current_time -p $PORTNUM -o $wrkpth/SSH/$prj_name-$PORTNUM-ssh-scan_output-$current_time.json
            echo "--------------------------------------------------"
            # msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS file:$wrkpth/Nmap/SSH; set RPORT $PORTNUM; set USER_FILE /usr/share/seclists/Usernames/cirt-default-usernames.txt; set THREADS 25; exploit; exit -y" 2> /dev/null | tee -a $wrkpth/SSH/$prj_name-ssh-msf-$web.txt
        done
fi
echo

# Using batea
Banner "Ranking nmap output using batea"
for i in `ls $wrkpth/Nmap/ | rg -i xml | rg "$current_time"`; do
    batea -v $wrkpth/Nmap/$i | tee -a  $wrkpth/Batea/$prj_name-batea_output-$current_time.json 2> /dev/null
done
echo

# Using brutespray
Banner "Performing scan using brutespray or nrack"
if brutespray; then
  brutespray --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap -U /usr/share/seclists/Usernames/cirt-default-usernames.txt -P /usr/share/seclists/Passwords/cirt-default-passwords.txt --threads 10 --hosts 10 -c --output $wrkpth/l00tz
  brutespray --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap -U /usr/share/seclists/Usernames/cirt-default-usernames.txt -P /usr/share/seclists/Passwords/cirt-default-passwords.txt --threads 10 --hosts 10 -c --output $wrkpth/l00tz
elif ncrack; then
  ncrack -iX $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml -U /usr/share/seclists/Usernames/cirt-default-usernames.txt -P /usr/share/seclists/Passwords/cirt-default-passwords.txt -T4 -oA $wrkpth/l00tz/$prj_name-ncrack_output-$current_time
  ncrack -6 -iX $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.xml -U /usr/share/seclists/Usernames/cirt-default-usernames.txt -P /usr/share/seclists/Passwords/cirt-default-passwords.txt -T4 -oA $wrkpth/l00tz/$prj_name-ncrack_output6-$current_time
fi
echo

# Combining ports
# echo "--------------------------------------------------"
# echo "Combining ports
# echo "--------------------------------------------------"
# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i http | cut -d "/" -f 1 | tr -d " " | sort -n | uniq))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i ssl | cut -d "/" -f 1 | tr -d " " | sort -n | uniq))
if [ -z ${#HTTPPort[@]} ] && [ -z ${#SSLPort[@]} ]; then
    echo "There are no open web or ssl ports, exiting now"
    gift_wrap
    exit
fi
NEW=$(echo "${HTTPPort[@]}" "${SSLPort[@]}" | awk '/^[0-9]/' | sort -n | uniq) # Will need testing

# Using Eyewitness to take screenshots
Banner "Performing scan using EyeWitness & aquafone"
if [ ! -z $wrkpth/Nmap/$prj_name-HTTP-$current_time ] || [ ! -z $wrkpth/Nmap/HTTPS-$current_time]; then
    eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml --resolve --web --prepend-https --threads 10 --no-prompt -d $wrkpth/EyeWitness/
    if [ ! -z `$wrkpth/$prj_name-FinalTargets-$current_time.list | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u ` ]; then
        eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.xml --resolve --web --prepend-https --threads 10 --no-prompt -d $wrkpth/EyeWitnessv6/
    fi
    # Using aquafone
    cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml | aquatone -nmap -out $wrkpth/Aquatone/ -threads 10
    if [ ! -z `$wrkpth/$prj_name-FinalTargets-$current_time.list | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u ` ]; then
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.xml | aquatone -nmap -out $wrkpth/Aquatonev6/ -threads 10 # -ports xlarge
    fi
fi
cat $wrkpth/EyeWitness/parsed_xml*.txt $wrkpth/Aquatone/aquatone_urls.txt | sort -u | tee -a $wrkpth/$prj_name-web_targets-$current_time.list
echo

# Using testssl & sslcan
# switch back to for loop, testssl doesnt properly parse gnmap
Banner "Performing scan using testssl"
cd $wrkpth/SSL/
testssl --append --assume-http --full --parallel --sneaky -oA --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_output-$current_time.txt
testssl -6 --append --assume-http --full --parallel --sneaky -oA --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_outputv6-$current_time.txt
find $wrkpth/SSL/ -type f -size -1k -delete
cd $pth
echo

# Using nikto
Banner "Performing scan using Nikto"
nikto -C all -host $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output-$current_time.txt
if [ ! -z `$wrkpth/$prj_name-FinalTargets-$current_time.list | rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null || rg --auto-hybrid-regex -o -e "((([0-9a-fA-F]){1,4})\\:){7}([0-9a-fA-F]){1,4}" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort -u ` ]; then
    nikto -C all -host $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output-$current_time.txt
fi
echo

if [ ! -e $wrkpth/$prj_name-web_targets-$current_time.list ]; then
    echo "There are no web targets, skipping web testing"
    gift_wrap
    exit
fi

# Using theharvester & metagoofil
Banner "Performing scan using Theharvester and Metagoofil"
for web in $(cat  $wrkpth/$prj_name-web_targets-$current_time.list); do
    echo "--------------------------Scanning $web------------------------"
    timeout 900 theHarvester -d $web -l 500 -b all | tee $wrkpth/Harvester/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-harvester_http_output-$current_time.txt
    timeout 900 metagoofil -d $web -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-metagoofil_http_output-$current_time.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
done
if [ -d $wrkpth/Harvester/Evidence/ ]; then
    for files in $(ls $wrkpth/Harvester/Evidence/ | rg pdf); do
        pdfinfo $files.pdf | rg Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
    done
    cat $wrkpth/Harvester/tempusr | sort -u > $wrkpth/Harvester/Usernames
    rm $wrkpth/Harvester/tempusr
fi
echo

# Using Wappalyzer
Banner "Performing scan using Wappalyzer"
for web in $(cat  $wrkpth/$prj_name-web_targets-$current_time.list); do
    echo "--------------------------Scanning $web------------------------"
    if hash wappalyzer 2> /dev/null; then
        wappalyzer $web -r -D 3 -m 50 --pretty | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json
    elif hash docker && [ -z $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json ] 2> /dev/null; then
        docker run --rm wappalyzer/cli $web -r -D 3 -m 50 --pretty | tee -a $wrkpth/Wappalyzer/$prj_name-wappalyzer_output-$current_time.json
    fi
done
find $wrkpth/Wappalyzer/ -type f -size -1k -delete
echo

# Using XSStrike
Banner "Performing scan using XSStrike"
for web in $(cat  $wrkpth/$prj_name-web_targets-$current_time.list); do
    echo "--------------------------Scanning $web------------------------"
    python3 /opt/XSStrike/xsstrike.py -u $web --crawl -t 10 -l 10 | tee -a $wrkpth/XSStrike/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-xsstrike_output-$current_time.txt
done
find $wrkpth/XSStrike/ -type f -size -1k -delete
echo

# Using sqlmap & uro
Banner "Parsing wappalyzer using uro"
cat $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json | jq '.urls' | cut -d \" -f 2 | sort -u | egrep -iv "status|\}|\{" | tee -a $wrkpth/Wappalyzer/$prj_name-url_targets-$current_time.list
Banner "Scanning for SQLi using SQLMap"
sqlmap -m "$wrkpth/Wappalyzer/$prj_name-url_targets-$current_time.list" --level=5 --risk=3 -a --os-shell --batch --disable-coloring --output-dir=$wrkpth/SQLMap/ --results-file=$wrkpth/SQLMap/$prj_name-sqlmap_output-$current_time.csv | tee -a $wrkpth/SQLMap/$prj_name-sqlmap_output-$current_time.log

# Using Goverview
Banner "Getting an overfiew of URLs"
cat $wrkpth/$prj_name-web_targets-$current_time.list | goverview probe -N -L -j -c 25 | tee -a -a $wrkpth/PathEnum/$prj_name-goverview_output-$current_time.json
echo

# Using Dalfox
Banner "Scanning using dalfox"
dalfox file $wrkpth/Wappalyzer/$prj_name-url_targets-$current_time.list -F --mass --custom-payload /opt/xss-payload-list/Intruder/xss-payload-list.txt -o $wrkpth/XSStrike/$prj_name-dalfox_output-$current_time.out
echo

# Using gospider, hakrawler, gobuster, dirdby
Banner "Performing path traversal enumeration"
for web in $(cat  $wrkpth/$prj_name-web_targets-$current_time.list); do
    echo "--------------------------Scanning $web------------------------"
    gospider -s "$web" -o $wrkpth/PathEnum/GoSpider -c 10 -d 5 -t 10 -a | tee -a $wrkpth/PathEnum/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-gospider_output-$current_time.log
    hakrawler --url $web -js -linkfinder -robots -subs -urls -usewayback -insecure -depth 10 -outdir $wrkpth/PathEnum/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-Hakcrawler-$current_time | tee -a $wrkpth/PathEnum/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-hakrawler_output.log
    gobuster dir -t 10 -w /usr/share/seclists/Discovery/Web-Content/common.txt -o $wrkpth/PathEnum/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-gobuster-$current_time -k --wildcard -u "$web"
    dirdby -f /usr/share/seclists/Discovery/Web-Content/common.txt -t 10 -u "$web" | tee -a $wrkpth/PathEnum/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-dirbpy_output-$current_time.log
done
echo

# Using Nuclei, Wapiti, arjun and ffuf
Banner "Performing scan using nuclei, Wapiti, arjun, and ffuf"
if nuclei 2> /dev/null; then 
    nuclei -t technologies/ -t network/ -t miscellaneous/ -t iot/ -t headless/ -t file/ -t exposed-panels/ -t dns/ -t default-logins/ -t cnvd/ -t cves/ -t exposures/ -t misconfiguration/ -t vulnerabilities/ -t takeovers/ -t fuzzing/ -l $wrkpth/$prj_name-web_targets-$current_time.list -o $wrkpth/WebVulnScan/$prj_name-nuclei_output-$current_time.out -severity critical,high,medium,info -exclude dos
elif docker 2> /dev/null && [ `wc -l $wrkpth/WebVulnScan/$prj_name-nuclei_output-$current_time.out | cut -d ' ' -f 8` eq 0 ]; then
    docker run --rm -it -v "$PWD:/media/Project" projectdiscovery/nuclei -t technologies/ -t network/ -t miscellaneous/ -t iot/ -t headless/ -t file/ -t exposed-panels/ -t dns/ -t default-logins/ -t cnvd/ -t cves/ -t exposures/ -t misconfiguration/ -t vulnerabilities/ -t takeovers/ -t fuzzing/ -severity critical,high,medium,info -exclude dos -c 25 -nc -l /media/Project/Sherlock/$prj_name-web_targets.list -o /media/Project/Sherlock/WebVulnScan/$prj_name-nuclei_output-$current_time.out -vv | tee -a $wrkpth/WebVulnScan/$prj_name-nuclei_output-$current_time.txt
fi
for web in $(cat  $wrkpth/$prj_name-web_targets-$current_time.list); do
    echo "--------------------------Scanning $web------------------------"
    wapiti -u "$web" -o $wrkpth/WebVulnScan/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-wapiti_http_result-$current_time -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-wapiti_result-$current_time.log
    pythoon3 /opt/Arjun/arjun.py -u "$web" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-arjun_output-$current_time.txt 2> /dev/null
    ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w /usr/share/seclists/Fuzzing/fuzz-Bo0oM.txt -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-`echo $web | tr "/" "_" | tr ":" "_" | cut -d "_" -f 1,4-5`-ffuf_output -c -u "$web/FUZZ"
done
echo

# WRapping up assessment
gift_wrap
} 2> /dev/null | tee -a $wrkpth/$prj_name-sherlock_output-$current_time.txt
