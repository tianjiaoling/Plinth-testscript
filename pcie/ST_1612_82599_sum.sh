#!/bin/bash

#############################################################################

#pcie0 port link

pcie0_link1=`busybox devmem 0xa0090080`

if [ x"$pcie0_link1" = x"0xF0430000" ]; then
	echo "Yes, succeed, pcie0 port link up OK, pcie0_link1 is $pcie0_link1."
else 
	echo "No, fail, pcie0 port link up fail, pcie0_link1 is $pcie0_link1."
fi

pcie0_link2=`busybox devmem 0xa0090728 | awk '{print substr($0,9,length($0)-1)}'`

if [ x"$pcie0_link2" = x"91" ]; then
	echo "Yes, succeed, pcie0 port link up OK, pcie0_link2 is $pcie0_link2."
else 
	echo "No, fail, pcie0 port link up fail, pcie0_link2 is $pcie0_link2."
fi

#############################################################################
#pcie2 port link

pcie2_link1=`busybox devmem 0xa00a0080`

if [ x"$pcie2_link1" = x"0xF0830000" ]; then
	echo "Yes, succeed, pcie2 port link up OK, pcie2_link1 is $pcie2_link1."
else 
	echo "No, fail, pcie2 port link up fail, pcie2_link1 is $pcie2_link1."
fi

pcie2_link2=`busybox devmem 0xa00a0728 | awk '{print substr($0,9,length($0)-1)}'`

if [ x"$pcie2_link2" = x"91" ]; then
	echo "Yes, succeed, pcie2 port link up OK, pcie2_link2 is $pcie2_link2."
else 
	echo "No, fail, pcie2 port link up fail, pcie2_link2 is $pcie2_link2."
fi
#############################################################################
#############################################################################
#dmesg ixgbe driver

dmesg | grep -A 8 -B 8 pci | grep ixgbe
if [ x"$?" = x"" ]; then
	echo "No, fail, can't find dmesg ixgbe driver, enumeration test failed!"
else
	echo "Yes, succeed, find dmesg ixgbe driver, enumeration test successful."
fi
dmesg | grep pci >dmesg_599pci.txt
#############################################################################

#############################################################################
# search 82599 device info
PCI_ADDR=()

#############################################################################
for ixg_addr in `dmesg | grep ixgbe | grep "Intel(R) 10 Gigabit Network Connection" | awk '{print substr($4,0,length($4)-1)}'`
do
         if [ x"$ixg_addr" != x"" ]; then
                PCI_ADDR=(${PCI_ADDR[*]} $ixg_addr)
                echo "Yes, succeed, the PCI_ADDR is $ixg_addr."
        else
                echo "No, fail, can't find the PCI_ADDR!"
        fi
done

echo "${PCI_ADDR[@]}"

#############################################################################
OFFSET_HEX=C
NEW_VALUE=10
#############################################################################
# read&write the date of OFFSET_HEX
#############################################################################

awk_index=`printf "%d" 0x$OFFSET_HEX`
awk_index=$[awk_index + 2]
for pci_addr in ${PCI_ADDR[@]}; do

init_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`
if [ x"$init_value" = x"$NEW_VALUE" ]; then
	echo "No, fail, new value must be different from initialized value!" ; exit 1
fi


setpci -s $pci_addr $OFFSET_HEX.B=$NEW_VALUE
new_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`

if [ x"$new_value" = x"$NEW_VALUE" ]; then
	echo "Yes, succeed, setpci successful,init_value is $init_value, and new_value is $NEW_VALUE."
else
	echo "No, fail, setpci faild! (set value: $NEW_VALUE, new value: $new_value!"
fi
done

#############################################################################
# 82599 device info

# global variable
#############################################################################
IGB_DEV_IP="192.168.1.20"
GATE_WAY_IP="192.168.1.1"

IGB_ETH_NAME=()
igb_eth_name=()


#############################################################################
# get 82599 PCI address

# get 82599 network name
#############################################################################
for eth_name in `ifconfig -a |grep "eth" | awk '{print$1}'`
do
        info=`ethtool -i $eth_name | grep "driver: ixgbe"`
        if [ x"$info" != x"" ]; then
                IGB_ETH_NAME=(${IGB_ETH_NAME[*]} $eth_name)
                echo "Yes, successful, find IGB_ETH_NAME successful, the igb_eth_name is $eth_name."
        fi
done
#############################################################################
# ping function

for igb_eth_name in ${IGB_ETH_NAME[@]}; do
        ifconfig $igb_eth_name $IGB_DEV_IP

        ping -I $igb_eth_name $GATE_WAY_IP -w 180 >/dev/null
        if [ x"$?" = x"0" ]; then
                echo "Yes, succeed, $igb_eth_name is the correct Ethernet port, Intel(R) Gigabit Ethernet Network Connection Device works well." ; exit 0
                #igb_result=0
        else
                echo "No, fail, $igb_eth_name isn't the correct Ethernet port,Intel(R) Gigabit Ethernet Network Connection Device doesn't work!" ; exit 1
        fi
        ifconfig $igb_eth_name down
done
#############################################################################
lspci -k >1612_82599_lspci_k.txt

lspci -vvv >1612_82599_lspci_vvv.txt

lspci -xxx >1612_82599_lspci_xxx.txt
