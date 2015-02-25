echo "Running simple ping scan..."
sudo nmap -sn $1 | ./getIpsFromFile.sh | tee excludedIps
echo "Running advanced host discovery:"
sudo nmap -sn -PS80,22,56273 -PA80,22,49163 -PU53,12739 -PP -PM -PO --excludefile excludedIps $1 | ./getIpsFromFile.sh | tee -a excludedIps
echo "Running udp-proto-scanner"
sudo nmap -sL --excludefile excludedIps $1 | ./getIpsFromFile.sh >> udp.ips
udp-proto-scanner.pl --file udp.ips | ./getIpsFromFile.sh | sort | uniq > udp.discovery
echo "Running blind host discovery:"
sudo nmap -v -Pn --top-ports 500 --excludefile excludedIps $1 > blindtcp.discovery
mv excludedIps discovered.hosts
