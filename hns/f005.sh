#!/bin/bash
#Ethtool Support: Get Driver Informations   
# Testing ethtool
#get GE ports and set name
nw_if=$(ifconfig -a|grep eth|awk 'NR==2 {print $1}')
vlan_id=101
vlan_name=$nw_if.$vlan_id
#get XGE ports and set name 
nw_if2=$(ifconfig -a|grep eth|awk 'NR==4 {print $1}')
vlan_id2=103
vlan_name2=$nw_if2.$vlan_id2
#add VLAN interface
ip link add link $nw_if name $vlan_name type vlan id $vlan_id
ip link add link $nw_if2 name $vlan_name2 type vlan id $vlan_id2
#delete VLAN interface
#ip link delete $vlan_name

#Add an IPv4 address to the just created vlan link, and activate the link: 
ip addr add 192.168.$vlan_id.1/24 brd 192.168.$vlan_id.255 dev $vlan_name
ip addr add 192.168.$vlan_id2.1/24 brd 192.168.$vlan_id2.255 dev $vlan_name2
ifconfig $nw_if up
ifconfig $vlan_name up
ifconfig $nw_if2 up
ifconfig $vlan_name2 up








exit
