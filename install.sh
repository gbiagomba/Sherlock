# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, nmap, sn1pe, masscan, arachni, sslscan, testssl
if [ "halberd" != "$(ls /usr/local/bin/halberd)" ]; then
    # cd /opt/
    # git clone https://github.com/jmbr/halberd
    # cd halberd
    # python setup.py install
    pip install halberd
fi

if [ "dnsenum" != "$(ls /usr/bin/dnsenum)" ]; then
    apt install dnsenum -y
fi

if [ "sublist3r" != "$(ls /usr/bin/sublist3r)" ]; then
    apt install sublist3r -y
fi

if [ "theharvester" != "$(ls /usr/bin/theharvester)" ]; then
    apt install theharvester -y
fi

if [ "metagoofil" != "$(ls /usr/bin/metagoofil)" ]; then
    apt install metagoofil -y
fi

if [ "nikto" != "$(ls /usr/bin/nikto)" ]; then
    apt install nikto -y
fi

if [ "dirb" != "$(ls /usr/bin/dirb)" ]; then
    apt install dirb -y
fi

if [ "nmap" != "$(ls /usr/bin/nmap)" ]; then
    apt install nmap -y
fi

if [ "sniper" != "$(ls /usr/bin/sniper)" ]; then
    cd /opt/
    git clone https://github.com/1N3/Sn1per
    cd Sn1per
    bash install,sh
fi

if [ "masscan" != "$(ls /usr/bin/masscan)" ]; then
    apt install masscan -y
fi

if [ "html2text" != "$(ls /usr/bin/html2text)" ]; then
    apt install html2text -y
fi

if [ "arachni" != "$(ls /usr/bin/arachni)" ]; then
    apt install arachni -y
fi

if [ "sslscan" != "$(ls /usr/bin/sslscan)" ]; then
    apt install sslscan -y
fi

if [ "testssl" != "$(ls /usr/bin/testssl)" ]; then
    apt install testssl -y
fi

# Downloading the git project
cd /opt/
git pull https://github.com/gbiagomba/Sherlock
cd Sherlock

# Setting up symbolic link
ln sherlock.sh /usr/bin/sherlock