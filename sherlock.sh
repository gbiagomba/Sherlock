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
GRAB_FQDN=$(rg --auto-hybrid-regex --engine -i -e "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz|\.io|\.info|\.tv)")
# GRAB_IPV4=$(rg --auto-hybrid-regex --engine -o -e "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
GRAB_IPV4CIDR=$(grep -e "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}")
IPv6=$(rg --engine -i -o -e "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" 2> /dev/null | rg -iv "FE80:" | cut -d ":" -f 2-9 | sort | uniq)
NMAP_SCRIPTARG="newtargets,userdb=/usr/share/seclists/Usernames/cirt-default-usernames.txt,passdb=/usr/share/seclists/Passwords/cirt-default-passwords.txt,unpwdb.timelimit=15m,brute.firstOnly"
NMAP_SCRIPTS="vulners,vulscan/vulscan.nse"
OS_CHK=$(cat /etc/os-release | rg -o debian)
WORDLIST="/opt/Sherlock/rsc/subdomains.list"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
diskMax=95
diskSize=$(df | rg /dev/sda1 | cut -d " " -f 13 | cut -d "%" -f 1)
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

# https://bytefreaks.net/gnulinux/bash/convertandprintseconds-convert-seconds-to-minutes-hours-and-days-in-bash
convertAndPrintSeconds() 
{
    # local totalSeconds=$1;
    # local seconds=$((totalSeconds%60));
    # local minutes=$((totalSeconds/60%60));
    # local hours=$((totalSeconds/60/60%24));
    # local days=$((totalSeconds/60/60/24));
    # (( $days > 0 )) && printf '%d days ' $days;
    # (( $hours > 0 )) && printf '%d hours ' $hours;
    # (( $minutes > 0 )) && printf '%d minutes ' $minutes;
    # (( $days > 0 || $hours > 0 || $minutes > 0 )) && printf 'and ';
    # printf '%d seconds\n' $seconds;
        num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"m "$sec"s
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
for i in Batea DNS_Recon EyeWitness GOLismero Halberd Harvester Masscan Metagoofil Nikto Nmap PathEnum SSH SSL SubDomainEnum Wappalyzer WebVulnScan XSStrike l00tz; do
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

# Recording screen output
# exec >|$PWD/$prj_name-term_output.log 2>&1

# Parsing the target file
cat $pth/$targets | $GRAB_FQDN >$wrktmp/WebTargets
cat $pth/$targets | $GRAB_IPV4 > $wrktmp/TempTargets
cat $pth/$targets | grep -e "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}" >> $wrktmp/TempTargets
cat $pth/$targets | $IPv6 >> $wrktmp/TempTargetsv6
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq > $wrktmp/IPtargetsv6
echo

# Using sublist3r 
Banner "Performing Subdomain enum"
# consider replacing with  gobuster -m dns -o gobuster_output-$current_time.txt -u example.com -t 50 -w "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
# gobuster -m dns -cn -e -i -r -t 25 -w $WORDLIST -o "$wrkpth/PathEnum/$prj_name-gobuster_dns_output-$web.txt" -u example.com
if [ ! -z $wrktmp/WebTargets ]; then
    for web in $(cat $wrktmp/WebTargets); do
        sublist3r -d $web -v -t 25 -o "$wrkpth/SubDomainEnum/$prj_name-$web-sublist3r_output-$current_time.txt"
        amass enum -brute -w $WORDLIST -d $web -ip -o "$wrkpth/SubDomainEnum/$prj_name-$web-amass_output-$current_time.txt"
        gobuster dns -i -t 25 -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-gobuster_dns_output-$current_time.txt" -d $web
        shuffledns -d $web -w $WORDLIST -o "$wrkpth/SubDomainEnum/$prj_name-$web-shuffledns_output-$current_time.txt" -r /opt/Sherlock/rsc/ressolvers.txt -massdns `which massdns`
        fierce --domain $web --subdomain-file $WORDLIST --traverse 255 2> /dev/null | tee -a "$wrkpth/SubDomainEnum/$prj_name-$web-fierce_output-$current_time.json" 
    done
fi
echo

# Checking subdomains against subdomainizer
cat $wrktmp/WebTargets | httprobe | tee -a $wrkpth/SubDomainEnum/SubDomainizer_feed-$current_time
for i in `cat $wrkpth/SubDomainEnum/SubDomainizer_feed-$current_time`; do 
    timeout 1200 python3 /opt/SubDomainizer/SubDomainizer.py -u $i -k -o $wrkpth/SubDomainEnum/$prj_name-subdomainizer_output-$current_time.txt 2> /dev/null
done
echo

# Pulling out all the web targets
for i in `ls $wrkpth/SubDomainEnum/ | rg "$current_time"`; do
    if [ ! -z $wrkpth/SubDomainEnum/$i ]; then
        cat $wrkpth/SubDomainEnum/$i | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | tr -d ":" | tr -d "\'" | tr -d "[" | tr -d "]" | tr -d "{" | tr -d ":" | tr -d "}" | sort | uniq >> $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | $GRAB_IPV4 >> $wrktmp/TempTargets
        cat $wrkpth/SubDomainEnum/$i | $GRAB_FQDN >> $wrktmp/TempWeb
        cat $wrkpth/SubDomainEnum/$i | $IPv6 >> $wrktmp/TempTargetsv6
    fi
done
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
echo

# Using halberd
Banner "Performing scan using Halberd"
cat $wrktmp/WebTargets | parallel -j 10 -k "timeout 300 halberd {} -p 25 -t 90 -v | tee $wrkpth/Halberd/$prj_name-{}-halberd_output-$current_time.txt"
for web in $(ls $wrkpth/Halberd/); do
    if [ ! -z $wrkpth/Halberd/$i ]; then
        cat $wrkpth/Halberd/$i | $GRAB_IPV4 >> $wrktmp/TempTargets
    fi
done
echo

Banner "Some house cleaning"
# Some house cleaning
# PUT IN ADDITIONAL FILTERS FOR IPV4, V6, ETC.
cat $wrktmp/WebTargets | $GRAB_FQDN >> $wrktmp/TempWeb
cat $wrktmp/IPtargets | $GRAB_IPV4 >> $wrktmp/TempTargets
cat $wrktmp/IPtargetsv6 | $IPv6 >> $wrktmp/TempTargetsv6
cat $wrktmp/TempWeb | sort | uniq > $wrktmp/WebTargets
cat $wrktmp/TempTargets | sort | uniq > $wrktmp/IPtargets
cat $wrktmp/TempTargetsv6 | sort | uniq > $wrktmp/IPtargetsv6
cat $wrktmp/IPtargets $wrktmp/IPtargetsv6 $wrktmp/WebTargets | tr "<BR>" "\n" | tr " " "\n" | tr "," "\n" | rg -iv found | tr -d ":" | tr -d "\'" | tr -d "[" | tr -d "]" | sort | uniq | tee -a $wrktmp/tempFinal

# Nmap - Pingsweep using ICMP echo, netmask, timestamp
Banner "Nmap Pingsweep - ICMP echo, netmask, timestamp & TCP SYN, and UDP"
nmap -T5 --min-rate 300 -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PE -PM -PP -PO -PR -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time

# Nmap - IPv6 Pingsweep using TCP SYN, and UDP
Banner "Nmap - IPv6 Pingsweep using TCP SYN, and UDP"
nmap -6 -T5 --min-rate 300 -PA"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PS"21-23,25,53,80,88,110,111,135,139,443,445,3389,8080" -PU"42,53,67-68,88,111,123,135,137,138,161,500,3389,5355" -PY"22,80,179,5060" -R --reason --resolve-all -sn -iL $wrktmp/tempFinal -oA $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time


# Nmap - Grabing live hosts
Banner "Grabbing livehosts from pingsweep"
if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweep-$current_time.gnmap | rg Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live-$current_time
    cat $wrkpth/Nmap/live-$current_time | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponse-live-$current_time
fi

if [ -s $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap ] || [ -r $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap ]; then
    cat $wrkpth/Nmap/$prj_name-nmap_pingsweepv6-$current_time.gnmap | rg Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/livev6
    cat $wrkpth/Nmap/livev6 | sort | uniq > $wrkpth/Nmap/$prj_name-nmap_pingresponsev6-live-$current_time
fi
echo

# Combining targets
# PUT IN ADDITIONAL FILTERS FOR IPV4, V6, ETC.
Banner "Merging all targets files"
if [ -r $wrkpth/Masscan/live-$current_time ] || [ -r $wrkpth/Nmap/live-$current_time ] || [ -r $wrktmp/TempTargets ] || [ -r $wrktmp/WebTargets ]; then
    # cat $wrkpth/Masscan/live-$current_time | sort | uniq > $wrktmp/TempTargets
    cat $wrkpth/Nmap/live-$current_time | sort | uniq >> $wrktmp/TempTargets
    cat $wrktmp/tempFinal  >> $wrktmp/TempTargets
    cat $wrktmp/WebTargets $wrktmp/tempFinal $wrktmp/TempTargets | tr " " "\n" | tr "," "\n"  | sort | uniq >> $wrktmp/FinalTargets
    cat $wrktmp/TempTargets | $GRAB_IPV4 | sort | uniq | tee $wrktmp/IPtargets
    cat $wrktmp/IPtargetsv6 $wrktmp/TempTargetsv6 | $IPv6 >> $wrktmp/FinalTargets
fi
echo 

Banner "Printing final list of targets to be used"
cat $wrktmp/FinalTargets $wrktmp/IPtargets | tr " " "\n" | tr "," "\n" | sort | uniq
echo

# Using masscan to perform a quick port sweep
# Consider switcing to unicornscan
# unicornscan -i eth1 -Ir 160 -E 192.168.1.0/24:1-4000 gateway:a
Banner "Performing portknocking scan using Masscan"
# hostcount=$(wc -l $wrktmp/IPtargets | cut -d " " -f 4)
# nmapTimer=$(expr ((3*65535*$hostcount)/1000)*1.1)
# printf "This portion of the scan will take approx"
# convertAndPrintSeconds $nmapTimer
masscan -iL $wrktmp/IPtargets -p 0-65535 --rate 1000 --open-only --retries 3 -oL $wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list
if [ -r "$wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list" ] && [ -s "$wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list" ]; then
    cat $wrkpth/Masscan/$prj_name-masscan_portknock-$current_time.list | cut -d " " -f 4 | rg -v masscan | sort | uniq >> $wrkpth/$prj_name-livehosts-$current_time
fi
echo 

# Nmap - Full TCP SYN & UDP scan on live-$current_time targets
# time = (max-retries * ports * hosts) / min-rate
# -T4 has a max retry of 6
Banner "Performing portknocking scan using Nmap"
echo "Full TCP SYN & UDP scan on live-$current_time targets"
# hostcount=$(wc -l $wrktmp/FinalTargets | cut -d " " -f 4)
# nmapTimer=$(expr ((6*65535*$hostcount)/300)*1.1)
# printf "This portion of the scan will take approx"
# convertAndPrintSeconds $nmapTimer
nmap -T4 --min-rate 300p -P0 -R --reason --resolve-all -sSV --open -p- -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time
nmap -T5 --min-rate 300p --defeat-icmp-ratelimit -P0 -R --reason --resolve-all -sUV --open --top-ports 1000 -P0 -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time

# Scanning for IPv6
nmap -T4 --min-rate 300p -6 -P0 -R --reason --resolve-all -sSV --open -p- -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time
nmap -T5 --min-rate 300p --defeat-icmp-ratelimit -6 -P0 -R --reason --resolve-all -sUV --open --top-ports 1000 -P0 -iL $wrktmp/FinalTargets -oA $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time

# Enumerating the services discovered by nmap
if [ -r $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml ] || [ -r $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap ]; then
    for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time | rg Ports | cut -d "/" -f 5 | tr "|" "\n" | sort | uniq`; do # smtp domain telnet microsoft-ds netbios-ssn http ssh ssl ms-wbt-server imap; do
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap | rg $i | rg open | cut -d ' ' -f 2 | rg -iv nmap | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap | $GRAB_FQDN | cut -d " " -f 3 | cut -d "(" -f 2 | cut -d ")" -f 1 | rg -iv nmap | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $i | rg open | cut -d ' ' -f 2 | rg -iv nmap | $IPv6 | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`v6-$current_time
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | $GRAB_FQDN | cut -d " " -f 3 | cut -d "(" -f 2 | cut -d ")" -f 1 | rg -iv nmap | sort | uniq | tee -a $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`v6-$current_time
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
Banner "Performing scan using testssl"
python3 /opt/brutespray/brutespray.py --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap -U /usr/share/seclists/Usernames/cirt-default-usernames.txt -P /usr/share/seclists/Passwords/cirt-default-passwords.txt --threads 10 --hosts 10 -c --output $wrkpth/l00tz
echo

# Checking all the services discovery by nmap
for i in `cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_udpv6-$current_time $wrkpth/Nmap/$prj_name-nmap_portknock_udp-$current_time | rg Ports | cut -d "/" -f 5 | tr "|" "\n" | sort | uniq`; do
    Banner "Performing targeted scan of $i"
    PORTNUM=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i $i | cut -d "/" -f 1 | tr -d " " | sort | uniq))
    # hostcount=$(wc -l $wrktmp/`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time | cut -d " " -f 4)
    # nmapTimer=$(expr ((6*${#PORTNUM[@]}*$hostcount)/300)*2.5)
    # printf "This portion of the scan will take approx"
    # convertAndPrintSeconds $nmapTimer
    nmap -T4 --min-rate 300p -A -P0 -R --reason --resolve-all -sSUV --open -p "$(echo ${PORTNUM[*]} | tr  " " ",")" --script="$(ls /usr/share/nmap/scripts/ | rg $i | rg -iv brute | tr "\n" ",")$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`-$current_time -oA $wrkpth/Nmap/$prj_name-nmap_$i
    nmap -6 -T4 --min-rate 300p -A -P0 -R --reason --resolve-all -sSUV --open -p "$(echo ${PORTNUM[*]} | sed 's/ /,/g')" --script="$(ls /usr/share/nmap/scripts/ | rg $i | rg -iv brute | tr "\n" ",")$NMAP_SCRIPTS" --script-args "$NMAP_SCRIPTARG" -iL $wrkpth/Nmap/`echo $i | tr '[:lower:]' '[:upper:]'`v6-$current_time -oA $wrkpth/Nmap/$prj_name-nmapv6_$i
done
unset PORTNUM
echo

# Using batea
Banner "Ranking nmap output using batea"
for i in `ls $wrkpth/Nmap/ | rg -i xml | rg "$current_time"`; do
    batea -v $wrkpth/Nmap/$i | tee -a  $wrkpth/Batea/$prj_name-batea_output-$current_time.json 2> /dev/null
done
echo

# Using DNS Recon
# Will revise this later to account for other ports one might use for dns
Banner "Performing scan using DNS Scan"
if [ -s $wrkpth/Nmap/DOMAIN-$current_time ]; then
    for IP in $(cat $wrkpth/Nmap/DOMAIN-$current_time); do
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
if [ -s $wrkpth/Nmap/SSH-$current_time ]; then
    SSHPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i ssh | cut -d "/" -f 1 | tr -d " " | sort | uniq))
    for IP in $(cat $wrkpth/Nmap/SSH-$current_time); do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $IP | rg "Status: Up" -o | cut -c 9-10 | sort | uniq) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $IP | rg "$PORTNUM/open/tcp//ssh" -o | rg "ssh" -o | sort | uniq) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $IP | rg "$PORTNUM/filtered/tcp//ssh" -o | rg "ssh" -o | sort | uniq) # Check to see if the port is filtered & is a web service
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "ssh" ] || [ "$STAT3" == "ssh" ]; then
            for PORTNUM in ${SSHPort[*]}; do
                echo Scanning $IP
                echo "--------------------------------------------------"
                ssh-audit -n $IP -p  $PORTNUM | aha -t "SSH Audit" > $wrkpth/SSH/$prj_name-$IP:$PORTNUM-ssh-audit_output-$current_time.html
                echo "--------------------------------------------------"
                ssh_scan -t $IP -p $PORTNUM -o $wrkpth/SSH/$prj_name-$IP:$PORTNUM-ssh-scan_output-$current_time.json
                echo "--------------------------------------------------"
                msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS file:$wrkpth/Nmap/SSH; set RPORT $PORTNUM; set USER_FILE /usr/share/seclists/Usernames/cirt-default-usernames.txt; set THREADS 25; exploit; exit -y" 2> /dev/null | tee -a $wrkpth/SSH/$prj_name-ssh-msf-$web.txt
            done
        fi
    done
fi
echo

# Using Eyewitness to take screenshots
Banner "Performing scan using EyeWitness & aquafone"
if [ ! -z $wrkpth/Nmap/HTTP-$current_time ] || [ ! -z $wrkpth/Nmap/HTTPS-$current_time]; then 
    eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml --resolve --web --prepend-https --threads 25 --no-prompt -d $wrkpth/EyeWitness/
    if [ ! -z `$wrktmp/FinalTargets | $IPv6 ` ]; then
        eyewitness -x $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.xml --resolve --web --prepend-https --threads 25 --no-prompt -d $wrkpth/EyeWitnessv6/
    fi
    # Using aquafone
    cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.xml | aquatone -nmap -out $wrkpth/Aquatone/ -ports xlarge -threads 10
    if [ ! -z `$wrktmp/FinalTargets | $IPv6 ` ]; then
        cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.xml | aquatone -nmap -out $wrkpth/Aquatone/ -threads 10 # -ports xlarge
    fi
fi
echo 

# Using testssl & sslcan
# switch back to for loop, testssl doesnt properly parse gnmap
Banner "Performing scan using testssl"
cd $wrkpth/SSL/
testssl --append --assume-http --csv --full --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_output-$current_time.txt
testssl -6 --append --assume-http --csv --full --html --json-pretty --log --parallel --sneaky --file $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | tee -a $wrkpth/SSL/$prj_name-TestSSL_outputv6.txt
find $wrkpth/SSL/ -type f -size -1k -delete
cd $pth
echo

# Combining ports
# echo "--------------------------------------------------"
# echo "Combining ports
# echo "--------------------------------------------------"
# Merging HTTP and SSL ports
HTTPPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i http | cut -d "/" -f 1 | tr -d " " | sort | uniq))
SSLPort=($(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg Ports | cut -d ":" -f 3 | tr "," "\n" | rg -iv nmap | rg -i ssl | cut -d "/" -f 1 | tr -d " " | sort | uniq))
if [ -z ${#HTTPPort[@]} ] && [ -z ${#SSLPort[@]} ]; then
    echo "There are no open web or ssl ports, exiting now"
    gift_wrap
    exit
fi
NEW=$(echo "${HTTPPort[@]}" "${SSLPort[@]}" | awk '/^[0-9]/' | sort | uniq) # Will need testing
# Consider using the below script to parse for ports (https://github.com/superkojiman/scanreport)
# ./scanreport.sh -f XPC-2020Q1-nmap_portknock_tcp.gnmap -s http | rg -v Host | cut -d$'\t' -f 1 | sort | uniq

# Using theharvester & metagoofil
# look into the conditional
Banner "Performing scan using Theharvester and Metagoofil"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "Status: Up" -o | cut -c 9-10 | sort | uniq) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theHarvester -d http://$web:$PORTNUM -l 500 -b all | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_http_output-$current_time.txt
            timeout 900 metagoofil -d http://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_http_output-$current_time.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
         fi

        if [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            timeout 900 theHarvester -d https://$web:$PORTNUM -l 500 -b all | tee $wrkpth/Harvester/$prj_name-$web-$PORTNUM-harvester_https_output-$current_time.txt
            timeout 900 metagoofil -d https://$web:$PORTNUM -l 500 -o $wrkpth/Metagoofil/Evidence -f $wrkpth/Metagoofil/$prj_name-$web-$PORTNUM-metagoofil_https_output-$current_time.html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
            echo "--------------------------------------------------"
        fi
    done
done
if [ -d $wrkpth/Harvester/Evidence/ ]; then
    for files in $(ls $wrkpth/Harvester/Evidence/ | rg pdf); do
        pdfinfo $files.pdf | rg Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
    done
    cat $wrkpth/Harvester/tempusr | sort | uniq > $wrkpth/Harvester/Usernames
    rm $wrkpth/Harvester/tempusr
fi
echo

# Using Wappalyzer
Banner "Performing scan using Wappalyzer"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "Status: Up" -o | cut -c 9-10 | sort | uniq) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            if hash wappalyzer 2> /dev/null; then
                wappalyzer $web:$PORTNUM | jq | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json
            elif hash docker 2> /dev/null; then
                docker run --rm wappalyzer/cli $web:$PORTNUM | jq | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json
            fi
        elif [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
             if hash wappalyzer 2> /dev/null; then
                wappalyzer $web:$PORTNUM | jq | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json
            elif hash docker 2> /dev/null; then
                docker run --rm wappalyzer/cli $web:$PORTNUM | jq | tee -a $wrkpth/Wappalyzer/$prj_name-$web-wappalyzer_output-$current_time.json
            fi
        fi
    done
done
find $wrkpth/Wappalyzer/ -type f -size -1k -delete
echo

# Using XSStrike
Banner "Performing scan using XSStrike"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "Status: Up" -o | cut -c 9-10 | sort | uniq) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is filtered & ssl enabled
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "http" ] || [ "$STAT3" == "http" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u https://$web:$PORTNUM --crawl -t 10 -l 10 | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output-$current_time.txt
            echo "--------------------------------------------------"
        fi

        if [ "$STAT1" == "Up" ] && [ "$STAT4" == "ssl" ] && [ "$STAT5" == "ssl" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            python3 /opt/XSStrike/xsstrike.py -u http://$web:$PORTNUM --crawl -t 10 -l 10 | tee -a $wrkpth/XSStrike/$prj_name-$web-$PORTNUM-xsstrike_output-$current_time.txt
            echo "--------------------------------------------------"
        fi
    done
done
find $wrkpth/XSStrike/ -type f -size -1k -delete
echo

# Using nikto
Banner "Performing scan using Nikto"
nikto -C all -host $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output-$current_time.txt
if [ ! -z `$wrktmp/FinalTargets | $IPv6 ` ]; then
    nikto -C all -host $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap -output $wrkpth/Nikto/$prj_name-nikto_output.csv -Display 1,2,3,4,E,P -maxtime 90m | tee $wrkpth/Nikto/$prj_name-nikto_output-$current_time.txt
fi
echo

# Using gospider
Banner "Performing path traversal enumeration"
for web in $(cat $wrktmp/FinalTargets); do
    for PORTNUM in ${NEW[*]}; do
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "Status: Up" -o | cut -c 9-10 | sort | uniq) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//http" | rg "http" -o | sort | uniq) # Check to see if the port is filtered & is a web service
        STAT4=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is open & ssl enabled
        STAT5=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered/tcp//ssl" | rg "ssl" -o | sort | uniq) # Check to see if the port is filtered & ssl enabled
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
        STAT1=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "Status: Up" -m 1 -o | cut -c 9-10) # Check to make sure the host is in fact up
        STAT2=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/open" -m 1 -o | rg "open" -o) # Check to see if the port is open & is a web service
        STAT3=$(cat $wrkpth/Nmap/$prj_name-nmap_portknock_tcp-$current_time.gnmap $wrkpth/Nmap/$prj_name-nmap_portknock_tcpv6-$current_time.gnmap | rg $web | rg "$PORTNUM/filtered" -m 1 -o | rg "filtered" -o) # Check to see if the port is filtered & is a web service
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo Scanning $web:$PORTNUM
            echo "--------------------------------------------------"
            wapiti -u "http://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_http_result-$current_time -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            wapiti -u "https://$web:$PORTNUM/" -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_https_result-$current_time -f html -m "all" -v 1 2> /dev/null | tee -a $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-wapiti_result.log
            pythoon3 /opt/Arjun/arjun.py -u "https://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_https_output-$current_time.txt 2> /dev/null
            pythoon3 /opt/Arjun/arjun.py -u "http://$web:$PORTNUM/" --get --post -t 10 -f /opt/Arjun/db/params.txt -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-arjun_http_output-$current_time.txt 2> /dev/null
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w  $WORDLIST -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_https_output -c -u "https://$web:$PORTNUM/FUZZ"
            ffuf -r -recursion -recursion-depth 5 -ac -maxtime 600 -w  $WORDLIST -mc 200,401,403 -of all -o $wrkpth/WebVulnScan/$prj_name-$web-$PORTNUM-ffuf_http_output -c -u "http://$web:$PORTNUM/FUZZ"
            echo "--------------------------------------------------"
        fi
    done
done
echo

# WRapping up assessment
gift_wrap
} 2> /dev/null | tee -a $pth/$prj_name-sherlock_output-$current_time.txt