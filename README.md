![alt tag](http://detective-tours.com/site/assets/files/1104/sherlock-banner.940x258.jpg)

# Sherlock - Web Inspector
Over the years I have had to do various web application and network pentests and I realized I was spending a lot of time performing the asset discovery, network vulnerability and web vulnerability scans. So I wrote this script to help handle that and I figuered I should share it with the world. Be advised, this tool was written for educational, and research purposes, please do not use this tool on systems you do not own.

## Pre-requisite
Though I am planning to make a version of this script that can run on other NIX/UNX systems, however for the time being this was written to run best on debian based systems.

## Install
```
cd /opt/
git clone https://github.com/gbiagomba/Sherlock
cd Sherlock
./install.sh
```

## Usage
```
sherlock targetfile projectName
```
Do not worry, if you forget to supply a field, the prompt(s) will be asked as the tool runs.

## Uninstall
```
cd /opt/Sherlock/
./uninstall.sh
```

## TODO
- [x] Un-initialize variables
- [ ] Add multi-thread parallel processing
- [ ] Limit amount of data stored to disk, use more variables
- [x] Add SSL (e.g., sslyze, ssltest or testssl) checking later [done]
- [x] Add zipping of all content ~and sending it via some medium (e.g., email, ftp, etc)~ [done]
- [x] Write install script [done]
- [x] Add DNS recon [done]
- [x] Add SSH audit [done]
- [x] Add XSSTrike [done]
- [ ] Add FTP testing [inprogress]
- [ ] Add SMTP testing [inprogress]
- [ ] Add SMB testing [inprogress]
- [ ] Add RDP testing [inprogress]
- [ ] Add DB/SQL testing [inprogress]
- [ ] Add Tenable API scanning/support [Queued]
- [ ] Add joomscan [Queued]
- [ ] Add  docker run --rm asannou/droopescan scan [Queued]
- [ ] Add function to check if the script is running on latest version [inprogress]
- [x] Switch sublister with subfinder [https://github.com/projectdiscovery/subfinder]
- [ ] Switch grep with ripgrep [inprogress]
- [x] Add arjun [https://github.com/s0md3v/Arjun] [done]
- [ ] Add exclusion list config file

## Future Plans
I plan on converting this into a python script later down the road...just an FYI

```
           ."""-.
          /      \
          |  _..--'-.
          >.`__.-"";"`
         / /(     ^\    (
         '-`)     =|-.   )s
          /`--.'--'   \ .-.
        .'`-._ `.\    | J /
  jgs  /      `--.|   \__/
```
