#!/bin/bash
#Ethtool Support: Get Driver Informations   
# Testing ethtool 
nw_if=$(ifconfig -a|grep eth|awk 'NR==1 {print $1}')
nw_if2=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')

ethtool -i $nw_if    
status=$?
if test $status -eq 0 
then
    echo "command ethtool -i $nw_if [PASS]"
else
    echo "command ethtool -i $nw_if [\e[31mFAIL\e[0m]"
    exit
fi

echo "disable ethernet device"
ifconfig $nw_if2 down
ethtool -i $nw_if2    
status=$?
echo "enable ethernet device"
ifconfig $nw_if2 up
sleep 1
ethtool -i $nw_if2    
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "command ethtool -i $nw_if2 [PASS]"
else
    echo "command ethtool -i $nw_if2 [\e[31mFAIL\e[0m]"
    exit
fi
exit
