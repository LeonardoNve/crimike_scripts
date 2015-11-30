#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - IP needed, and if basic auth, USER and PASS"
    exit
fi

port=80

if [ $# -eq 1 ]
then
    basicAuth=0
fi

if [ $# -eq 2 ]
then
    basicAuth=0
    port=$2
fi

if [ $# -eq 3 ]
then
    basicAuth=1
    user=$2
    pass=$3
    echo "[+]Using basic authentication with ${user}:${pass}"
fi


if [ $# -eq 4 ]
then
    basicAuth=1
    user=$3
    pass=$4
    port=$2
    echo "[+]Using basic authentication with ${user}:${pass}"
fi
    
if [ $basicAuth -eq 0 ]
then
    echo "[+]Running nikto for $1"
    nikto -Cgidirs all -port $port -host $1 | tee ${1}_${port}.nikto
    echo "[+]Running hoppy for $1"
    /root/tools/hoppy/hoppy -p $port -h http://$1 | tee ${1}_${port}.hoppy
    echo "[+]Running dirb for $1"
    dirb http://${1}:${port} | tee ${1}_${port}.dirb
fi

if [ $basicAuth -eq 1 ]
then
    echo "[+]Running nikto for $1"
    nikto -Cgidirs all -port $port -host $1 -id ${user}:${pass} | tee ${1}_${port}.nikto
    echo "[+]Running hoppy for $1"
    /root/tools/hoppy/hoppy -p $port -h http://$1 -a ${user}:${pass} | tee ${1}_${port}.hoppy
    echo "[+]Running dirb for $1"
    dirb http://${1}:${port} -u ${user}:${pass} | tee ${1}_${port}.dirb
fi

