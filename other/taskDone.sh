#!/bin/bash

if [ -z "$1" ]; then
   echo "Specify task code"
   exit
fi

lg Archiving and uploading zip - task finished

FULL_ARCHIVE_PATH=/root/archiveProjects/${1}-CRM.tgz

echo "Full Archive Path is: $FULL_ARCHIVE_PATH"

tar -zcvf $FULL_ARCHIVE_PATH /root/projects/$1

ls -l $FULL_ARCHIVE_PATH

echo "[+] Uploading archive to XDB..."

lftp sftp://crm@xdb -e "put ${FULL_ARCHIVE_PATH};bye" -p 65122

echo "MD5 of the archive is: "

md5sum $FULL_ARCHIVE_PATH

rm /var/log/work.log
