cat /usr/share/nmap/nmap-services | grep -v "^#" | grep $1 | tr '\t' ' ' | awk '{print $3, $2, $1}' | sort -r | head -$2 | cut -d' ' -f2 | cut -d'/' -f1
