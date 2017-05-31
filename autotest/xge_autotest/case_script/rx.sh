#!/bin/bash

# rx functionality
# IN :N/A
# OUT:N/A
function rx()
{
   Test_Case_Title="GE port ping the other ge port"
   Test_Case_ID="ST_GE_TX_RX_000"
   :> D03tx.txt
   ifconfig eth1 up
   ifconfig eth1 192.168.100.212
   value1=$(ifconfig eth1 | grep -Po "(?<=RX packets:)([0-9]*)")
   ssh root@$BACK_IP 'ifconfig eth1 up; ifconfig eth1 192.168.100.200; ping 192.168.100.212 -c 3'
   value2=$(ifconfig eth1 | grep -Po "(?<=RX packets:)([0-9]*)")
   value=`expr $value2 - $value1 - 4`
   if [ $value -eq 0 ];then
	     writePass
   else
         writeFail
   fi

}

function main()
{
    JIRA_ID="PV-435"
    Test_Item="basic function of send and receive packets"
    Designed_Requirement_ID="R.HNS.F002A"
	rx
}


main


