#!/bin/bash
#tailf log.c |grep SUM 
iperf -c 192.168.2.1 -t 1550 -i 1 -P 20 > log.c &
declare -i i=1
while ((i<=100)) 
do
ifconfig eth5 mtu 68

sleep 5

ifconfig eth5 mtu 1500
sleep 5

ifconfig eth5 mtu 9706
sleep 5

let ++i
done
exit

