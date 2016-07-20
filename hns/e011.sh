#!/bin/bash
    
#Support KEY registers query (PPE,RCB,DSA,GE/XGE)   
# Testing ethtool 
nw_if=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')
nw_if2=$(ifconfig -a|grep eth|awk 'NR==4 {print $1}')
#GE ports registers query
echo "restart ethernet device $nw_if"
ifconfig $nw_if down
ethtool -d $nw_if 1>/dev/null
status=$?
ifconfig $nw_if up;sleep 1
ethtool -d $nw_if 1>/dev/null
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "command ethtool -d $nw_if [PASS]"
else
    echo "command ethtool -d $nw_if [\e[31mFAIL\e[0m]"
    exit
fi
#iperf test
echo "iperf test $nw_if"
#start server process
iperf -s  1>/dev/null &
#clear and start iperf
COMMAND="pid=\`ps -ef|grep 'iperf -c'|tac|sed '1,3d'|awk '{print \$2}'\`;kill -9 \`echo \$pid\` 1>/dev/null 2>\&1;iperf -s 1>/dev/null &"
ssh 192.168.2.2 "${COMMAND}"
ssh 192.168.2.2 'iperf -c 192.168.2.1 -t 80 -d -P 3 1>/dev/null &'
#start test registers query
declare -i i=1
while ((i<=8)) 
do
ethtool -d $nw_if 1>/dev/null
status=$?
if test $status -eq 0
then
    :
else
    echo "command ethtool -d $nw_if [\e[31mFAIL\e[0m]"
    exit
fi
sleep 9
let ++i
done
#XGE ports registers query
echo "restart ethernet device $nw_if2"
ifconfig $nw_if2 down
ethtool -d $nw_if2 1>/dev/null  
status=$?
ifconfig $nw_if2 up;sleep 1
ethtool -d $nw_if2 1>/dev/null    
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "command ethtool -d $nw_if2 [PASS]"
else
    echo "command ethtool -d $nw_if2 [\e[31mFAIL\e[0m]"
    exit
fi
#iperf test
echo "iperf test $nw_if2"
#clear and start iperf
COMMAND="pid=\`ps -ef|grep 'iperf -c'|tac|sed '1,3d'|awk '{print \$2}'\`;kill -9 \`echo \$pid\` 1>/dev/null 2>\&1"
ssh 192.168.4.2 "${COMMAND}"
ssh 192.168.4.2 'iperf -c 192.168.4.1 -t 80 -d -P 3 1>/dev/null &'
#start test registers query
declare -i i=1
while ((i<=8)) 
do
ethtool -d $nw_if2 1>/dev/null
status=$?
if test $status -eq 0
then
    :
else
    echo "command ethtool -d $nw_if2 [\e[31mFAIL\e[0m]"
    exit
fi
sleep 9
let ++i
done

#clear all iperf process
COMMAND_CLR="pid=\`ps -ef|grep 'iperf'|tac|sed '1,3d'|awk '{print \$2}'\`;kill -9 \`echo \$pid\` 1>/dev/null 2>\&1"
ssh 192.168.2.2 "${COMMAND_CLR}"
pid=`ps -ef|grep 'iperf'|tac|sed '1d'|awk '{print $2}'`;kill -9 'echo $pid'

exit

