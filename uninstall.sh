#!/usr/bin/env bash
# Removing dependencies

# Setting up variables
OS_CHK=$(cat /etc/os-release | grep -o debian)

# Checking user is root & Ensuring system is debian based
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
elif [ "$OS_CHK" != "debian" ]; then
    echo "Unfortunately this install script was written for debian based distributions only, sorry!"
    exit
fi

# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /usr/bin/gift_wrapper.sh
rm /opt/Sherlock -rf

# Done!
echo We are sorry to see you go, we hope to see you back soon!
echo "We only removed sherlock and not the dependencies - Just in case you wanted to keep using them"