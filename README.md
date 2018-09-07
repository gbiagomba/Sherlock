# Sherlock - Web Inspector
I wrote this script because over the years I have had to do various web application aseessments and one of the most time consuming part is performing the discovery, network vulnerability and web vulnerability scans. Though this does not do all that, however it takes care of the basics for me/you. 

## Install
cd /opt/
git pull https://github.com/gbiagomba/Sherlock
cd Sherlock

## Usage
./WebInspector

Do not worry all the prompts will be asked as the tool runs

## TODO
1. Un-initialize variables
2. Add multi-thread parallel processing
3. Move all subroutines into functions
4. Limit amount of data stored to disk, use more variables
5. Add SSL (e.g., sslyze, ssltest or testssl) checking later [done]
6. Add zipping of all content and sending it via some medium (e.g., email, ftp, etc)
7. Write install script

## Future Plans
I plan on converting this into a python script later down the road...just an FYI