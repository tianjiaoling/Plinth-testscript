#!/bin/bash
#############################################################################
# SSD device_info  global constant
#############################################################################
SSD_DRIVER=nvme
OFFSET_HEX=C
NEW_VALUE=10
PCI_ADDR=()
route=/dev
SSD_NAME=()
#int_value=00
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
# P3600 Enumeration test

dmesg | grep pci | grep -A 8 -B 4 "$SSD_DRIVER" >/dev/null
if [ x"$?" != x"0" ]; then
	echo "No, fail, can't find dmesg ssd nvme driver, enumeration test failed!"
else
	echo "Yes, succeed, find dmesg ssd nvme driver, enumeration test successful."
fi
dmesg | grep pci >dmesg_ssdpci.txt

#############################################################################
lspci -v | grep "Kernel driver in use: $SSD_DRIVER"
if [ x"$?" != x"0" ]; then
	echo "No, fail, can't find any SSD driver info by lspci -v command!"
else
	echo "Yes, succeed, the SSD driver name is $SSD_DRIVER by lspci -v command."
fi

#############################################################################

for ssd_addr in `dmesg | grep nvme | grep "enabling device (0000 -> 0002)" | awk '{print substr($4,0,length($4)-1)}'`
do
         if [ x"$ssd_addr" != x"" ]; then
                PCI_ADDR=(${PCI_ADDR[*]} $ssd_addr)
                echo "Yes, succeed, the PCI_ADDR is $ssd_addr."
        else
                echo "No, fail, can't find the PCI_ADDR!"
        fi
done

echo "${PCI_ADDR[@]}"

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
	echo "Yes, succeed, setpci successful,init_value is $init_value, and new_value is $NEW_VALUE!"
else
	echo "No, fail, setpci faild! (set value: $NEW_VALUE, new value: $new_value"
fi
done
#############################################################################
lspci -k >1612_ssd_lspci_k.txt

lspci -vvv >1612_ssd_lspci_vvv.txt

lspci -xxx >1612_ssd_lspci_xxx.txt

#############################################################################

name_temp=`ls $route/$SSD_DRIVER*`
if [ x"$name_temp" = x"nvme0 nvme0n1" -o x"nvme1 nvme1n1" -o x"nvme0 nvme0n1 nvme1 nvme1n1" ]; then
        echo "Yes, succeed, find $name_temp in the directory $route."
else
        echo "No, fail, can't find  $name_temp in the directory $route!"
fi
#############################################################################
#############################################################################
for ssd_name in `lsblk | grep $SSD_DRIVER | awk '{print $1}'`
do
	if [ x"ssd_name" = x"" ]; then
		echo "No, fail, can't find SSD_NAME!"; exit 1
	else
		SSD_NAME=(${SSD_NAME[*]} $ssd_name)
		echo "Yes, succeed, the SSD_NAME is $ssd_name."
	fi
done

echo "${SSD_NAME[@]}"
mkdir -p /mnt/nvme

for ssd_temp in ${SSD_NAME[@]}
do
	mkfs.ext4 /dev/$ssd_temp
	mount /dev/$ssd_temp /mnt/nvme
	mount | grep /dev/$ssd_temp
	if [ x"$?" != x"0" ]; then
		echo "No, fail, can't mount $ssd_temp SSD up!" ; exit 1
	else
		echo "Yes, succeed, can $ssd_temp mount SSD up."
	fi
done






