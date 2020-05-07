#!/usr/bin/env bash
# Removing dependencies

# Setting up variables
OS_CHK=$(cat /etc/os-release | grep -o debian)

# Checking user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Ensuring system is debian based
if [ "$OS_CHK" != "debian" ]; then
    echo "Unfortunately this install script was written for debian based distributions only, sorry!"
    exit
fi

# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /opt/Sherlock -rf

# Removing the XSStrike dependency
pip3 uninstall -r /opt/XSStrike/requirements.txt
rm /opt/XSStrike/ -rf
rm /usr/bin/xsstrike

# Removing nmap-converter
rm -rf /opt/nmap-converter

# Removing installing nmaptocsv
rm -rf /opt/maptocsv

# Removing the Vulners Nmap Script dependency
rm /opt/vulnersCom/nmap-vulners -rf
rm /usr/share/nmap/scripts/nmap-vulners/vulners.nse

# Removing ssh-audit dependency
rm -rf /opt/ssh-audit/
rm -rf /usr/bin//ssh-audit
if [ ! -x `which ssh-audit`]; then
    pip3 uninstall ssh-audit
fi

# Removing the XSStrike dependency
pip3 uninstall -r /opt/XSStrike/requirements.txt
rm -rf /opt/XSStrike/
rm /usr/bin/xsstrike

# Downloading & installing nmap-converter
pip3 uninstall -r /opt/nmap-converter/requirements.txt
rm -rf /opt/nmap-converter

# Downloading & installing nmaptocsv
pip3 uninstall -r /opt/nmap-converter/requirements.txt
rm -rf /opt/nmap-converter

# Removing npm, nodejs, and retirejs dependency
npm uninstall retire -g

# Removing the SpiderLabs Nmap Script dependency
rm -rf /opt/nmap-vulners
rm -rf /usr/share/nmap/scripts/vulners.nse

# Removing mozilla's ssh_scan dependcy
gem uninstall ssh_scan

# Removing remaining dependencies
apt remove halberd sublist3r theharvester metagoofil nikto nmap dnsrecon masscan arachni testssl seclists docker-ce docker-ce-cli containerd.io nodejs -y
pip uninstall halberd

# Done!
echo We are sorry to see you go, we hope to see you back soon!
echo "We DID NOT delete python2/3, and npm/node - Just in case you needed them"