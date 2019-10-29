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

# Removing the SpiderLabs Nmap Script dependency
rm /opt/SpiderLabs/Nmap-Tools -rf
rm /usr/share/nmap/scripts/http-screenshot.nse

# Removing the Vulners Nmap Script dependency
rm /opt/vulnersCom/nmap-vulners -rf
rm /usr/share/nmap/scripts/nmap-vulners/vulners.nse

# Removing ssh-audit dependency
rm -rf /opt/ssh-audit

# Removing the sshscan dependency
rm -rf /opt/SSHScan/

# Removing npm, nodejs, and retirejs dependency
npm uninstall retire -g
npm uninstall npm -g

# Removing the SpiderLabs Nmap Script dependency
rm -rf /opt/nmap-vulners
rm -rf /usr/share/nmap/scripts/vulners.nse

# Removing remaining dependencies
apt remove halberd sublist3r theharvester metagoofil nikto nmap dnsrecon python3 masscan arachni sslscan testssl golismero gobuster docker-ce docker-ce-cli containerd.io nodejs -y
pip uninstall halberd

# Done!
echo We are sorry to see you go, we hope to see you back soon!