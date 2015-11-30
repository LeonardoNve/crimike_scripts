#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - IP needed"
    exit
fi

sslscan --xml=$1_ssl.xml $1 > $1_ssl.scan
/root/tools/ssl-cipher-suite-enum-v1.0.0/ssl-cipher-suite-enum.pl $1 > $1_ssl.enum
echo;echo;echo;echo "Ciphers that do not support Forward secrecy:";echo
cat $1_ssl.scan | grep Accept | egrep -v 'EDH|ECDHE|ECDH|AECDH|DHE'
echo;echo "Ciphers that support Forward Secrecy"
cat $1_ssl.scan | grep Accept | egrep 'EDH|ECDHE|ECDH|AECDH|DHE'
