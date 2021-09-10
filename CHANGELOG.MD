# v1.19.3
* Added more banners in install script

# v1.19.2
* Changed gospider and dirbpy to load in the target file (its more efficient this way)
* Fixed dirbpy execution, it was a typo which explains why it never ran
* Moved path enum to execute after wappalyzerm this is helpful for feeding the next round fo tools
* Updated install script to reflect the new tools added

# v1.19.1
* added additional tools to install script (e.g., sqlmap, dalfox, uro)
* added sqlmap, goverview and dalfox to sherlock
* fixed some logic errors as well

# v1.18.0
* Added nuclei
* Streamlined code by generating URL tags into a file as opposed to going through nmap results and checking to see if each target had a web server
* Updated install script
* Removed some legacy code

# v1.18.1
* Made changes to the SSH securitty checks
