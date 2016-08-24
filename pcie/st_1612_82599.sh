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
#Check if dmesg ixgbe driver loaded successfully
test_dmesg_ixgbe_driver_load()
{
    TEST="dmesg_ixgbe_driver_load"
    dmesg | grep -A 8 -B 8 pci | grep ixgbe
    if [ x"$?" = x"" ]; then
        fail_test "No, fail, can't find dmesg ixgbe driver, enumeration test failed!"
        return 1
    fi
    echo "Yes, succeed, find dmesg ixgbe driver, enumeration test successful."
    dmesg | grep pci >dmesg_599pci.txt
    pass_test
}
#############################################################################

#############################################################################
# Check PCIe address ethx exists
test_exist_pci_addr()
{
    TEST="exist_pci_addr"
    PCI_ADDR=()

    for ixg_addr in `dmesg | grep ixgbe | grep "Intel(R) 10 Gigabit Network Connection" | awk '{print substr($4,0,length($4)-1)}'`
    do
    if [ x"$ixg_addr" = x"" ]; then
        fail_test "No, fail, can't find the PCI_ADDR!"
        return 1
    fi
        PCI_ADDR=(${PCI_ADDR[*]} $ixg_addr)
        echo "Yes, succeed, the PCI_ADDR is $ixg_addr."

    done

    echo "${PCI_ADDR[@]}"
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

    for pci_addr in `dmesg | grep ixgbe | grep "Intel(R) 10 Gigabit Network Connection" | awk '{print substr($4,0,length($4)-1)}'`
    do
        init_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`
        if [ x"$init_value" = x"$NEW_VALUE" ]; then
            fail_test "No, fail, new value must be different from initialized value!"
            return 1
        fi

        setpci -s $pci_addr $OFFSET_HEX.B=$NEW_VALUE
        new_value=`lspci -s $pci_addr -xxx | grep -P "^(00: )" | awk -F' ' '{print $'$awk_index'}'`

        if [ x"$new_value" != x"$NEW_VALUE" ]; then
            fail_test "No, fail, setpci faild! (set value: $NEW_VALUE, new value: $new_value!"
            return 1
        fi
        echo "Yes, succeed, setpci successful,init_value is $init_value, and new_value is $NEW_VALUE."
    done
    pass_test
}
#############################################################################
# Check ping function is ok
#############################################################################
test_network_ping_function()
{
    TEST="network_ping_function"
    IGB_DEV_IP="192.168.1.20"
    GATE_WAY_IP="192.168.1.1"

    IGB_ETH_NAME=()
    igb_eth_name=()

    # get 82599 PCI address, get 82599 network name
    for eth_name in `ifconfig -a |grep "eth" | awk '{print$1}'`
    do
            info=`ethtool -i $eth_name | grep "driver: ixgbe"`
            if [ x"$info" = x"" ]; then
            fail_test "No, fail, find IGB_ETH_NAME failed, can't find ethx!"
            return 1
            fi
        IGB_ETH_NAME=(${IGB_ETH_NAME[*]} $eth_name)
        echo "Yes, successful, find IGB_ETH_NAME successful, the igb_eth_name is $eth_name."
    done

    # Check ping function is ok
    for igb_eth_name in ${IGB_ETH_NAME[@]}
    do
            ifconfig $igb_eth_name $IGB_DEV_IP

            ping -I $igb_eth_name $GATE_WAY_IP -w 180 >/dev/null
            if [ x"$?" != x"0" ]; then
            fail_test "No, fail, $igb_eth_name isn't the correct Ethernet port,Intel(R) \
                Gigabit Ethernet Network Connection Device doesn't work!"
            return 1
            fi
            echo "Yes, succeed, $igb_eth_name is the correct Ethernet port, Intel(R) Gigabit Ethernet \
                Network Connection Device works well."
            ifconfig $igb_eth_name down
    done

    pass_test
}
#############################################################################
# run the tests
test_status_pcie0_link1
test_status_pcie0_link2
test_status_pcie2_link1
test_status_pcie2_link2
test_dmesg_ixgbe_driver_load
test_exist_pci_addr
test_rw_date_offset_hex
test_network_ping_function
# clean exit so lava-test can trust the results
exit 0
