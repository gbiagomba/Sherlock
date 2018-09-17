# Removing the Sherlock project file and soft link
rm /usr/bin/sherlock
rm /opt/Sherlock -rf

# Removing the jhexboss dependency
rm /opt/jexboss/ -rf

# Removing the XssPy dependency
rm /opt/XssPy/ -rf

# Removing dependencies
apt remove halberd sublist3r theharvester metagoofil nikto dirb nmap sn1pe masscan arachni sslscan testssl jexboss grabber golismero -y
pip uninstall halberd