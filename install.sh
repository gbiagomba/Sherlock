#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, nmap, sn1pe, masscan, arachni, sslscan, testssl, jexboss
if [ "halberd" != "$(ls /usr/local/bin/halberd)" ]; then
    # cd /opt/
    # git clone https://github.com/jmbr/halberd
    # cd halberd
    # python setup.py install
    pip install halberd
fi

if [ "dnsenum" != "$(ls /usr/bin/ | grep dnsenum)" ]; then
    apt install dnsenum -y
fi

if [ "sublist3r" != "$(ls /usr/bin/ | grep sublist3r)" ]; then
    apt install sublist3r -y
fi

if [ "theharvester" != "$(ls /usr/bin/ | grep theharvester)" ]; then
    apt install theharvester -y
fi

if [ "metagoofil" != "$(ls /usr/bin/ | grep metagoofil)" ]; then
    apt install metagoofil -y
fi

if [ "nikto" != "$(ls /usr/bin/ | grep nikto)" ]; then
    apt install nikto -y
fi

if [ "dirb" != "$(ls /usr/bin/ | grep dirb)" ]; then
    apt install dirb -y
fi

if [ "nmap" != "$(ls /usr/bin/ | grep nmap)" ]; then
    apt install nmap -y
fi

if [ "sniper" != "$(ls /usr/bin/ | grep sniper)" ]; then
    cd /opt/
    git clone https://github.com/1N3/Sn1per
    cd Sn1per
    bash install,sh
fi

if [ "masscan" != "$(ls /usr/bin/ | grep masscan)" ]; then
    apt install masscan -y
fi

if [ "html2text" != "$(ls /usr/bin/ | grep html2text)" ]; then
    apt install html2text -y
fi

if [ "arachni" != "$(ls /usr/bin/ | grep arachni)" ]; then
    apt install arachni -y
fi

if [ "sslscan" != "$(ls /usr/bin/ | grep sslscan)" ]; then
    apt install sslscan -y
fi

if [ "testssl" != "$(ls /usr/bin/ | grep testssl)" ]; then
    apt install testssl -y
fi

if [ "grabber" != "$(ls /usr/bin/ | grep grabber)" ]; then
    apt install grabber -y
fi

if [ "golismero" != "$(ls /usr/bin/ | grep golismero)" ]; then
    apt install golismero -y
fi

# Downloading the jhexboss dependency
cd /opt/
git clone https://github.com/joaomatosf/jexboss.git
cd jexboss/
pip install -r requires.txt

# Downloading the XssPy dependency
cd /opt/
git clone https://github.com/faizann24/XssPy

# Downloading the git project
cd /opt/
git pull https://github.com/gbiagomba/Sherlock
cd Sherlock

# Setting up symbolic link
ln sherlock.sh /usr/bin/ | grep sherlock