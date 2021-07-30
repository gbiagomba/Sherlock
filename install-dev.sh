#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per, 
#                         wapiti, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer
#                         sshscan, ssh-audit, dnsrecon, retirejs, python3, gobuster, seclists, metasploit
# set -eux
trap "echo Booh!" SIGINT SIGTERM

# Setting up variables
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

# Checking user is root & Ensuring system is debian based
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Setting sudo to HOME variable to target user's home dir
SUDOH="sudo -EH"

# Function banner
function banner
{
    echo "--------------------------------------------------"
    echo "Installing $1"
    echo "--------------------------------------------------"
}

# Figuring out installer
if ! hash apt 2> /dev/null; then
    PKG_MNGR_INSTALLER="apt install -y"
    PKG_MNGR_UPDATE="apt update"
    PKG_MNGR_UPGRADE="apt upgrade -y"
elif ! hash snap 2> /dev/null; then
    PKG_MNGR_INSTALLER="snap install"
    PKG_MNGR_UPDATE=$PKG_MNGR_UPGRADE
    PKG_MNGR_UPGRADE="snap refresh"
elif ! hash brew 2> /dev/null; then
    PKG_MNGR_INSTALLER="brew install"
    PKG_MNGR_UPDATE="brew update"
    PKG_MNGR_UPGRADE="brew upgrade"
elif ! hash pacman 2> /dev/null; then
    PKG_MNGR_INSTALLER="pacman install"
    PKG_MNGR_UPDATE=
    PKG_MNGR_UPGRADE=
elif ! hash emerge 2> /dev/null; then
    PKG_MNGR_INSTALLER="emerge install"
    PKG_MNGR_UPDATE=
    PKG_MNGR_UPGRADE=
elif ! hash dnf 2> /dev/null; then
    PKG_MNGR_INSTALLER="dnf install"
    PKG_MNGR_UPDATE=
    PKG_MNGR_UPGRADE=
elif ! hash zypper 2> /dev/null; then
    PKG_MNGR_INSTALLER="zypper install"
    PKG_MNGR_UPDATE=
    PKG_MNGR_UPGRADE=
fi

{
# Doing the basics
banner "system updates"
apt update
apt upgrade -y

# Installing main system dependencies
for i in aha amass chromium dirb dirbuster dnsrecon golang git git-core go jq masscan mediainfo medusa metagoofil msfconsole nikto nmap nodejs npm openssl pipenv parallel python2 python-pip python3 python3-pip ripgrep seclists sublist3r sudo testssl.sh theharvester unrar wapiti; do
    if ! hash $i 2> /dev/null; then
        banner $i
        $PKG_MNGR_INSTALLER $i
    fi
done

# Installing python dependencies
if ! hash theHarvester 2> /dev/null || ! hash ssh-audit 2> /dev/null; then
    banner "theHarvester, ssh-audit and fierce"
    $SUDOH pip3 install fierce ssh-audit theHarvester
fi

# Installing remaining dependencies
if ! hash testssl 2> /dev/null || ! hash testssl.sh 2> /dev/null; then
    banner "testssl.sh"
    cd /usr/bin/
    curl -s -o testssl https://testssl.sh/testssl.sh
    chmod +x testssl
fi

if [ ! -e /usr/share/seclists/ ]; then
    banner seclists
    cd /usr/share/; wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip; unzip SecList.zip; rm -f SecList.zip; mv SecLists-master/ seclists/
fi

if ! hash msfconsole 2> /dev/null; then
    banner msfconsole
    cd `mktemp -d`; curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
    systemctl enable postgresql
fi

if ! hash docker 2> /dev/null; then
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

if ! hash ssh_scan 2> /dev/null; then
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
    # Now Compiling NPM (Node Package Manager)
    cd ../npm
    make install
    #Testing our installation
    node –version
    npm -v
fi

# Installing wappalyzer
if ! hash wappalyzer 2> /dev/null; then
    banner "Wappalyzer"
    $SUDOH npm i wappalyzer -g
fi

if ! hash go; then
    banner golang
    add-apt-repository ppa:longsleep/golang-backports
    apt update
    apt install  -y golang golang-go
    $SUDOH export GOPATH=$(go env GOPATH)
    $SUDOH export PATH=$PATH:$(go env GOPATH)/bin
    $SUDOH echo "export PATH=$PATH:$(go env GOPATH)/bin" >> ~/.bashrc
    $SUDOH source ~/.bashrc

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

if ! hash nuclei; then
    banner nuclei
    $SUDOH go get -u -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
    git clone https://github.com/projectdiscovery/nuclei-templates.git /opt/nuclei-templates/
    if ! hash nuclei; then
        cd /opt/
        git clone https://github.com/projectdiscovery/nuclei.git; cd nuclei/v2/cmd/nuclei/; go build; mv nuclei /usr/bin/; nuclei -h
    fi
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
if [ ! -e /opt/Sublist3r ] && ! hash sublist3r 2> /dev/null; then
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

# Downloading and installing vulscan
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

# Downloading and installing brutespray
if [ ! -e /opt/brutesprays ]; then
    banner "brutespray"
    cd /opt/
    git clone https://github.com/x90skysn3k/brutespray
    cd brutespray/
    pip3 install -r requirements.txt
else
    cd /opt/brutespray/
    git pull
fi

# Downloading and installing janus
if [ ! -e /opt/OWASP-Janus ]; then
    banner "OWASP Janus"
    cd /opt/
    git clone https://github.com/gbiagomba/OWASP-Janus
    cd OWASP-Janus/
    ln -s /opt/OWASP-Janus/janus.sh /usr/bin/janus
else
    cd /opt/OWASP-Janus
    git pull
fi

# Downloading and installing xml2json
if [ ! -e /opt/xml2json ]; then
    banner xml2json
    cd /opt/
    git clone https://github.com/gbiagomba/xml2json
    cd xml2json/
    $SUDOH pip3 install -r requirements.txt
    # ln -s /opt/xml2json/xml2json.py /usr/bin/xml2json
else
    cd /opt/xml2json
    git pull
fi

# Downloading and installing medusa
if [ ! -e /opt/medusa-2.2 ] && ! hash medusa 2> /dev/null; then
    banner medusa
    wget -q http://foofus.net/goons/jmk/tools/medusa-2.2.tar.gz -O - | sudo tar -xvz
    cd medusa*
    ./configure
    make 
    make install
    medusa -q
fi

# Done
banner "WE ARE FINISHED!!!"
} 2> /dev/null | tee -a /opt/sherlock_install-$current_time.log