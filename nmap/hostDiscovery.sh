echo "Running simple ping scan..."
sudo nmap -sn $1 | ./getIpsFromFile.sh | tee excludedIps
echo "Running advanced host discovery:"
sudo nmap -sn -PS80,22,56273 -PA80,22,49163 -PU53,12739 -PP -PM -PR --excludefile excludedIps $1 | ./getIpsFromFile.sh | tee -a excludedIps
echo "Running blind host discovery:"
sudo nmap -Pn --top-ports 500 --excludefile excludedIps $1 > blindtcp.discovery
echo "Running udp-proto-scanner"
sudo nmap -sL --excludefile excludedIps $1 | ./getIpsFromFile.sh | xargs | udp-proto-scanner | ./getIpsFromFile.sh | sort | uniq > udp.discovery
mv excludedIps discovered.hosts
