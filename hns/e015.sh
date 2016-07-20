#!/bin/bash
#Support of getting current links status statistic through Ethtool get_link   
# Testing ethtool 
nw_if=$(ifconfig -a|grep eth|awk 'NR==1 {print $1}')
nw_if2=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')
linkstat=$(ethtool $nw_if|grep 'Link detected: yes')
if [ "$linkstat" = "" ]
then
    echo "get $nw_if current links status  [\e[31mFAIL\e[0m]"
    exit
else
    echo "get $nw_if current links status  [PASS]"        
fi


echo "disable ethernet device"
ifconfig $nw_if2 down
linkstat=$(ethtool $nw_if2|grep 'Link detected: yes')
if [ "$linkstat" = "" ]
then
    echo "get $nw_if2 current links status  [PASS]"    
else
    echo "get $nw_if2 current links status  [\e[31mFAIL\e[0m]"
    exit    
fi

echo "enable ethernet device"
ifconfig $nw_if2 up
sleep 1
linkstat=$(ethtool $nw_if2|grep 'Link detected: yes')
if [ "$linkstat" = "" ]
then
    echo -e "get $nw_if2 current links status  [\e[31mFAIL\e[0m]"
else
    echo "get $nw_if2 current links status  [PASS]"
    exit
fi
exit
