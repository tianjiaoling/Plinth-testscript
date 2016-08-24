#!/bin/bash
. include/sh-test-lib
#############################################################################
#Check if pcie0 port link1 status is ok
test_status_pcie0_link1()
{
	TEST="status_pcie0_link1"
	pcie0_link1_status=`busybox devmem 0xa0090080`

	if [ x"$pcie0_link1" != x"0xF0430000" ]; then
		fail_test "No, fail, pcie0 port link up fail, pcie0_link1 is $pcie0_link1."
		return 1
	fi
	echo "Yes, succeed, pcie0 port link up OK, pcie0_link1 is $pcie0_link1."
	pass_test
}


#Check if pcie0 port link2 status is ok
test_status_pcie0_link2()
{
	TEST="status_pcie0_link2"
	pcie0_link2=`busybox devmem 0xa0090728 | awk '{print substr($0,9,length($0)-1)}'`

	if [ x"$pcie0_link2" != x"91" ]; then
		fail_test "No, fail, pcie0 port link up fail, pcie0_link2 is $pcie0_link2."
		return 1
	fi
	echo "Yes, succeed, pcie0 port link up OK, pcie0_link2 is $pcie0_link2."
	pass_test
}

#############################################################################
#Check if pcie2 port link1 status is ok
test_status_pcie2_link1()
{
	TEST="status_pcie2_link1"
	pcie2_link1=`busybox devmem 0xa00a0080`

	if [ x"$pcie2_link1" != x"0xF0830000" ]; then 
		fail_test "No, fail, pcie2 port link up fail, pcie2_link1 is $pcie2_link1."
		return 1
	fi
	echo "Yes, succeed, pcie2 port link1 up OK, pcie2_link1 is $pcie2_link1."
	pass_test
}


#Check if pcie2 port link2 status is ok
test_status_pcie2_link2()
{
	TEST="status_pcie2_link2"
	pcie2_link2=`busybox devmem 0xa00a0728 | awk '{print substr($0,9,length($0)-1)}'`

	if [ x"$pcie2_link2" != x"91" ]; then
	fail_test "No, fail, pcie2 port link up fail, pcie2_link2 is $pcie2_link2."
	return 1
	fi
	echo "Yes, succeed, pcie2 port link2 up OK, pcie2_link2 is $pcie2_link2."
	pass_test
}
#############################################################################
#############################################################################
#Check if P3600 SSD 400G Enumeration info
test_ssd_driver_enumeration()
{
	TEST="ssd_driver_enumeration"
	SSD_DRIVER=nvme

	dmesg | grep pci | grep -A 8 -B 4 "$SSD_DRIVER" >/dev/null
	if [ x"$?" != x"0" ]; then
		fail_test "No, fail, can't find dmesg ssd nvme driver, enumeration test failed!"
		return 1
	fi
	echo "Yes, succeed, find dmesg ssd nvme driver, enumeration test successful."
	dmesg | grep pci >dmesg_ssdpci.txt
	pass_test
}
#############################################################################
#Check if P3600 SSD driver is right
test_ssd_driver_name()
{
	TEST="lspci_ssd_driver_name"
	SSD_DRIVER=nvme
	lspci -v | grep "Kernel driver in use: $SSD_DRIVER"
	if [ x"$?" != x"0" ]; then
		fail_test "No, fail, can't find any SSD driver info by lspci -v command!"
		return 1
	fi
	echo "Yes, succeed, the SSD driver name is $SSD_DRIVER by lspci -v command."
	pass_test
}
#############################################################################
# Check PCIe address ethx exists
test_exist_pci_addr()
{
	TEST="exist_pci_addr"
	PCI_ADDR=()
	for ssd_addr in `dmesg | grep nvme | grep "enabling device (0000 -> 0002)" | awk '{print substr($4,0,length($4)-1)}'`
	do
		if [ x"$ssd_addr" != x"" ]; then
                	fail_test "No, fail, can't find the PCI_ADDR!"
			return 1
		fi
		PCI_ADDR=(${PCI_ADDR[*]} $ssd_addr)
        	echo "Yes, succeed, the PCI_ADDR is $ssd_addr."
		echo "${PCI_ADDR[@]}"
	done
	pass_test
}

#############################################################################
# Check if the date of OFFSET_HEX can be read and write 
test_rw_date_offset_hex()
{
	TEST="rw_date_offset_hex"
	OFFSET_HEX=C
	NEW_VALUE=30
	pci_addr=()
	awk_index=`printf "%d" 0x$OFFSET_HEX`
	awk_index=$[awk_index + 2]

	for pci_addr in`dmesg | grep ixgbe | grep "Intel(R) 10 Gigabit Network Connection" | awk '{print substr($4,0,length($4)-1)}'`
	do

		init_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`
		if [ x"$init_value" = x"$NEW_VALUE" ]; then
			fail_test "No, fail, new value must be different from initialized value!"
			return 1
		fi

		setpci -s $pci_addr $OFFSET_HEX.B=$NEW_VALUE
		new_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`

		if [ x"$new_value" != x"$NEW_VALUE" ]; then
			fail_test "No, fail, setpci faild! (set value: $NEW_VALUE, new value: $new_value"
			return 1
		fi
		echo "Yes, succeed, setpci successful,init_value is $init_value, and new_value is $NEW_VALUE!"
	done
	pass_test
}
#############################################################################
#Check if SSD card recognition ok
test_ls_ssd_name()
{
	TEST="ls_ssd_name"
	route=/dev
	SSD_DRIVER=nvme
	name_temp=`ls $route/$SSD_DRIVER*`

	if [ x"$name_temp" != x"nvme0 nvme0n1" -o x"nvme1 nvme1n1" -o x"nvme0 nvme0n1 nvme1 nvme1n1" ]; then
		fail_test "No, fail, can't find  $name_temp in the directory $route!"
		return 1
	fi
     
	echo "Yes, succeed, find $name_temp in the directory $route."
	pass_test
}

#############################################################################
#Check if SSD partition ok
test_mount_ssd()
{
	TEST="mount_ssd"
	SSD_NAME=()
	SSD_DRIVER=nvme

	for ssd_name in `lsblk | grep $SSD_DRIVER | awk '{print $1}'`
	do
		if [ x"ssd_name" = x"" ]; then
			fail_test "No, fail, can't find SSD_NAME!"
			return 1
		fi
		SSD_NAME=(${SSD_NAME[*]} $ssd_name)
		echo "Yes, succeed, the SSD_NAME is $ssd_name."
	done

	echo "${SSD_NAME[@]}"
	mkdir -p /mnt/nvme

	for ssd_temp in ${SSD_NAME[@]}
	do
		mkfs.ext4 /dev/$ssd_temp
		mount /dev/$ssd_temp /mnt/nvme
		mount | grep /dev/$ssd_temp
		if [ x"$?" != x"0" ]; then
			fail_test "No, fail, can't mount $ssd_temp SSD up!"
			return 1
		fi
		echo "Yes, succeed, can $ssd_temp mount SSD up."
	done
	pass_test
}

#############################################################################

# run the tests
test_status_pcie0_link1
test_status_pcie0_link2
test_status_pcie2_link1
test_status_pcie2_link2
test_ssd_driver_enumeration
test_ssd_driver_name
test_exist_pci_addr
test_rw_date_offset_hex
test_ls_ssd_name
test_mount_ssd
# clean exit so lava-test can trust the results
exit 0


