#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - IP needed, and if basic auth, USER and PASS"
    exit
fi

if [ $# -eq 1 ]
then
    basicAuth=0
fi

if [ $# -eq 3 ]
then
    basicAuth=1
    user=$2
    pass=$3
    echo "[+]Using basic authentication with ${user}:${pass}"
fi
    
if [ $basicAuth -eq 0 ]
then
    echo "[+]Running nikto for $1"
    nikto -Cgidirs all -host $1 > $1.nikto
    echo "[+]Running hoppy for $1"
    /home/cristi/tools/hoppy/hoppy -h http://$1 > $1.hoppy
    echo "[+]Running dirb for $1"
    dirb http://$1 > $1.dirb
fi

if [ $basicAuth -eq 1 ]
then
    echo "[+]Running nikto for $1"
    nikto -Cgidirs all -host $1 -id ${user}:${pass} > $1.nikto
    echo "[+]Running hoppy for $1"
    /home/cristi/tools/hoppy/hoppy -h http://$1 -a ${user}:${pass} > $1.hoppy
    echo "[+]Running dirb for $1"
    dirb http://$1 -u ${user}:${pass} > $1.dirb
fi

