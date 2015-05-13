#!/bin/bash
a=$(hping3 $1 -p 80 -S --tcp-timestamp -c 1 2>&1 | grep "timestamp" | cut -d"=" -f2)
sleep 5
b=$(hping3 $1 -p 80 -S --tcp-timestamp -c 1 2>&1 | grep "timestamp" | cut -d"=" -f2)
s=`expr $b - $a`
s=`expr $s / 5`
s=`expr $a / $s`
echo Seconds: $s
echo Minutes: `expr $s / 60`
echo Hours: `expr $s / 3600`
echo Days: `expr $s / 86400`
