![alt tag](http://detective-tours.com/site/assets/files/1104/sherlock-banner.940x258.jpg)

# Sherlock - Web Inspector
Over the years I have had to do various web application and network pentests and I realized I was spending a lot of time performing the asset discovery, network vulnerability and web vulnerability scans. So I wrote this script to help handle that and I figuered I should share it with the world. Be advised, this tool was written for educational, and research purposes, please do not use this tool on systems you do not own.

## Pre-requisite
Though I am planning to make a version of this script that can run on other NIX/UNX systems, however for the time being this was written to run best on debian based systems.

## Install
There are two install scripts, the main one being `install.sh` this has been tested to work on debian based machines. I am working on a newer version currently dubbed `install-dev.sh` and this version is designed to allow you to install sherlock on virtually any NIX/UNX machine. Be advised, as the name implies it is in development and may not work completely. 
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
The uninstall script will NOT remove everything that was installed, the assumption I made is you want to keep all the tools and services for yourself. I will be updating the uninstall script later to allow a full uninstall for those who want everything added gone.
```
cd /opt/Sherlock/
./uninstall.sh
```

## TODO
- [ ] Add multi-thread parallel processing
- [ ] Limit amount of data stored to disk, use more variables
- [ ] Add Tenable API scanning/support [Queued]
- [ ] Add joomscan & droopescan scan [Queued]
- [ ] Add function to check if the script is running on latest version [inprogress]
- [ ] Add exclusion list config file
- [ ] Add flag support
- [ ] Convert sherlock to rust lang

## Outtro

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
