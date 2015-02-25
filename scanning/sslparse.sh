#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - IP needed"
    exit
fi

sslscan --xml=$1_ssl.xml $1 > $1_ssl.scan
/home/cristi/tools/ssl-cipher-suite-enum-v1.0.0/ssl-cipher-suite-enum.pl $1 > $1_ssl.enum
