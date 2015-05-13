#!/bin/bash

if [ -z "$1" ]; then
    echo "Specify new folder name(task code)"
    exit
else
    newFolder="$1"
fi

folderArray=(screenshots documents logs scripts other notes)


echo "[+] Creating directory skeleton..."
for fName in ${folderArray[@]}
do
    echo "[+] Creating $fname"
    mkdir -p $newFolder/$fName
done

echo "[+] Creating symbolic link for the tools folder"
ln -s /home/cristi/tools $newFolder/
echo "[+] Copying scripts ..."
cp /home/cristi/crimike/scripts/scanning/* $newFolder/

echo "[+] Creating work log"

rm /var/log/work.log
touch $newFolder/work.log
ln -s /root/projects/$newFolder/work.log /var/log/work.log
