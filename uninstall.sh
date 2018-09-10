# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /opt/Sherlock -rf

# Removing dependencies
apt remove sublist3r theharvester metagoofil nikto dirb nmap sn1pe masscan arachni sslscan testssl
pip uninstall halberd