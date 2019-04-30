#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per, arachni, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ ! -x /usr/local/bin/halberd ]; then
    pip install halberd
fi

if [ ! -x /usr/bin/sublist3r ]; then
    apt install sublist3r -y
fi

if [ ! -x /usr/bin/theharvester ]; then
    apt install theharvester -y
fi

if [ ! -x /usr/bin/metagoofil ]; then
    apt install metagoofil -y
fi

if [ ! -x /usr/bin/nikto) ]; then
    apt install nikto -y
fi

if [ ! -x /usr/bin/dirb ]; then
    apt install dirb -y
fi

if [ ! -x /usr/bin/nmap ]; then
    apt install nmap -y
fi

if [ ! -x /usr/bin/sniper ]; then
    cd /opt/
    git clone https://github.com/1N3/Sn1per
    cd Sn1per
    bash install.sh
fi

if [ ! -x /usr/bin/masscan ]; then
    apt install masscan -y
fi

if [ ! -x /usr/bin/html2text ]; then
    apt install html2text -y
fi

if [ ! -x /usr/bin/arachni ]; then
    apt install arachni -y
fi

if [ ! -x /usr/bin/sslscan ]; then
    apt install sslscan -y
fi

if [ ! -x /usr/bin/testssl ]; then
    apt install testssl -y
fi

if [ ! -x /usr/bin/grabber ]; then
    apt install grabber -y
fi

if [ ! -x /usr/bin/golismero ]; then
    apt install golismero -y
fi

if [ ! -x/usr/bin/docker ]; then
    apt install docker -y
fi

# Downloading the jexboss dependency
cd /opt/
git clone https://github.com/joaomatosf/jexboss
cd jexboss/
pip install -r requires.txt

# Downloading the XSStrike dependency
cd /opt/
git clone https://github.com/UltimateHackers/XSStrike
cd XSStrike/
pip3 install -r requirements.txt
cd /usr/bin/
ln -s /opt/XSStrike/xsstrike.py ./xsstrike

# Downloading the Sherlock git project
cd /opt/
git pull https://github.com/gbiagomba/Sherlock
cd Sherlock
ln -s sherlock.sh /usr/bin/sherlock

# Done
echo finished!