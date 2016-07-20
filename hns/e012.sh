#!/bin/bash
    
#Support of get Ethernet port mode, phy type and etc through Ethtool get_settings and set_settings.   
# Testing ethtool 
nw_if=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')
nw_if2=$(ifconfig -a|grep eth|awk 'NR==4 {print $1}')

ethtool $nw_if    
status=$?
if test $status -eq 0 
then
    echo "command ethtool $nw_if [PASS]"
else
    echo "command ethtool $nw_if [\e[31mFAIL\e[0m]"
    exit
fi

echo "disable ethernet device"
ifconfig $nw_if2 down
ethtool $nw_if2    
status=$?
echo "enable ethernet device"
ifconfig $nw_if2 up
sleep 1
ethtool $nw_if2    
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "command ethtool $nw_if2 [PASS]"
else
    echo "command ethtool $nw_if2 [\e[31mFAIL\e[0m]"
    exit
fi
exit
