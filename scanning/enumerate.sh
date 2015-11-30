#!/bin/bash

if [ $# -lt 2 ]
then
    echo "No argument supplied - File with IPs needed"
    echo "Usage: ./enumerate <file> <type>"
    echo "Types possible: "
    echo -e "\t st - Simple tcp scan - first 1k ports"
    echo -e "\t ft - Full tcp scan - all 65535 TCP ports"
    echo -e "\t su - Simple udp scan - first 100 ports"
    echo -e "\t du - Default udp scan - first 1k ports"
    echo -e "\t fu - Full udp scan - all 65535 UDP ports"
    echo -e "\t bs - Both TCP and UDP simple scans"
    echo -e "\t bf - Full TCP and UDP scans"
    exit
fi

host_and_ping()
{
    echo -e "======Host======" >> $1/$1.info
    sudo host $1 >> $1/$1.info
#    echo -e "\n\n======Traceroute======" >> $1/$1.info
#    sudo traceroute $1 >> $1/$1.info
#    echo -e "\n\n======Ping with record route======" >> $1/$1.info
#    sudo ping -R -c 1 $1 | sed '1,/RR/d' | awk '/statistics/ {exit} {print}' >> $1/$1.info
}

run_enum4linux()
{
    OsName=$(cat $1/$1*.nmap | grep "OS details")
    echo -e "\n\n==========Operating System==========" >> $1/$1.info
    echo $OsName >> $1/$1.info
    if [[ $OsName == *"Windows"* ]]
    then
        echo  "[+]Enum4linux on: $1 ........"
        sudo enum4linux $1 > $1/$1.enum
        echo "[$1]Enum4linux done"
    fi
}

check_tcp_services()
{
    http=$(cat $1/$1_*.nmap | grep "80/tcp" | grep "open")
    if [[ $http == *"80"* ]]
    then
        echo  "[http]Found port 80 open on $1 ........"
        echo -e "\n\n[+]Found http website(port 80)" >> $1/$1.info
    fi

    https=$(cat $1/$1_*.nmap | grep "443/tcp" | grep "open")
    if [[  $https == *"443"* ]]
    then
        echo  "[https]Found port 443 open on $1 ......."
        echo -e "\n\n[+]Found https website(port 443)" >> $1/$1.info
    fi

    dns=$(cat $1/$1_*.nmap | grep "53/tcp" | grep "open")
    if [[ $dns == *"53"* ]]
    then
        echo  "[dns]Found TCP port 53 open on $1 ......."
        echo -e "\n\n[+] Found dns service" >> $1/$1.info
    fi

    ssh=$(cat $1/$1_*.nmap  | grep "22/tcp" | grep "open")
    if [[ $ssh == *"22"* ]]
    then
        echo  "[ssh]Found port 22 open on $1........"
        echo -e "\n\n[+] Found ssh service" >> $1/$1.info
    fi

    nfs=$(cat $1/$1_*.nmap | grep "2049/tcp" | grep "open")
    if [[ $nfs == *"2049"* ]]
    then
        echo  "[nfs]Found port 2049 open on $1......"
        echo -e "\n\n[+] Found nfs service" >> $1/$1.info
    fi

    rdp=$(cat $1/$1_*.nmap | grep "3389/tcp" | grep "open")
    if [[ $rdp == *"3389"* ]]
    then
        echo  "[rdp]Found port 3389 open on $1......"
        echo -e "\n\n[+] Found rdp service" >> $1/$1.info
    fi

    ftp=$(cat $1/$1_*.nmap | grep "21/tcp" | grep "open")
    if [[ $ftp == *"21"* ]]
    then
        echo  "[ftp]Found port 21 open on $1......"
        echo -e "\n\n[+] Found ftp service" >> $1/$1.info
    fi

    smtp=$(cat $1/$1_*.nmap | grep "25/tcp" | grep "open")
    if [[ $smtp == *"25"* ]]
    then
        echo  "[smtp]Found port 25 open on $1....."
        echo -e "\n\n[+] Found SMTP service" >> $1/$1.info
    fi

    #TODO: kerberos, sftp, dcom, netbios, ldap, ldaps, mssql, mysql, postgresql
    echo  "[$1]Finished parsing tcp services"
}

check_udp_services()
{
    snmp=$(cat $1/$1_*.nmap | grep "161/udp" | grep "open")
    if [[ $snmp == *"161/udp"* ]]
    then
        echo  "[snmp]Found SNMP service on $1, running 161"
        echo -e "\n\n[+] Found SNMP service" >> $1/$1.info
        echo -e "\n\n=======OneSixtyOne======" >> $1/${1}.info
        sudo onesixtyone -c /usr/share/metasploit-framework/data/wordlists/snmp_default_pass.txt $1 >> $1/$1.info
    fi
    echo "[$1] Finished parsing UDP services, running udp-proto-scanner"
    sudo udp-proto-scanner.pl $1 > $1/$1_proto.udp
    echo "[$1]UDP ProtoScanner done"
}

run_full_tcp()
{
    sudo nmap --max-retries 5 -vv -n --reason -Pn -p- -A -oA "$1/$1_full_tcp" $1 > "$1/$1_live" 2>&1
    echo "[$1] Full TCP Scan done"
    check_tcp_services $1
}

run_simple_tcp()
{
    sudo nmap -vv -n --reason -Pn -A -oA "$1/$1_simple_tcp" $1 > "$1/$1_live" 2>&1  
    echo "[$1] Simple TCP Scan done"
    check_tcp_services $1
}

run_default_udp()
{
    sudo nmap --max-retries 5 -vv -n --reason -Pn -A -sU -oA "$1/$1_default_udp" $1 > "$1/$1_live_udp" 2>&1
    echo "[$1]Default UDP scan done"
    check_udp_services $1
}

run_full_udp()
{
    sudo nmap --max-retries 3 -vv -n --reason -Pn -A -sU -p- -oA "$1/$1_full_udp" $1 > "$1/$1_live_udp" 2>&1
    echo "[$1]Full UDP scan done"
    check_udp_services $1
}

run_simple_udp()
{
    sudo nmap -vv -n --reason -Pn -v -A -sU --top-ports 100 -oA "$1/$1_simple_udp" $1 > "$1/$1_live_udp" 2>&1
    echo "[$1]Simple UDP scan done"
    check_udp_services $1
}

if [ $# -ge 3 ]
then
    echo -e "***NOTE: Any argument past first two is not taken into consideration......just so you know\n\n"
fi

echo "[+]Creating folders for each IP in the list"
while read ip; do
    mkdir $ip
done<$1

echo "[+]Running host and traceroute on the ip list"
while read ip; do
    host_and_ping $ip &
done<$1

wait
echo "Finished running host and traceroute on the list"

if [[ $2 == "st" || $2 == "bs" ]]
then
    echo "[+]Running simple TCP scan on the list given"
    while read ip; do
        run_simple_tcp $ip &
    done<$1
    wait
    echo "[+]Finished simple TCP scan on all IPs"
fi

if [[ $2 == "su" || $2 == "bs" ]]
then
    echo "[+]Running simple udp scan on the ip list"
    while read ip; do
        run_simple_udp $ip &
    done<$1
    wait
    echo "[+]Finished simple UDP scan on all IPs"
fi

if [[ $2 == "du" ]]
then
    echo "[+]Running default udp scan on the ip list"
    while read ip; do
        run_default_udp $ip &
    done<$1
    wait
    echo "[+]Finished default UDP scan on all IPs"
fi


if [[ $2 == "ft" || $2 == "bf" ]]
then
    echo "Running full TCP scan on the list"
    while read ip; do
        run_full_tcp $ip &
    done<$1
    wait
    echo "[+]Finished Full TCP Scan on all IPs"
fi

if [[ $2 == "fu" || $2 == "bf" ]]
then
    echo "Running full UDP scan on the list"
    while read ip; do
        run_full_udp $ip &
    done<$1

    wait
    echo "[+]Finished full UDP scan on all IPs"
fi
while read ip; do
    run_enum4linux $ip
done<$1
