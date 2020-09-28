![alt tag](http://detective-tours.com/site/assets/files/1104/sherlock-banner.940x258.jpg)
```
     _               _            _    
    | |             | |          | |   
 ___| |__   ___ _ __| | ___   ___| | __
/ __| '_ \ / _ \ '__| |/ _ \ / __| |/ /
\__ \ | | |  __/ |  | | (_) | (__|   < 
|___/_| |_|\___|_|  |_|\___/ \___|_|\_\
```

# Sherlock - Web Inspector
I wrote this script because over the years I have had to do various web application aseessments and one of the most time consuming part is performing the discovery, network vulnerability and web vulnerability scans. Though this does not do all that, however it takes care of the basics for you and I. 

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
Do not worry all the prompts will be asked as the tool runs

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
- [ ] Switch grep with ripgrep
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
