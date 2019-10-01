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
git pull https://github.com/gbiagomba/Sherlock
cd Sherlock
./install.sh
```

## Usage
```
sherlock targetfile
```
Do not worry all the prompts will be asked as the tool runs

## Uninstall
```
cd /opt/Sherlock/
./uninstall.sh
```

## TODO
- [ ] Un-initialize variables
- [ ] Add multi-thread parallel processing
- [ ] Limit amount of data stored to disk, use more variables
- [x] Add SSL (e.g., sslyze, ssltest or testssl) checking later [done]
- [x] Add zipping of all content ~and sending it via some medium (e.g., email, ftp, etc)~ [done]
- [x] Write install script [done]
- [x] Add DNS recon [done]
- [x] Add SSH audit [done]
- [x] Add XSSTrike [done]
- [ ] ~Add RetireJS~ [TBD]

## Future Plans
I plan on converting this into a python script later down the road...just an FYI

```
           ."""-.
          /      \
          |  _..--'-.
          >.`__.-"";"`
         / /(     ^\    (
         '-`)     =|-.   )
          /`--.'--'   \ .-.
        .'`-._ `.\    | J /
  jgs  /      `--.|   \__/
```
