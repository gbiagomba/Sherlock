#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per, 
#                         wapiti, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer
#                         sshscan, ssh-audit, dnsrecon, retirejs, python3, gobuster, seclists, metasploit
# set -eux
trap "echo Booh!" SIGINT SIGTERM


# Setting up variables
OS_CHK=$(cat /etc/os-release | grep -o debian)

# Checking user is root & Ensuring system is debian based
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ "$OS_CHK" != "debian" ]; then
    echo "Unfortunately this install script was written for debian based distributions only, sorry!"
    exit
fi

# Setting sudo to HOME variable to target user's home dir
SUDOH="sudo -H"

# Function banner
function banner
{
    echo "--------------------------------------------------"
    echo "Installing $1"
    echo "--------------------------------------------------"
}

{
# Doing the basics
apt update
apt upgrade -y

# Installing main system dependencies
for i in amass chromium dnsrecon golang go masscan metagoofil msfconsole nikto nmap pipenv python2 python-pip python3 python3-pip ripgrep seclists sublist3r sudo testssl.sh theharvester wapiti; do
    if ! hash $i; then
        banner $i
        apt install -y $i
    fi
done

# Installing python dependencies
banner "theHarvester & ssh-audit"
$SUDOH pip3 install theHarvester ssh-audit

# Installing remaining dependencies
if ! hash testssl || ! hash testssl.sh; then
    banner "testssl.sh"
    cd /usr/bin/
    curl -s -o testssl https://testssl.sh/testssl.sh
    chmod +x testssl
fi

if [ ! -e /usr/share/seclists/ ]; then
    banner seclists
    cd /usr/share/; wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip; unzip SecList.zip; rm -f SecList.zip; mv SecLists-master/ seclists/
fi

if ! hash msfconsole; then
    banner msfconsole
    cd `mktemp -d`; curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
    systemctl enable postgresql
fi

if ! hash docker; then
    banner docker
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
    apt-get remove  docker docker-engine docker.io containerd runc -y
    # Install Docker:
    apt-get install docker-ce docker-ce-cli containerd.io -y
fi

if ! hash ssh_scan; then
    banner ssh_scan
    $SUDOH gem install ssh_scan
fi

if ! hash node && ! hash npm; then
    banner "node & npm"
    # Based on the article https://relutiondev.wordpress.com/2016/01/09/installing-nodejs-and-npm-kaliubuntu/
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
    #Testing our installation
    node –version
    npm -v
fi

if ! hash go; then
    banner golang
    add-apt-repository ppa:longsleep/golang-backports
    apt update
    apt install  -y golang golang-go
    $SUDOH export GOPATH=$(go env GOPATH)
    $SUDOH export PATH=$PATH:$(go env GOPATH)/bin
    echo "PATH=$PATH:$(go env GOPATH)/bin" >> ~/.bash
fi

if ! hash amass; then
    banner amass
    $SUDOH go get -v github.com/OWASP/Amass
fi

if ! hash httprobe; then
    banner httprobe
    $SUDOH go get -u -v github.com/tomnomnom/httprobe
fi

if ! hash gospider; then
    banner gospider
    $SUDOH go get -u -v github.com/jaeles-project/gospider
fi

if ! hash hakrawler; then
    banner hakrawler
    $SUDOH go get -u -v github.com/hakluke/hakrawler
fi

if ! hash ffuf; then
    banner ffuf
    $SUDOH go get -u -v github.com/ffuf/ffuf
fi

if ! hash shuffledns; then
    banner shuffledns
    $SUDOH go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
fi

if ! hash massdns; then
    banner massdns
    git clone https://github.com/blechschmidt/massdns.git
    cd massdns
    $SUDOH make
fi

if ! hash aquatone; then
    banner aquatone
    $SUDOH go get -u -v github.com/michenriksen/aquatone
fi

if ! hash gobuster; then
    banner gobuster
    $SUDOH go get -u -v github.com/OJ/gobuster
fi

# Downloading the XSStrike dependency
if [ ! -e /opt/XSStrike ]; then
    banner XSStrike
    cd /opt/
    git clone https://github.com/s0md3v/XSStrike
    cd XSStrike/
    $SUDOH pip3 install -r requirements.txt
    cd /usr/bin/
    ln -s /opt/XSStrike/xsstrike.py ./xsstrike
else
    cd /opt/XSStrike
    git pull
fi

# Downloading the ssh-audit
if ! hash /usr/bin/ssh-audit; then
    banner ssh-audit
    cd /opt/
    git clone https://github.com/jtesta/ssh-audit
    cd /usr/bin/
    ln -s /opt/ssh-audit/ssh-audit.py ./ssh-audit
else
    cd /opt/ssh-audit
    git pull
fi
# Downloading the Vulners Nmap Script
if [ ! -e /opt/nmap-vulners ]; then
    banner "nmap script vulners"
    cd /opt/
    git clone https://github.com/vulnersCom/nmap-vulners
    cp /opt/vulnersCom/nmap-vulners/vulners.nse /usr/share/nmap/scripts
else
    cd /opt/nmap-vulners
    git pull
fi

# Downloading & installing nmap-converter
if [ ! -e /opt/nmap-converter ]; then
    banner msfconsole
    cd /opt/
    git clone https://github.com/mrschyte/nmap-converter
    cd nmap-converter
    $SUDOH pip3 install -r requirements.txt
else
    cd /opt/nmap-converter
    git pull
fi

# Downloading & installing SubDomainizer
if [ ! -e /opt/SubDomainizer ]; then
    banner SubDomainizer
    cd /opt/
    git clone https://github.com/nsonaniya2010/SubDomainizer.git
    cd SubDomainizer
    $SUDOH pip3 install -r requirements.txt
else
    cd /opt/SubDomainizer
    git pull
fi

# Downloading & installing batea
if [ ! -e /opt/batea ]; then
    banner batea
    cd /opt/
    git clone https://github.com/delvelabs/batea
    cd batea/
    $SUDOH python3 setup.py sdist
    $SUDOH pip3 install -r requirements.txt
    $SUDOH pip3 install ! -e .
else
    cd /opt/batea
    git pull
fi

# Downloading & installing nmap-bootstrap-xsl
if [ ! -e /opt/nmap-bootstrap-xsl ]; then
    banner "nmap HTML report template"
    cd /opt/
    git clone https://github.com/honze-net/nmap-bootstrap-xsl.git
else
    cd /opt/nmap-bootstrap-xsl
    git pull
fi

# Downloading & installing SubDomainizer
if [ ! -e /opt/Sherlock ]; then
    banner sherlock
    ln -s /opt/Sherlock/sherlock.sh /usr/bin/sherlock
    ln -s /opt/Sherlock/gift_wrapper.sh /usr/bin/gift_wrapper.sh
else
    cd /opt/Sherlock
    git pull
fi

# Downloading & installing Arjun
if [ ! -e /opt/Arjun ]; then
    banner Arjun
    cd /opt/
    git clone https://github.com/s0md3v/Arjun
else
    cd /opt/Arjun
    git pull
fi

# Installing main dependencies
if [ ! -e /opt/Sublist3r ]; then
    banner Sublist3r
    cd /opt/
    git clone https://github.com/aboul3la/Sublist3r
    cd Sublist3r/
    $SUDOH pip3 install -r requirements.txt
    $SUDOH python3 setup.py install
    ln -s /opt/Sublist3r/sublist3r.py /usr/bin//sublist3r
else
    cd /opt/Sublist3r
    git pull
fi

# Downloading and installing metagofil
if [ ! -e /opt/metagoofil ]; then
    banner metagofil
    cd /opt/
    git clone https://github.com/laramies/metagoofil
    cd metagoofil/
    $SUDOH pip3 install -r requirements.txt
    $SUDOH python3 setup.py install
    ln -s /opt/metagoofil/metagoofil.py /usr/bin//metagoofil
else
    cd /opt/metagoofil
    git pull
fi

# Downloading and installing metagofil
if [ ! -e /opt/vulscan ]; then
    banner vulscan
    cd /opt/
    git clone https://github.com/scipag/vulscan
    cd vulscan/
    ln -s /opt/vulscan/ /usr/share/nmap/scripts/vulscan 
else
    cd /opt/vulscan
    git pull
fi

# Done
echo finished!
} 2> /dev/null | tee -a /opt/sherlock_install.log