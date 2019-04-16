#!/usr/bin/env bash
# Removing dependencies

# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /opt/Sherlock -rf

# Removing the jexboss dependency
pip uninstall -r /opt/jexboss/requires.txt
rm /opt/jexboss/ -rf

# Removing the XSStrike dependency
pip3 uninstall -r /opt/XSStrike/requirements.txt
rm /opt/XSStrike/ -rf

# Removing remaining dependencies
apt remove halberd sublist3r theharvester metagoofil nikto dirb nmap sn1pe masscan arachni sslscan testssl jexboss grabber golismero docker -y
pip uninstall halberd

# Done!
echo We are sorry to see you go, we hope to see you back soon!