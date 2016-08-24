#!/bin/bash
#GE ports support of negotiation reset through Ethtool    
# Testing ethtool
#get GE ports 
nw_if=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')
#the network interface module is loaded, re-enter auto-negotiation command
ifconfig $nw_if down 
ethtool -r $nw_if 
ifconfig $nw_if up
sleep 3
#network interface up, ping success;
ping 192.168.2.2 -c 3 1>/dev/null 2>&1
status=$?
if test $status -eq 0 
then
    echo "command ethtool -r $nw_if [PASS]"
else
    echo -e "command ethtool -r $nw_if [\e[31mFAIL\e[0m]"
    exit
fi

echo "restart ethernet device"
ifconfig $nw_if down
sleep 3
ethtool -r $nw_if
status=$?
ifconfig $nw_if up
sleep 3
ping 192.168.2.2 -c 3 1>/dev/null 2>&1
status2=$?
if test $status -eq 0 -a  $status2 -eq 0
then
    echo "command ethtool -r $nw_if [PASS]"
else
    echo -e "command ethtool -r $nw_if [\e[31mFAIL\e[0m]"
    exit
fi
function check_iperf(){
pid=$(ps -ef|grep 'iperf -s'|awk 'NR==1 {print $2}')
if [ "$pid" = "" ]
then exit
else 
kill -9 $pid 1>/dev/null 2>\&1
fi
}

check_iperf
iperf -s  1>/dev/null &

COMMAND="pid=\`ps -ef|grep 'iperf -c'|tac|sed '1,3d'|awk '{print \$2}'\`;kill -9 \`echo \$pid\` 1>/dev/null 2>\&1"
ssh 192.168.2.2 "${COMMAND}"

#ssh 192.168.2.2 'kill -9 $(ps -ef|grep 'iperf -c'|sed -n '1,1p'|tr -s ' '|cut -d ' ' -f2)'
ssh 192.168.2.2 'iperf -s 1>/dev/null &'
#sleep 5
ssh 192.168.2.2 'iperf -c 192.168.2.1 -t 80 -d -P 3 1>/dev/null &'

declare -i i=1
while ((i<=8)) 
do

ethtool -r $nw_if
rx_bytes=$(ethtool -S $nw_if|grep rx_bytes|awk '{print $2}')
sleep 9
rx_bytes2=$(ethtool -S $nw_if|grep rx_bytes|awk '{print $2}')
speed=`echo "scale=2;($rx_bytes2-$rx_bytes)/9/1024/1024"|bc`
stdspeed=10
#if [ `echo "$max > $min" | bc` -eq 1 ]
if [ `echo "$speed > $stdspeed" | bc` -eq 1 ]
then
echo "speed is $speed Mbits/sec"
else
echo -e "command ethtool -r $nw_if [\e[31mFAIL\e[0m]"
exit
fi
let ++i

done

exit
