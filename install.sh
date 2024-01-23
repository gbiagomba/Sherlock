#!/usr/bin/env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per,
#                         wapiti, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer
#                         sshscan, ssh-audit, dnsrecon, retirejs, python3, gobuster, seclists, metasploit
# set -eux
trap "echo Booh!" SIGINT SIGTERM

# Setting up variables
# OS_CHK=$(cat /etc/os-release | grep -o debian)
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
wrkpth="$PWD"

# Checking user is root
if [ "$EUID" -ne 0 ]; then
  SUDOH="sudo -EH"
fi

# Checking the operating system & setting bin
if [ $(uname -o) -eq "Darwin" ]; then
  BIN_INSTALL="$HOME/.sherlock/bin/"
  mkdir -p $BIN_INSTALL/
else; then
  BIN_INSTALL="$/opt/"
fi

# Figuring out the default package monitor
if hash apt 2> /dev/null; then
  PAKMAN_INSTALL="$SUDOH apt install -y"
  PAKMAN_UPDATE="$SUDOH apt update"
  PAKMAN_UPGRADE="$SUDOH apt upgrade -y"
  PAKMAN_RM="$SUDOH apt remove -y"
elif hash yum; then
  PAKMAN_INSTALL="$SUDOH yum install -y --skip-broken"
  PAKMAN_UPDATE="$SUDOH yum update -y --skip-broken"
  PAKMAN_UPGRADE="$SUDOH yum upgrade -y --skip-broken"
  PAKMAN_RM="$SUDOH yum remove -y"
elif hash snap 2> /dev/null; then
  PAKMAN_INSTALL="$SUDOH snap install"
  PAKMAN_UPGRADE="$SUDOH snap refresh"
  PAKMAN_UPDATE=$PAKMAN_UPGRADE
  PAKMAN_RM="$SUDOH snap remove"
elif hash brew 2> /dev/null; then
  PAKMAN_INSTALL="brew install"
  PAKMAN_UPDATE="brew update"
  PAKMAN_UPGRADE="brew upgrade"
  PAKMAN_RM="brew uninstall"
fi

# Function banner
function banner
{
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

{
# Doing the basics
banner "system updates"
$PAKMAN_UPDATE
$PAKMAN_UPGRADE

# Installing main system dependencies
for i in aha amass arjun batea brutespray chromium dirb dirbuster dnsrecon exploitdb git git-core go golang golang-go janus jq masscan mediainfo medusa metagofil metagoofil msfconsole nikto nmap nmap-bootstrap-xsl nmap-converter nodejs nuclei openssl parallel pipenv python-pip python2 python3 python3-pip ripgrep searchsploit seclists ssh-audit subdomainizer sublist3r testssl testssl.sh theharvester unrar vulscan wapiti xml2json xss-payload-list xsstrike; do
    if ! hash $i 2> /dev/null; then
        banner "Installing $i"
        $PAKMAN_INSTALL $i
    fi
done

# Installing python dependencies
for i in dnsrecon fierce dirbpy ssh-audit theHarvester uro; do
    if ! hash $i 2> /dev/null; then
        banner "Installing python package $i"
        pip3 install --user $i
    fi
done

# Installing remaining dependencies
if ! hash testssl 2> /dev/null || ! hash testssl.sh 2> /dev/null; then
    banner "testssl.sh"
    cd /usr/bin/
    curl -s -o testssl https://testssl.sh/testssl.sh
    chmod +x testssl
    ln -s testssl testssl.sh
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
    $PAKMAN_UPDATE
    # Uninstall older docker
    $PAKMAN_RM docker docker-engine docker.io containerd runc
    # Install Docker:
    $PAKMAN_INSTALL docker-ce docker-ce-cli containerd.io
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
    $PAKMAN_UPDATE
    $PAKMAN_INSTALL golang golang-go
    export GOPATH=$(go env GOPATH)
    export PATH=$PATH:$(go env GOPATH)/bin
    echo "export PATH=$PATH:$(go env GOPATH)/bin" >> ~/.bashrc
    source ~/.bashrc
fi

if ! hash amass; then
    banner amass
    go install -v github.com/OWASP/Amass@latest
fi

if ! hash httprobe; then
    banner httprobe
    go install -v github.com/tomnomnom/httprobe@latest
fi

if ! hash gospider; then
    banner gospider
    go install -v github.com/jaeles-project/gospider@latest
fi

if ! hash hakrawler; then
    banner hakrawler
    go install -v github.com/hakluke/hakrawler@latest
fi

if ! hash ffuf; then
    banner ffuf
    go install -v github.com/ffuf/ffuf@latest
fi

if ! hash shuffledns; then
    banner shuffledns
    go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
fi

if ! hash dalfox; then
    banner dalfox
    go install -v github.com/detectify/page-fetch@latest
    if ! hash dalfox; then sudo snap install dalfox; fi
fi

if ! hash page-fetch; then
    banner page-fetch
    go install -v github.com/hahwul/dalfox/v2@latest
    if ! hash page-fetch; then sudo `git clone https://github.com/detectify/page-fetch.git $BIN_INSTALL/page-fetch/ && cd $BIN_INSTALL/page-fetch/ && go install -v`; fi
fi

if ! hash massdns && [ ! -e $BIN_INSTALL/massdns ]; then
    banner massdns
    cd $BIN_INSTALL/
    git clone https://github.com/blechschmidt/massdns.git
    cd massdns
    $SUDOH make
fi

if ! hash aquatone; then
    banner aquatone
    go install -v github.com/michenriksen/aquatone@latest
fi

if ! hash gobuster; then
    banner gobuster
    go install -v github.com/OJ/gobuster@latest
fi

if ! hash goverview; then
    banner goverview
    go install -v github.com/j3ssie/goverview@latest
fi

if ! hash nuclei; then
    banner nuclei
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    git clone https://github.com/projectdiscovery/nuclei-templates.git $BIN_INSTALL/nuclei-templates/
    if ! hash nuclei; then
        cd $BIN_INSTALL/
        git clone https://github.com/projectdiscovery/nuclei.git; cd nuclei/v2/cmd/nuclei/; go build; mv nuclei /usr/bin/; nuclei -h
    fi
fi

if ! hash urinteresting; then
    banner urinteresting
    go install -v github.com/tomnomnom/hacks/urinteresting@latest
fi

# Downloading the XSStrike dependency
if [ ! -e $BIN_INSTALL/XSStrike ]; then
    banner XSStrike
    cd $BIN_INSTALL/
    git clone https://github.com/s0md3v/XSStrike
    cd XSStrike/
    $SUDOH pip3 install -r requirements.txt
    ln -s $BIN_INSTALL/XSStrike/xsstrike.py /usr/bin/xsstrike
else
    banner XSStrike
    cd $BIN_INSTALL/XSStrike
    git pull
fi

# Downloading the ssh-audit
if ! hash /usr/bin/ssh-audit; then
    banner ssh-audit
    cd $BIN_INSTALL/
    git clone https://github.com/jtesta/ssh-audit
    cd /usr/bin/
    ln -s $BIN_INSTALL/ssh-audit/ssh-audit.py ./ssh-audit
else
    banner ssh-audit
    cd $BIN_INSTALL/ssh-audit
    git pull
fi

# Downloading the Vulners Nmap Script
if [ ! -e $BIN_INSTALL/nmap-vulners ]; then
    banner "nmap script vulners"
    cd $BIN_INSTALL/
    git clone https://github.com/vulnersCom/nmap-vulners
    cp $BIN_INSTALL/vulnersCom/nmap-vulners/vulners.nse /usr/share/nmap/scripts
else
    banner "nmap script vulners"
    cd $BIN_INSTALL/nmap-vulners
    git pull
fi

# Downloading & installing nmap-converter
if [ ! -e $BIN_INSTALL/nmap-converter ]; then
    banner msfconsole
    cd $BIN_INSTALL/
    git clone https://github.com/mrschyte/nmap-converter
    cd nmap-converter
    $SUDOH pip3 install -r requirements.txt
else
    banner msfconsole
    cd $BIN_INSTALL/nmap-converter
    git pull
fi

# Downloading & installing SubDomainizer
if [ ! -e $BIN_INSTALL/SubDomainizer ]; then
    banner SubDomainizer
    cd $BIN_INSTALL/
    git clone https://github.com/nsonaniya2010/SubDomainizer.git
    cd SubDomainizer
    $SUDOH pip3 install -r requirements.txt
else
    banner SubDomainizer
    cd $BIN_INSTALL/SubDomainizer
    git pull
fi

# Downloading & installing batea
if [ ! -e $BIN_INSTALL/batea ]; then
    banner batea
    cd $BIN_INSTALL/
    git clone https://github.com/delvelabs/batea
    cd batea/
    python3 setup.py sdist
    pip3 install -r requirements.txt
    pip3 install -e .
    python3 -m venv batea/
    source batea/bin/activate
    pip3 install -r requirements-dev.txt
    pip3 install -e .
    pytest
else
    banner batea
    cd $BIN_INSTALL/batea
    git pull
fi

# Download and install favfreak
if [ ! -e $BIN_INSTALL/FavFreak ]; then
    banner favfreak
    git clone https://github.com/devanshbatham/FavFreak
    cd FavFreak
    virtualenv -p python3 env
    source env/bin/activate
    python3 -m pip install mmh3
    ln -s $BIN_INSTALL/FavFreak/favfreak.py /usr/bin/favfreak
else
    banner favfreak
    cd $BIN_INSTALL/FavFreak
    git pull
fi

# Downloading & installing nmap-bootstrap-xsl
if [ ! -e $BIN_INSTALL/nmap-bootstrap-xsl ]; then
    banner "nmap HTML report template"
    cd $BIN_INSTALL/
    git clone https://github.com/honze-net/nmap-bootstrap-xsl.git
else
    banner "nmap HTML report template"
    cd $BIN_INSTALL/nmap-bootstrap-xsl
    git pull
fi

# Linking sherlock
if [ -x sherlock ]; then
    banner sherlock
    ln -s $BIN_INSTALL/Sherlock/sherlock.sh /usr/bin/sherlock
    ln -s $BIN_INSTALL/Sherlock/gift_wrapper.sh /usr/bin/gift_wrapper.sh
else
    cd $BIN_INSTALL/Sherlock
    git pull
fi

# Downloading & installing Arjun
if [ ! -e $BIN_INSTALL/Arjun ]; then
    banner Arjun
    cd $BIN_INSTALL/
    git clone https://github.com/s0md3v/Arjun
else
    banner Arjun
    cd $BIN_INSTALL/Arjun
    git pull
fi

# Installing main dependencies
if [ ! -e $BIN_INSTALL/Sublist3r ] && ! hash sublist3r 2> /dev/null; then
    banner Sublist3r
    pip3 install --user git+https://github.com/aboul3la/Sublist3r
    ln -s $BIN_INSTALL/Sublist3r/sublist3r.py /usr/bin//sublist3r
else
    banner Sublist3r
    cd $BIN_INSTALL/Sublist3r
    git pull
fi

# Downloading and installing metagofil
if [ ! -e $BIN_INSTALL/metagoofil ]; then
    banner metagoofil
    pip3 install --user git+https://github.com/laramies/metagoofil
    ln -s $BIN_INSTALL/metagoofil/metagoofil.py /usr/bin//metagoofil
else
    banner metagoofil
    cd $BIN_INSTALL/metagoofil
    git pull
fi

# Downloading and installing vulscan
if [ ! -e $BIN_INSTALL/vulscan ]; then
    banner vulscan
    cd $BIN_INSTALL/
    git clone https://github.com/scipag/vulscan
    cd vulscan/
    ln -s $BIN_INSTALL/vulscan/ /usr/share/nmap/scripts/vulscan
else
    banner vulscan
    cd $BIN_INSTALL/vulscan
    git pull
fi

# Downloading and installing brutespray
if ! hash brutespray 2> /dev/null; then
    banner "brutespray"
    cd $BIN_INSTALL/
    git clone https://github.com/x90skysn3k/brutespray
    cd brutespray/
    pip3 install -r requirements.txt
    ln -s $BIN_INSTALL/brutespray/brutespray.py /usr/bin/brutespray
else
    banner "brutespray"
    cd $BIN_INSTALL/brutespray/
    git pull
fi

# Downloading and installing janus
if [ ! -e $BIN_INSTALL/OWASP-Janus ]; then
    banner "OWASP Janus"
    cd $BIN_INSTALL/
    git clone https://github.com/gbiagomba/OWASP-Janus
    cd OWASP-Janus/
    ln -s $BIN_INSTALL/OWASP-Janus/janus.sh /usr/bin/janus
else
    banner "OWASP Janus"
    cd $BIN_INSTALL/OWASP-Janus
    git pull
fi

# Downloading and installing xml2json
if [ ! -e $BIN_INSTALL/xml2json ]; then
    banner xml2json
    cd $BIN_INSTALL/
    git clone https://github.com/gbiagomba/xml2json
    cd xml2json/
    $SUDOH pip3 install -r requirements.txt
    # ln -s $BIN_INSTALL/xml2json/xml2json.py /usr/bin/xml2json
else
    banner xml2json
    cd $BIN_INSTALL/xml2json
    git pull
fi

# Downloading and installing medusa
if [ ! -e $BIN_INSTALL/medusa-2.2 ] && ! hash medusa 2> /dev/null; then
    banner medusa
    wget -q http://foofus.net/goons/jmk/tools/medusa-2.2.tar.gz -O - | sudo tar -xvz
    cd medusa*
    ./configure
    make
    make install
    medusa -q
fi

# Downloading and installing theHarvester
if [ ! -e $BIN_INSTALL/theHarvester] && ! hash theHarvester 2> /dev/null; then
    banner theHarvester
    git clone https://github.com/laramies/theHarvester.git
    cd $BIN_INSTALL/theHarvester
    pip3 install -r requirements/base.txt
    ln -s $BIN_INSTALL/theHarvester/theHarvester.py /usr/bin/theharvester
else
    banner theHarvester
    cd $BIN_INSTALL/theHarvester
    git pull
fi

# Downloading and installing searchsploit
if [ ! -e $BIN_INSTALL/exploit-database ] && ! hash searchsploit 2> /dev/null; then
    banner searchsploit
    git clone https://github.com/offensive-security/exploit-database.git
    cd $BIN_INSTALL/exploit-database/
    ln -s $BIN_INSTALL/exploit-database/searchsploit /usr/bin/searchsploit
else
    banner searchsploit
    searchsploit -u
    cd $BIN_INSTALL/exploit-database/
    git pull
fi

# Downloading and installing xss-payload-list
if [ ! -e $BIN_INSTALL/xss-payload-list ]; then
    banner xss-payload-list
    git clone https://github.com/payloadbox/xss-payload-list
else
    banner xss-payload-list
    cd $BIN_INSTALL/xss-payload-list/
    git pull
fi

# Done
banner "WE ARE FINISHED!!!"
} 2> /dev/null | tee -a $PWD/sherlock_install-$current_time.log
