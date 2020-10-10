function gift_wrap()
{
    # Cleaning empty files and zipping up all content
    Banner "Gift wrapping everything and putting a bowtie on it!"
    echo

    # Generating HTML, CSV and XLSX reports
    Banner "But first we need to make all those nmap results nice and purtty like"
    for i in `ls $wrkpth/Nmap/ | grep xml`; do
        xsltproc $wrkpth/Nmap/$i -o $wrkpth/Nmap/`echo $i | tr -d 'xml'`html /opt/nmap-bootstrap-xsl/nmap-bootstrap.xsl
        python3 /opt/nmaptocsv/nmaptocsv.py -x $wrkpth/Nmap/$i -S -d "," -n -o "$wrkpth/Nmap/$i.csv"
        python3 /opt/xml2json/xml2json.py $wrkpth/Nmap/$i | tee "$wrkpth/Nmap/$i.json"
    done
    python3 /opt/nmap-converter/nmap-converter.py -o "$wrkpth/Nmap/$prj_name-nmap_output.xlsx" $wrkpth/Nmap/*.xml
    echo

    # Combining testssl scans
    Banner "Next we are going to combine all the testssl csv files into one"
    # sed -i '$(head $wrkpth/SSL/*.csv | sort | uniq)' $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.csv | sort | uniq | tee -a $wrkpth/$prj_name-testssl_output.csv
    cat $wrkpth/SSL/*.json | tee -a $wrkpth/$prj_name-testssl_output-$current_time.json
    mv $wrkpth/$prj_name-testssl_output.* $wrkpth/SSL/
    echo

    # Combining nikto scans
    Banner "Now we are goingt o combine all the nikto csv files into one"
    cat $wrkpth/nikto/*.csv | sort | uniq | tee -a $wrkpth/$prj_name-nikto_output.csv
    mv $wrkpth/$prj_name-nikto_output.csv $wrkpth/Nikto/
    echo

    # Empty file cleanup
    Banner "Deleting empty files and directories"
    find $wrkpth -type d,f -empty | xargs rm -rf
    echo

    # Converting output to HTML
    Banner "Generating html report"
    cat $pth/$prj_name-sherlock_output-$current_time.txt | aha > $pth/$prj_name-sherlock_output-$current_time.html
    echo

    # Zipping the rest up
    Banner "Compressing the files"
    zip -ru9 $pth/$prj_name-sherlock_output-$current_time.zip $pth/$prj_name-sherlock_output-$current_time.txt $pth/$prj_name-sherlock_output-$current_time.html $wrkpth/
    echo

    # Removing unnessary files
    Banner "Removing files that are no longer needed"
    rm -rf $wrktmp/
    echo

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