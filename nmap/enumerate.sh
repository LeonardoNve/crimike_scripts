#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - File with IPs needed"
    exit
fi

echo "Running reverse host lookup on the IPs"
while read ip; do
    echo "Running host and traceroute for $ip"
    host $ip > ${ip}.info
    traceroute $ip >> ${ip}.info
    ping -R -c 1 192.168.2.96 | sed '1,/RR/d' | awk '/statistics/ {exit} {print}' >> ${ip}.info
done<$1

echo "Running simple TCP scan and enum4linux on the list given"
while read ip; do
    echo "Simple TCP Scanning on: $ip"
    sudo nmap -Pn -v -A -oA ${ip}_simple_tcp $ip > /dev/null
    OsName = $(cat ${ip}_simple_tcp | grep "OS details")
    echo "\tCheck ${ip}_simple_tcp.nmap for port 80 - dirb and webdav"
    echo "\tCheck ${ip}_simple_tcp.nmap for port 443 - sslscan"
    echo $OsName >> ${ip}.info
    echo "\tCheck ${ip}.info for OS"
    if [[ $OsName == *"Windows"* ]]
    then
        echo "Enum4linux on: $ip"
        sudo enum4linux $ip > ${ip}.enum
    fi
done<$1

echo "Running basic udp scan on the ip list"
while read ip; do
    echo "Simple UDP Scan on: $ip"
    sudo nmap -Pn -v -A -sU --top-ports 200 -oA ${ip}_simple_udp $ip > /dev/null
    echo "udp-proto-scanner on: $ip"
    sudo udp-proto-scanner.pl $ip > ${ip}_proto.udp
    echo "\tCheck ${ip}_proto.udp for SNMP - onesixtyone"
    echo "\tCheck ${ip}_proto.udp for DNS - dig @${ip} name axfr"
done<$1

echo "Running full TCP scan on list"
while read ip; do
    echo "Full TCP scan on: $ip"
    sudo nmap -Pn -v -A -p- -oA ${ip}_full_tcp $ip > /dev/null
done<$1

echo "Running Default UDP scan on list"
while read ip; do
    echo "Default UDP scan on: $ip"
    sudo nmap -Pn -v -A -sU -oA ${ip}_full_tcp $ip > /dev/null
done<$1
