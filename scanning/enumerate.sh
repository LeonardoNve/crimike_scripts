#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No argument supplied - File with IPs needed"
    exit
fi

host_and_ping()
{
    echo -e "======Host======" >$1.info
    sudo host $1 >> $1.info
    echo -e "\n\n======Traceroute======" >> $1.info
    sudo traceroute $1 >> $1.info
    echo -e "\n\n======Ping with record route======" >> $1.info
    sudo ping -R -c 1 $1 | sed '1,/RR/d' | awk '/statistics/ {exit} {print}' >> $1.info
}

parse_tcp()
{
    sudo nmap -v -Pn -A -oA "$1_simple_tcp" $1 > /dev/null
    echo "[$1] Simple TCP Scan done"
    OsName=$(cat $1_simple_tcp.nmap | grep "OS details")
    echo -e "\n\n==========Operating System==========" >> $1.info
    echo $OsName >> $1.info
    if [[ $OsName == *"Windows"* ]]
    then
        echo  "[+]Enum4linux on: $1 ........"
        sudo enum4linux $1 > $1.enum
        echo "[$1]Enum4linux done"
    fi
    http=$(cat $1_simple_tcp.nmap | grep "80/tcp")
    if [[ $http == *"80"* ]]
    then
        echo  "[http]Found http website on $1 ........"
        echo -e "\n\n[+]Found http website(port 80)" >> $1.info
    fi
    https=$(cat $1_simple_tcp.nmap | grep "443/tcp")
    if [[  $https == *"443"* ]]
    then
        echo  "[https]Found https website on $1 ......."
        echo -e "\n\n[+]Found https website(port 443)" >> $1.info
    fi
    dns=$(cat $1_simple_tcp.nmap | grep "53/tcp")
    if [[ $dns == *"53"* ]]
    then
        echo  "[dns]Found DNS service on $1 ......."
        echo -e "\n\n[+] Found dns service" >> $1.info
    fi
    ssh=$(cat $1_simple_tcp.nmap  | grep "22/tcp")
    if [[ $ssh == *"22"* ]]
    then
        echo  "[ssh]Found ssh service on $1........"
        echo -e "\n\n[+] Found ssh service" >> $1.info
    fi
    nfs=$(cat $1_simple_tcp.nmap | grep "2049/tcp")
    if [[ $nfs == *"2049"* ]]
    then
        echo  "[nfs]Found nfs service on $1......"
        echo -e "\n\n[+] Found nfs service" >> $1.info
    fi
    rdp=$(cat $1_simple_tcp.nmap | grep "3389/tcp")
    if [[ $rdp == *"3389"* ]]
    then
        echo  "[rdp]Found rdp service on $1......"
        echo -e "\n\n[+] Found rdp service" >> $1.info
    fi
    ftp=$(cat $1_simple_tcp.nmap | grep "21/tcp")
    if [[ $ftp == *"21"* ]]
    then
        echo  "[ftp]Found FTP service on $1......"
        echo -e "\n\n[+] Found ftp service" >> $1.info
    fi
    smtp=$(cat $1_simple_tcp.nmap | grep "25/tcp")
    if [[ $smtp == *"25"* ]]
    then
        echo  "[smtp]Found SMTP service on $1....."
        echo -e "\n\n[+] Found SMTP service" >> $1.info
    fi
    tftp=$(cat $1_simple_tcp.nmap | grep "69/tcp")
    if [[ $tftp == *"69"* ]]
    then
        echo  "[tftp]Found tftp service on $1....."
        echo -e "\n\n[+] Found tftp service" >> $1.info
    fi
    #TODO: kerberos, sftp, dcom, netbios, ldap, ldaps, mssql, mysql, postgresql
    echo  "[$1]Finished parsing tcp services"
}

parse_udp()
{
    sudo nmap -v -Pn -v -A -sU --top-ports 100 -oA "$1_simple_udp" $1 > /dev/null
    echo "[$1]Simple UDP scan done"
    snmp=$(cat $1_simple_udp.nmap | grep "161/udp")
    if [[ $snmp == *"161/udp"* ]]
    then
        echo  "[smtp]Found SMTP service on $1, running 161"
        echo -e "\n\n[+] Found SMTP service" >> $1.info
        echo -e "\n\n=======OneSixtyOne======" >> ${ip}.info
        sudo onesixtyone -c /usr/share/metasploit-framework/data/wordlists/snmp_default_pass.txt $1 >> $1.info
    fi
    sudo udp-proto-scanner.pl $1 > $1_proto.udp
    echo "[$1]UDP ProtoScanner done"
}

if [ $# -ge 2 ]
then
    echo -e "***NOTE: Any argument past '$1' is not taken into consideration......just so you know\n\n"
fi

echo "[+]Running host and traceroute on the ip list"
while read ip; do
    host_and_ping $ip &
done<$1

echo "[+]Running simple TCP scan on the list given"
while read ip; do
    parse_tcp $ip &
done<$1

wait

echo "[+]Running basic udp scan on the ip list"
while read ip; do
    parse_udp $ip &
done<$1

wait

echo "Running full TCP scan on list"
while read ip; do
    sudo nmap -v -Pn -v -A -p- -oA "${ip}_full_tcp" $ip > /dev/null &
done<$1

wait
echo "[++]Finished Full TCP Scan"

echo "Running Default UDP - 1k ports -  scan on list"
while read ip; do
    sudo nmap -v -Pn -v -A -sU -oA "${ip}_full_udp" $ip > /dev/null &
done<$1
