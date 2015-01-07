#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - File with IPs needed"
    exit
fi

if [ $# -ge 2 ]
then
    echo -e "***NOTE: Any argument past '$1' is not taken into consideration......just so you know\n\n"
fi

while read ip; do
    echo -n "Running host and traceroute for $ip ........."
    echo -e "======Host======" >${ip}.info
    sudo host $ip >> ${ip}.info
    echo -e "\n\n======Traceroute======" >> ${ip}.info
    sudo traceroute $ip >> ${ip}.info
    echo -e "\n\n======Ping with record route======" >> ${ip}.info
    sudo ping -R -c 1 $ip | sed '1,/RR/d' | awk '/statistics/ {exit} {print}' >> ${ip}.info
    echo "Done"
done<$1

echo "Running simple TCP scan on the list given"
while read ip; do
    echo -n "Simple TCP Scanning on: $ip ......"
    sudo nmap -v -Pn -v -A -oA "${ip}_simple_tcp" $ip > /dev/null
    echo "Done"
    OsName=$(cat ${ip}_simple_tcp.nmap | grep "OS details")
    echo -e "\n\n==========Operating System==========" >> ${ip}.info
    echo $OsName >> ${ip}.info
    http=$(cat ${ip}_simple_tcp.nmap | grep "80/tcp")
    if [[ $http == *"80"* ]]
    then
        echo -n "Running dirb for $ip ........"
        echo -e "\n\n============Dirb===========" >> $ip.info
        dirb http://$ip >> $ip.info
        echo "Done"
    fi
    dns=$(cat ${ip}_simple_tcp.nmap | grep "53/tcp")
    if [[ $dns == *"53"* ]]
    then
        echo -n "Running dns zone transfer for $ip ......."
        dig @$ip axfr > $ip.dns
        echo "Done"
    fi
    ssh=$(cat ${ip}_simple_tcp.nmap | grep "22/tcp")
    if [[ $ssh == *"22"* ]]
    then
        echo -n "Grabbing SSH Banner from $ip ......."
        echo -e "\n\n===========SSH===========" >> $ip.info
        sudo nmap -p 22 -sV $ip | grep "22/tcp" >> $ip.info
        sudo expect -c "spawn ssh -o StrictHostKeyChecking=no qwerty@$ip;expect \"qwerty@@ip's password:\"; send \"a\r\"" >> $ip.info
        echo "Done"
    fi
    nfs=$(cat ${ip}_simple_tcp.nmap | grep "2049/tcp")
    if [[ $nfs == *"2049"* ]]
    then
        echo -n "Getting exported file systems from NFS server on $ip ......."
        echo -e "\n\n============NFS===========" >> $ip.info
        sudo showmount -e $ip >> $ip.info
        echo "Done"
    fi
    if [[ $OsName == *"Windows"* ]]
    then
        echo -n "Enum4linux on: $ip ........"
        sudo enum4linux $ip > ${ip}.enum
        echo "Done"
        echo -n "Trying RPC NULL Login to $ip ........"
        echo -e "\n\n========RPC NULL Session==========" >> ${ip}.info
        sudo rpcclient -U "" -N -c "getusername;exit" $ip >> ${ip}.info
        echo "Done"
    fi
done<$1

echo "Running basic udp scan on the ip list"
while read ip; do
    echo -n "Simple UDP Scan on: $ip ......."
    sudo nmap -v -Pn -v -A -sU --top-ports 100 -oA "${ip}_simple_udp" $ip > /dev/null
    echo "Done"
    snmp=$(cat ${ip}_simple_udp.nmap | grep "161/udp")
    if [[ $snmp == *"161/udp"* ]]
    then
        echo -n "Running onesixtyone on $ip ........"
        echo -e "\n\n=======OneSixtyOne======" >> ${ip}.info
        sudo onesixtyone -c /usr/share/metasploit-framework/data/wordlists/snmp_default_pass.txt $ip >> ${ip}.info
        echo "Done"
    fi
    echo -n "udp-proto-scanner on: $ip ......."
    sudo udp-proto-scanner.pl $ip > ${ip}_proto.udp
    echo "Done"
done<$1

echo "Running full TCP scan on list"
while read ip; do
    echo -n "Full TCP scan on: $ip ......."
    sudo nmap -v -Pn -v -A -p- -oA "${ip}_full_tcp" $ip > /dev/null
    echo "Done"
done<$1

echo "Running Default UDP - 1k ports -  scan on list"
while read ip; do
    echo -n "Default UDP scan on: $ip ......."
    sudo nmap -v -Pn -v -A -sU -oA "${ip}_full_udp" $ip > /dev/null
    echo "Done"
done<$1
