#!/usr/bin/env bash
# Removing dependencies

# Checking UAC
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /opt/Sherlock -rf
rm /usr/bin/sherlock

# Removing the jexboss dependency
pip uninstall -r /opt/jexboss/requires.txt
rm /opt/jexboss/ -rf

# Removing the XSStrike dependency
pip3 uninstall -r /opt/XSStrike/requirements.txt
rm /opt/XSStrike/ -rf
rm /usr/bin/xsstrike


# Removing remaining dependencies
apt remove halberd sublist3r theharvester metagoofil nikto dirb nmap sn1pe masscan arachni sslscan testssl jexboss grabber golismero docker -y
pip uninstall halberd

# Done!
echo We are sorry to see you go, we hope to see you back soon!