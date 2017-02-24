#!/bin/bash


# Load common function
. config/sas_test_lib

TEST="file_transfer_stability_test"

for dev_part in "${ALL_DISK_PART_NAME[@]}"
do
    echo "y" | mkfs.ext4 $dev_part 1>/dev/null 2>&1
    mount -t ext4 $dev_part /mnt 1>/dev/null 2>&1
    temp_info=`mount | grep -w "^$dev_part"`

    if [ x"$temp_info" == x"" ]
    then
        fail_test "Mount "$dev_part" disk failure."
        exit 1
    fi

    ./$COMMON_TOOL_PATH/iozone -a -n 1g -g 10g -i 0 -i 1 -i 2 -f /mnt/iozone -V 5aa51ff1 1 > $ERROR_INFO 2>&1
    status=$?
    info=`grep -iw 'error' $ERROR_INFO`
    if [ x"$info" == x"" ] && [ $status -ne 0 ]
    then
        fail_test "File transfer stability test,IO read and write exception."
        umount $dev_part
        exit 1
    fi

    umount $dev_part
    rm -f $ERROR_INFO
done

pass_test
