#!/usr/bin/env bash
# Author: Gilles Biagomba
# Program: Sherlock.sh
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specficailly recon).\n

# for debugging purposes
# set -eux
trap "echo Booh!" SIGINT SIGTERM

function gift_wrap()
{
    # Cleaning empty files and zipping up all content
    Banner "Gift wrapping everything and putting a bowtie on it!"

    # Generating HTML, CSV and XLSX reports
    Banner "But first we need to make all those nmap results nice and purtty like"
    for i in `ls $wrkpth/Nmap/ | grep xml`; do
        xsltproc $wrkpth/Nmap/$i -o $wrkpth/Nmap/`echo $i | tr -d 'xml'`html /opt/nmap-bootstrap-xsl/nmap-bootstrap.xsl
        python3 /opt/nmaptocsv/nmaptocsv.py -x $wrkpth/Nmap/$i -S -d "," -n -o "$wrkpth/Nmap/`$i | tr -d 'xml'`csv"
        python3 /opt/xml2json/xml2json.py $wrkpth/Nmap/$i | tee "$wrkpth/Nmap/`$i | tr -d 'xml'`json"
    done
    python3 /opt/nmap-converter/nmap-converter.py -o "$wrkpth/Nmap/$prj_name-nmap_output.xlsx" $wrkpth/Nmap/*.xml

    # Combining testssl scans
    Banner "Next we are going to combine all the testssl csv into one spreadsheet"
    # sed -i '$(head $wrkpth/SSL/*.csv | sort | uniq)' $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.csv | sort | uniq | tee -a $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.json | tee -a $wrkpth/$prj_name-testssl_output.json
    mv $wrkpth/$prj_name-testssl_output.* $wrkpth/SSL/

    # Empty file cleanup
    find $wrkpth -type d,f -empty | xargs rm -rf

    # Converting output to HTML
    cat $pth/$prj_name-sherlock_output-$current_time.txt | aha > $pth/$prj_name-$current_time-sherlock_output-$current_time.html

    # Zipping the rest up
    zip -ru9 $pth/$prj_name-sherlock_output-$current_time.zip $pth/$prj_name-$current_time-sherlock_output.txt $pth/$prj_name-$current_time-sherlock_output.html

    # Removing unnessary files
    rm -rf $wrktmp/

    # Uninitializing variables
    for var in API_AK API_SK HTTPPort i IP NEW NMAP_SCRIPTS NMAP_SCRIPTARG PORTNUM OS_CHK prj_name pth SSHPort SSLPort SSLCHECK STAT1 STAT2 STAT3 STAT4 STAT5 targets TodaysDAY TodaysYEAR web wrkpth wrktmp WORDLIST; do
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