#!/bin/bash
    
#Ethtool Support: Self test and Loopback Test.   
# Testing ethtool 
nw_if=$(ifconfig -a|grep eth|awk 'NR==1 {print $1}')
nw_if2=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')

ethtool -t $nw_if online   
status=$?
if test $status -eq 0 
then
    echo "GE ports self test and loopback test [PASS]"
else
    echo "GE ports self test and loopback test [\e[31mFAIL\e[0m]"
    exit
fi

echo "disable ethernet device"
ifconfig $nw_if2 down
ethtool -t $nw_if2 online
status=$?
echo "enable ethernet device"
ifconfig $nw_if2 up
sleep 1
ethtool -t $nw_if2 online
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "XGE ports self test and loopback test [PASS]"
else
    echo "XGE ports self test and loopback test [\e[31mFAIL\e[0m]"
    exit
fi
exit
