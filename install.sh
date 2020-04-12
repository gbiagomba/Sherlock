#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per, 
#                         arachni, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer
#                         sshscan, ssh-audit, dnsrecon, retirejs, python3, gobuster, seclists

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

# if [ ! -x /usr/local/bin/halberd ]; then
#     pip install halberd
# fi

if [ ! -x /usr/bin/sublist3r ]; then
    apt install sublist3r -y
fi

if [ ! -x /usr/bin/theharvester ]; then
    apt install theharvester -y
fi

if [ ! -x /usr/bin/metagoofil ]; then
    apt install metagoofil -y
fi

if [ ! -x /usr/bin/nikto ]; then
    apt install nikto -y
fi

if [ ! -x /usr/bin/nmap ]; then
    apt install nmap -y
fi

if [ ! -x /usr/bin/dnsrecon ]; then
    apt install dnsrecon -y
fi

if [ ! -x /usr/bin/python3 ] && [ ! -x /usr/bin/python2 ]; then
    apt install python3 python2 -y
fi

if [ ! -x /usr/bin/masscan ]; then
    apt install masscan -y
fi

if [ ! -x /usr/bin/arachni ]; then
    apt install arachni -y
fi

if [ ! -x /usr/bin/testssl ]; then
    apt install testssl -y
fi

# if [ ! -x /usr/bin/golismero ]; then
#     apt install golismero -y
# fi

# if [ ! -x /usr/bin/gobuster ]; then
#     apt install gobuster -y
# fi

if [ ! -d /usr/share/seclists ] && [ ! -x /usr/bin/seclists ]; then
    apt install seclists -y
fi

if [ ! -x/usr/bin/docker ]; then
    # Based on these two articles
    # https://medium.com/@airman604/installing-docker-in-kali-linux-2017-1-fbaa4d1447fe
    # https://docs.docker.com/install/linux/docker-ce/debian/

    # Add Docker PGP key:
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

    # Configure Docker APT repository (Kali is based on Debian testing, which will be called buster upon release, and Docker now has support for it):
    echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' > /etc/apt/sources.list.d/docker.list

    # Update APT:
    apt-get update

    # Uninstall older docker
    apt-get remove docker docker-engine docker.io -y

    # Install Docker:
    apt-get install docker-ce docker-ce-cli containerd.io -y
fi

# Downloading mozilla's sshscan
if [ ! -x /usr/bin/ssh_scan ]; then
    gem install ssh_scan
fi

# Downloading and installing npm & nodejs
if [ ! -x /usr/local/bin/node ] && [ ! -x /usr/local/bin/npm ]; then
    # Based on the article https://relutiondev.wordpress.com/2016/01/09/installing-nodejs-and-npm-kaliubuntu/

    # Warning message to user
    echo "Use this script if the npm_install does not work"
    read answer #fix later

    # Make our directory to keep it all in
    src=$(mktemp -d) && cd $src

    # Add the location to our path so that we can call it with bash
    echo ‘export PATH=$HOME/local/bin:$PATH’ >> ~/.bashrc

    # Now we can start with downloading NodeJs and NPM
    git clone git://github.com/nodejs/node.git
    git clone git://github.com/npm/npm.git

    # Compiling NodeJS
    cd node
    bash configure –-prefix=~/local
    make install
    cd ../

    # Now Compiling NPM (Node Package Manager)
    cd npm
    make install
    cd ../

    #Testing our installation
    node –version
    npm -v
fi

# installing retirejs
if [ ! -x /usr/local/bin/retire]; then
    npm install -g retire
fi

# Downloading the XSStrike dependency
cd /opt/
git clone https://github.com/s0md3v/XSStrike
cd XSStrike/
pip3 install -r requirements.txt
cd /usr/bin/
ln -s /opt/XSStrike/xsstrike.py ./xsstrike

# Downloading the ssh-audit
cd /opt/
git pull https://github.com/jtesta/ssh-audit
cd /usr/bin/
ln -s /opt/ssh-audit/ssh-audit.py ./ssh-audit
if [ ! -x `which ssh-audit`]; then
    pip3 install ssh-audit
fi

# Downloading the SpiderLabs Nmap Script
# cd /opt/
# git pull https://github.com/SpiderLabs/Nmap-Tools
# cp /opt/SpiderLabs/Nmap-Tools/NSE/http-screenshot.nse /usr/share/nmap/scripts/

# Downloading the Vulners Nmap Script
cd /opt/
git clone https://github.com/vulnersCom/nmap-vulners
cp /opt/vulnersCom/nmap-vulners/vulners.nse /usr/share/nmap/scripts

# Downloading the Sherlock git project
cd /usr/bin/
ln -s /opt/Sherlock/sherlock.sh ./sherlock

# Done
echo finished!