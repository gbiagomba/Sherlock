function gift_wrap()
{
    # Cleaning empty files and zipping up all content
    Banner "Gift wrapping everything and putting a bowtie on it!"
    echo

    # Generating HTML, CSV and XLSX reports from nmap
    # Consider using the below script to parse for ports (https://github.com/superkojiman/scanreport)
    # ./scanreport.sh -f XPC-2020Q1-nmap_portknock_tcp.gnmap -s http | rg -v Host | cut -d$'\t' -f 1 | sort -u
    Banner "But first we need to make all those nmap results nice and purtty like"
    for i in `ls $wrkpth/Nmap/ | grep xml`; do
        xsltproc $wrkpth/Nmap/$i -o $wrkpth/Nmap/`echo $i | cut -d "." -f 1`.html /opt/nmap-bootstrap-xsl/nmap-bootstrap.xsl
        python3 /opt/nmaptocsv/nmaptocsv.py -x $wrkpth/Nmap/$i -S -d "," -n -o "$wrkpth/Nmap/`echo $i | cut -d "." -f 1`.csv"
        python3 /opt/xml2json/xml2json.py $wrkpth/Nmap/$i | tee "$wrkpth/Nmap/`echo $i | cut -d "." -f 1`.json"
        searchsploit --nmap $wrkpth/Nmap/$i | tee -a "$wrkpth/$prj_name-searchsploit_output-$current_time.txt"
    done
    python3 /opt/nmap-converter/nmap-converter.py -o "$wrkpth/Nmap/$prj_name-nmap_output-$current_time.xlsx" $wrkpth/Nmap/*.xml
    echo

    # Feeding nmap output to NVD
    Banner "Next we are going to feed nmp cpe data to the NVD"
    for i in `cat $wrkpth/Nmap/*.nmap | rg "cpe:" | tr " " "\n" | sort -u`; do echo "Checking $i"; curl -kLs https://services.nvd.nist.gov/rest/json/cpes/1.0?cpeMatchString=$i| jq; echo; done | tee -a "$wrkpth/$prj_name-nmap-nvd-cpe_output-$current_time.json"
    echo

    # Combining testssl scans
    Banner "Next we are going to combine all the testssl csv files into one"
    # sed -i '$(head $wrkpth/SSL/*.csv | sort -u)' $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.csv | sort -u | tee -a $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.json | tee -a $wrkpth/$prj_name-testssl_output-$current_time.json
    cat $wrkpth/Nmap/*.csv | sort -u | tee -a $wrkpth/$prj_name-nmap_output.csv
    mv $wrkpth/$prj_name-testssl_output.* $wrkpth/SSL/
    echo

    # Combining nikto scans
    Banner "Now we are goingt o combine all the nikto csv files into one"
    cat $wrkpth/nikto/*.csv | sort -u | tee -a $wrkpth/$prj_name-nikto_output.csv
    mv $wrkpth/$prj_name-nikto_output.csv $wrkpth/Nikto/
    echo

    # Empty file cleanup
    Banner "Deleting empty files and directories"
    find $wrkpth -type d,f -empty | xargs rm -rf
    echo

    # Converting output to HTML
    Banner "Generating html report"
    cat $wrkpth/$prj_name-sherlock_output-$current_time.txt | aha > $wrkpth/$prj_name-sherlock_output-$current_time.html
    echo

    # Zipping the rest up
    Banner "Compressing the files"
    zip -ru9 $pth/$prj_name-sherlock_output-$current_time.zip $wrkpth/$prj_name-sherlock_output-$current_time.txt $wrkpth/$prj_name-sherlock_output-$current_time.html $wrkpth/
    echo

    # Removing unnessary files
    Banner "Removing files that are no longer needed"
    rm -rf $wrktmp/
    echo

    # Uninitializing variables
    for var in API_AK API_SK current_time GRAB_FQDN GRAB_IPV4 GRAB_IPV4CIDR HTTPPort i IP IPV6 NEW NMAP_SCRIPTS NMAP_SCRIPTARG PORTNUM OS_CHK prj_name pth SSHPort SSLPort SSLCHECK STAT1 STAT2 STAT3 STAT4 STAT5 targets TodaysDAY TodaysYEAR web wrkpth wrktmp WORDLIST; do
        unset $var
    done
    unset var

    # Goodbye Message
    echo "
    ___________________________¶¶¶
    _______________________¶¶¶¶¶¶¶¶¶¶¶¶
    ______________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ____________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    __________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ___________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    __________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶___¶¶¶
    ____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ___________¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    __________¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _________¶¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _________¶¶¶____¶¶¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ¶¶¶¶¶¶¶__¶¶______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _¶¶¶¶¶__¶¶_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _¶¶¶¶¶__¶¶______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    __¶¶¶¶¶¶¶_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ___¶¶¶¶¶_________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    _________________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ________________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
    ______________________¶¶¶¶¶¶¶¶¶¶¶¶¶
    _____________________¶¶¶¶¶¶¶¶¶¶¶
    ____________________¶¶¶¶¶¶¶¶¶¶
    ____________________¶¶¶¶¶¶¶¶
    ___________________¶¶¶¶¶
    If you eliminate all other possibilities, the one that remains, however unlikely, is the right answer."
}
