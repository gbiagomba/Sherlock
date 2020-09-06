#!`which env bash
# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, masscan, nmap, sn1per, 
#                         wapiti, sslscan, testssl, jexboss, xsstrike, grabber, golismero, docker, wappalyzer
#                         sshscan, ssh-audit, dnsrecon, retirejs, python3, gobuster, seclists, metasploit

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

# Doing the basics
apt update
apt upgrade -y

# Installing main system dependencies
for i in amass chromium dnsrecon golang go masscan metagoofil nikto nmap python2 python3 ripgrep seclists sublist3r testssl theharvester wapiti; do
    if [ ! -x $i ] || [ -z `which $i` ]; then
        apt install -y $i
    fi
done

# Installing python dependencies
$SUDOH pip3 install theHarvester ssh-audit

# Installing remaining dependencies
if [ ! -x `which testssl` ] || [ ! -x `which testssl.sh` ]; then
    cd /usr/bin/
    curl -s https://testssl.sh/testssl.sh
    mv testssl.sh testssl
    chmod +x testssl
fi

if [ ! -e /usr/share/seclists/ ]; then
    cd /usr/share/; wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip; unzip SecList.zip; rm -f SecList.zip; mv SecLists-master/ seclists/
fi

if [ ! -x `which msfconsole` ]; then
    cd `mktemp -d`; curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
    systemctl enable postgresql
fi

if [ ! -x `which docker` ]; then
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

if [ ! -x `which ssh_scan` ]; then
    $SUDOH gem install ssh_scan
fi

if [ ! -x `which node` ] && [ ! -x `which npm` ]; then
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

if [ ! -x `which go` ]; then
    add-apt-repository ppa:longsleep/golang-backports
    apt update
    apt install golang golang-go -y
    $SUDOH export GOPATH=$(go env GOPATH)
    $SUDOH export PATH=$PATH:$(go env GOPATH)/bin
fi

if [ ! -x `which amass` ]; then
    $SUDOH go get -v github.com/OWASP/Amass
fi

if [ ! -x `which httprobe` ]; then
    $SUDOH go get -u -v github.com/tomnomnom/httprobe
fi

if [ ! -x `which gospider` ]; then
    $SUDOH go get -u -v github.com/jaeles-project/gospider
fi

if [ ! -x `which hakrawler` ]; then
    $SUDOH go get -u -v github.com/hakluke/hakrawler
fi

if [ ! -x `which ffuf` ]; then
    $SUDOH go get github.com/ffuf/ffuf
fi

if [ ! -x `which massdns` ]; then
    git clone https://github.com/blechschmidt/massdns.git
    cd massdns
    $SUDOH make
fi

if [ ! -x `which shuffledns` ]; then
    $SUDOH go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
fi

if [ ! -x `which aquatone` ]; then
    $SUDOH go get -u -v github.com/michenriksen/aquatone
fi

if [ ! -x `which gobuster` ]; then
    $SUDOH go get -u -v github.com/OJ/gobuster
fi

# Downloading the XSStrike dependency
if [ ! -e /opt/XSStrike ]; then
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
if [ ! -e /opt/ssh-audit ]; then
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
    cd /opt/
    git clone https://github.com/vulnersCom/nmap-vulners
    cp /opt/vulnersCom/nmap-vulners/vulners.nse /usr/share/nmap/scripts
else
    cd /opt/nmap-vulners
    git pull
fi

# Downloading & installing nmap-converter
if [ ! -e /opt/nmap-converter ]; then
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
    cd /opt/
    git clone https://github.com/honze-net/nmap-bootstrap-xsl.git
else
    cd /opt/nmap-bootstrap-xsl
    git pull
fi

# Downloading & installing SubDomainizer
if [ ! -e /opt/Sherlock ]; then
    ln -s /opt/Sherlock/sherlock.sh /usr/bin/sherlock
    ln -s /opt/Sherlock/gift_wrapper.sh /usr/bin/gift_wrapper.sh
else
    cd /opt/Sherlock
    git pull
fi

# Downloading & installing Arjun
if [ ! -e /opt/Sherlock ]; then
    cd /opt/
    git clone https://github.com/s0md3v/Arjun
else
    cd /opt/Arjun
    git pull
fi

# Installing main dependencies
if [ ! -e /opt/Sublist3r ]; then
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

# Done
echo finished!