echo "Running simple ping scan..."
sudo nmap -sn $1 | ./getIpsFromFile.sh > excludedIps
echo "Found:"
cat excludedIps
sudo nmap -sn -PS22,56273 -PA80,22,49163 -PU53,12739 -PP -PM --source-port 53 --excludefile excludedIps $1 | ./getIpsFromFile.sh
rm -f excludedIps
