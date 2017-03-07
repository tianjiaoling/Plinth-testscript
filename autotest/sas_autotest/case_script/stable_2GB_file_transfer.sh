#!/bin/bash


function iozne_file_transfer_stability_test()
{
    Test_Case_Title="iozne_file_transfer_stability_test"
    Test_Case_ID="ST.FUNC.049/ST.FUNC.050"

    for dev_part in "${ALL_DISK_PART_NAME[@]}"
    do
        echo "y" | mkfs.ext4 $dev_part 1>/dev/null 2>&1
        mount -t ext4 $dev_part /mnt 1>/dev/null 2>&1
        temp_info=`mount | grep -w "^$dev_part"`

        if [ x"$temp_info" == x"" ]
        then
            writeFail "Mount "$dev_part" disk failure."
            exit 1
        fi

        ./$COMMON_TOOL_PATH/iozone -a -n 1g -g 10g -i 0 -i 1 -i 2 -f /mnt/iozone -V 5aa51ff1 1 > $ERROR_INFO 2>&1
        status=$?
        info=`grep -iw 'error' $ERROR_INFO`
        if [ x"$info" == x"" ] && [ $status -ne 0 ]
        then
            writeFail "File transfer stability test,IO read and write exception."
            umount $dev_part
            exit 1
        fi

        umount $dev_part
        rm -f $ERROR_INFO
    done

    writePass 
}

function main()
{
    JIRA_ID="PV-926"
    Test_Item="Stable 2GB file transfer"
    Designed_Requirement_ID="R.SAS.N007.A"

    iozne_file_transfer_stability_test
}

main

exit 0

