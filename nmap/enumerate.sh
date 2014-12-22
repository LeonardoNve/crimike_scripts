#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - File with IPs needed"
    exit
fi

echo "Running simple TCP scan and enum4linux on the list given"
while read ip; do
    echo "Simple TCP Scanning on: $ip"
    sudo nmap -Pn -v -A -oA ${ip}_simple_tcp $ip > /dev/null
    echo "Enum4linux on: $ip"
    sudo enum4linux $ip > ${ip}.enum
done<$1

echo "Running basic udp scan on the ip list"
while read ip; do
    echo "Simple UDP Scan on: $ip"
    sudo nmap -Pn -v -A -sU --top-ports 200 -oA ${ip}_simple_udp $ip > /dev/null
    echo "udp-proto-scanner on: $ip"
    sudo udp-proto-scanner $ip > ${ip}_proto.udp
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
