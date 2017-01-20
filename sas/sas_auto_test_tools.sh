#!/bin/bash

# 
# SAS test cases for Plinth
# 
# Copyright (C) 2016 - 2020, chenliangfei Limited. 
# 
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either version 2 
# of the License, or (at your option) any later version. 
# 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software 
# Foundation, Inc.,Shenzhen, China
# 
# Author: chenliangfei <liangfei2015@foxmail.com> 

# loading library
. include/auto_test_lib



## 1-ATA and NCQ key words query
function key_words_query()
{
    TEST="key_words_query"

    flag=0
    ATA_info=`dmesg | grep ATA`
    NCQ_info=`dmesg | grep NCQ`

    if [ x"ATA_$info" == x"" ]
    then
        flag=1
        fail_test "Get information ATA failed."
    fi
    if [ x"$NCQ_info" == x"" ]
    then
        flag=1
        fail_test "Get information NCQ failed."
    fi

    if [ $flag -eq 1 ]
    then
        return 1
    fi
    pass_test
}

## 2-Disk negotiated link rate query 
function disk_negotiated_link_rate_query()
{
    TEST="disk_negotiated_link_rate_query"
 
    for dir in `ls ${PHY_FILE_PATH}`
    do
        str=`cat ${PHY_FILE_PATH}/${dir}/device_type`
        if [ x"$str" == x"end device" ]
        then
            rate_value=`cat ${PHY_FILE_PATH}/${dir}/negotiated_linkrate | awk -F '.' '{print $1}'`
            BRate=1
            for rate in `echo $DISK_NEGOTIATED_LINKRATE_VALUE | sed 's/|/ /g'`
            do
                if [ $rate_value -eq $rate ]
                then
                    BRate=0
                    break
                fi
            done

            if [ $BRate -eq 1 ]
            then
                fail_test "negotiated link rate query ERROR, 
                \"disk_negotiated_link_rate_query\" \"disk_negotiated_link_rate_query\"."

                return 1
            fi
        fi
    done

    pass_test   
}

## 3-Wide link reset
function hard_reset()
{
    TEST="hard_reset"
  
    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    change_sas_phy_file 1 "hard_reset"
    count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`

    fdisk_query
    status=$?
    if [ $status -eq 1 ] || [ $count_init -ne $count_curr ]
    then
        fail_test "Disk wide connection reset ERROR."
        return 1
    fi

    pass_test
}

## 4-Narrow link reset
function link_reset()
{
    TEST="link_reset"
    
    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    change_sas_phy_file 1 "link_reset"
    count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
    fdisk_query

    status=$?
    if [ $status -eq 1 ] || [ $count_init -ne $count_curr ]
    then
        fail_test "Disk narrow connection reset ERROR"
        return 1
    fi

    pass_test
}

## 5-loop narrow link reset.
function reset_link_loop()
{
    TEST="reset_link_loop"

    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for i in `seq $LOOP_RUN_MORE`
    do
        change_sas_phy_file 1 "link_reset"
        count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`

        fdisk_query
        status=$?
        if [ $status -eq 1 ] || [ $count_init -ne $count_curr ]
        then
            fail_test "loop narrow link reset, disk check failed."
            return 1
        fi
    done

    pass_test
}

## 6-loop Wide link reset.
function reset_hard_loop()
{
    TEST="reset_hard_loop"

    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for i in `seq $LOOP_RUN_MORE`
    do
        change_sas_phy_file 1 "hard_reset"
        count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`

        fdisk_query
        status=$?
        if [ $status -eq 1 ] || [ $count_init -ne $count_curr ]
        then
            fail_test "loop Wide link reset, disk check failed."
            return 1
        fi
    done

    pass_test
}

## 7-loop enable disk.
function loop_enable_disk()
{
    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for i in `seq $LOOP_RUN_MORE`
    do
        change_sas_phy_file 0 "enable"
        change_sas_phy_file 1 "enable"
        count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`

        fdisk_query
        status=$?
        if [ $status -eq 1 ] || [ $count_init -ne $count_curr ]
        then
            fail_test "loop enable disk, disk check failed."
            return 1
        fi
    done
}

#
function reset_phy_file()
{
    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        for rw in "${FIO_RW[@]}"
        do
            echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
            sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;}" $TEMPFIO_CONFIG
            ./fio $TEMPFIO_CONFIG > $ERROR_INFO &
                
            for i in `seq $EXEC_COMMAND_NUM`
            do 
                change_sas_phy_file $1 $2
            done

            wait
            info=`grep -iw 'error' $ERROR_INFO`
            count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
            if [ x"$info" == x"" ] || [ $count_init -ne $count_curr ]
            then
                rm -f $ERROR_INFO
                return 1
            fi
        done
    done 

    rm -f $ERROR_INFO
    return 0
}

## 8-When running FIO business, the continuous loop reset the narrow link.  
function runing_fio_link_reset()
{
    TEST="runing_fio_link_reset"

    reset_phy_file 1 "link_reset"
    status=$?
    if [ $status -eq 1 ]
    then
        fail_test "Continuous loop reset of a narrow link fails when running FIO services."
        return 1
    fi
    pass_test
}

## 9-When running FIO business, the continuous Loop reset wide link.
function runing_fio_hard_reset()
{
    TEST="runing_fio_hard_reset"

    reset_phy_file 1 "hard_reset"
    status=$?
    if [ $status -eq 1 ]
    then
        fail_test "Continuous loop reset of a wide link fails when running FIO services"
        return 1
    fi
    pass_test
}

## 10-When running FIO business, enable Disconnect disk.
function fio_run_enable_disk()
{
    TEST="fio_run_close_all_phy"

    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        for rw in "${FIO_RW[@]}"
        do
            echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
            sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;}" $TEMPFIO_CONFIG
            ./fio $TEMPFIO_CONFIG > $ERROR_INFO &
                
            change_sas_phy_file 0 "enable"
            wait

            info=`grep -iw 'error' $ERROR_INFO`
            count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
            if [ x"$info" == x"" ] || [ $count_init -ne $count_curr ]
            then
                rm -f $ERROR_INFO
                change_sas_phy_file 1 "enable"
                fail_test "When you run the FIO tool,enable disconnects the disk connection fail."
                return 1
            fi
            change_sas_phy_file 1 "enable"
        done
    done 

    rm -f $ERROR_INFO
    pass_test
}

## 11-When running FIO business, repeatedly disk hot plug
function run_business_repeatedly_disk_enable()
{
    TEST="run_business_repeatedly_disk_enable"

    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        for rw in "${FIO_RW[@]}"
        do
            echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
            sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;}" $TEMPFIO_CONFIG
            ./fio $TEMPFIO_CONFIG > $ERROR_INFO &
                
            for i in `seq $EXEC_COMMAND_NUM`
            do   
                change_sas_phy_file 0 "enable"
                change_sas_phy_file 1 "enable"
            done

            wait
            info=`grep -iw 'error' $ERROR_INFO`
            count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
            if [ x"$info" == x"" ] || [ $count_init -ne $count_curr ]
            then
                rm -f $ERROR_INFO
                fail_test "When running the FIO tool, looping on enable to close the enable disk failed."
                return 1
            fi
        done
    done 

    rm -f $ERROR_INFO
    pass_test
}

## 12-When running FIO business, close all phy.
function fio_run_close_all_phy()
{
    TEST="fio_run_close_all_phy"
    
    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        for rw in "${FIO_RW[@]}"
        do
            echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
            sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;}" $TEMPFIO_CONFIG
            ./fio $TEMPFIO_CONFIG > $ERROR_INFO &
                
            close_all_phy

            wait
            count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
            info=`grep -iw 'error' $ERROR_INFO`
            if [ x"$info" == x"" -o $count_init -ne $count_curr ]
            then
                rm -f $ERROR_INFO
                open_all_phy
                fail_test "When running FIO business, close all phy failed."

                return 1
            fi
            open_all_phy
            sleep 5
        done
    done 

    rm -f $ERROR_INFO
    pass_test
}

## 13-When running FIO business, the frequent turn off open phy.
function fio_run_phy_frequently_flash()
{
    TEST="fio_run_phy_frequently_flash"

    count_init=`fdisk -l | grep "Disk identifier:" | wc -l`
    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        for rw in "${FIO_RW[@]}"
        do
            echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
            sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;}" $TEMPFIO_CONFIG
            ./fio $TEMPFIO_CONFIG > $ERROR_INFO &
                
            for i in `seq $EXEC_COMMAND_NUM`
            do                 
                close_all_phy
                sleep 2
                open_all_phy
                sleep 2
            done

            wait
            info=`grep -iw 'error' $ERROR_INFO`
            count_curr=`fdisk -l | grep "Disk identifier:" | wc -l`
            if [ x"$info" == x"" -o $count_init -ne $count_curr ]
            then
                rm -f $ERROR_INFO
                fail_test "When running FIO business, the frequent turn off open phy failed."
                return 1
            fi
        done
    done 

    rm -f $ERROR_INFO
    pass_test
}

## 14-Close and open the phy, check the disk output information.
function inquire_open_phy_info()
{
    TEST="inquire_open_phy_info"

    open_init_number=`dmesg | grep -w "Write\ Protect\ is\ off" | wc -l`
    close_init_numbe=`dmesg | grep -w "found\ dev" | wc -l`

    close_all_phy
    open_all_phy
    
    #Waiting for phy open successfully.
    sleep 10

    open_curr_number=`dmesg | grep -w "Write\ Protect\ is\ off" | wc -l`
    close_curr_number=`dmesg | grep -w "found\ dev" | wc -l`

    if [ $open_init_number -eq $open_curr_number ] || [ $close_init_number -eq $close_curr_number ]
    then
        fail_test "phy value close, dmesg has no 'Write Protect is off' or 'found dev' info."
        return 1
    fi

    pass_test
}

## 15-File transfer stability test
function file_transfer_stability_test()
{
    TEST="file_transfer_stability_test"

    for dev_part in ${ALL_DISK_PART_NAME[*]}
    do
        echo "y" | mkfs.ext4 $dev_part 1>/dev/null 2>&1
        mount -t ext4 $dev_part /mnt 1>/dev/null 2>&1
        temp_info=`mount | grep -w "^$dev_part"`

        if [ x"$temp_info" == x"" ]
        then
            fail_test "Mount "$dev_part" disk failure."
            return 1
        fi

        ./iozone -a -n 1g -g 10g -i 0 -i 1 -i 2 -f /mnt/iozone -V 5aa51ff1 1 > $ERROR_INFO 2>&1
        status=$?
        info=`grep -iw 'error' $ERROR_INFO`
        if [ x"$info" == x"" ] && [ $status -ne 0 ]
        then
            fail_test "File transfer stability test,IO read and write exception."
            umount $dev_part
            return 1
        fi

        umount $dev_part
        rm -f $ERROR_INFO
    done

    pass_test
}

## 16-The FIO tool loops through the disk read and write
function fio_loop_run()
{
    TEST="fio_loop_run"

    for i in `seq $LOOP_RUN_MORE`
    do
        for dev in ${ALL_DISK_PART_NAME[*]}
        do
            dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
            for rw in "${FIO_RW[@]}"
            do
               echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
               sed -i "{s/^filename=.*/filename=$dev_filename/g;s/^rw=.*/rw=$rw/g;\
               s/^runtime=.*/runtime=$LOOP_RUN_TIME/g;}" $TEMPFIO_CONFIG
               ./fio $TEMPFIO_CONFIG > $ERROR_INFO

               results=$?
               info=`grep -iw 'error' $ERROR_INFO`
               if [ x"$info" != x"" ] && [ $results -ne 0 ]
               then
                    rm -f $ERROR_INFO
                    fail_test "fio loop ruing, fio Abnormal operation."
                    return 1
               fi
            done
        done
    done

    rm -f $ERROR_INFO
    pass_test
}

## 17-Disk read and write for a long time
function fio_long_time_run()
{
    TEST="fio_long_time_run"

    for dev in ${ALL_DISK_PART_NAME[*]}
    do
        dev_filename=`echo $dev | sed 's#\/#\\\/#g'`
        echo "$FIO_PARAMETER_LIST" > $TEMPFIO_CONFIG
        sed -i "{s/^filename=.*/filename=$dev_filename/g;\
        s/^runtime=.*/runtime=$FIO_LONG_RUN_TIME/g;}" $TEMPFIO_CONFIG
        ./fio $TEMPFIO_CONFIG > $ERROR_INFO
         
        results=$?
        info=`grep -iw 'error' $ERROR_INFO`
        if [ x"$info" != x"" ] && [ $results -ne 0 ]
        then
            rm -f $ERROR_INFO
            fail_test "fio long time run, fio Abnormal operation."
            return 1
        fi
    done

    rm -f $ERROR_INFO
    pass_test
}

## 18-Disk data comprehensive test.
function disk_data_comprehensive_test()
{
    TEST="disk_data_comprehensive_test"

    if [ ! -e $FIO_CONFIG ]
    then
        fail_test "fio and fio.conf file does not exist."
        return 1
    fi

    for disk_name in ${ALL_DISK_PART_NAME[*]}
    do
        #       
        echo "y" | mkfs.ext4 $disk_name 1>/dev/null
        mount -t ext4 $disk_name /mnt 1>/dev/null
        temp_info=`mount | grep -w "^$disk_name"`
        if [ "$temp_info" = x"" ]
        then
            fail_test "Mount "$disk_name" disk failure."
            return 1
        fi
        
        #
        time dd if=/dev/zero of=/mnt/test.img bs=10M count=200 conv=fsync 1>/dev/null
        if [ $? -ne 0 ]
        then
            umount $disk_name
            fail_test "dd tools read data error."
            return 1
        fi

        #
        init_value=`md5sum /mnt/test.img | awk -F ' ' '{print $1}'`
        for i in `seq $LOOP_RUN_MORE`
        do
            cp /mnt/test.img ~/test.img.$i
            value=`md5sum ~/test.img.$i | awk -F ' ' '{print $1}'`
            if [ x"$init_value" != x"$value" ]
            then
                rm -f /mnt/test.img
                umount $disk_name
                fail_test "The test.img($init_value) file is not equal to the MD5 value of the ~/test.img.$i($value) file."
                return 1
            fi
            rm -f ~/test.img.$i
        done
        rm -f /mnt/test.img
        #
        umount $disk_name
        temp_info=`mount | grep -w "^$disk_name"`
        if [ x"$temp_info" != x"" ]
        then
            fail_test "Failed to uninstall the "$disk_name" disk."
            return 1
        fi

        #
        dev_filename=`echo $disk_name | sed 's#\/#\\\/#g'`
        for bs in "${FIO_BS[@]}"
        do
            sed -i "{s/^bs=.*/bs=$bs/g;s/^filename=.*/filename=$dev_filename/g;\
            s/^runtime=.*/runtime=$fio_comprehensive_test_time/g;}" $FIO_CONFIG
            ./fio $FIO_CONFIG 1>$ERROR_INFO 2>&1
            status=$?
            info=`grep -iw 'error' $ERROR_INFO`
            if [ x"$info" != x"" ] && [ $status -ne 0 ]
            then
                fail_test "when useing fio to read and write $disk_name partition failed."
                rm -f $ERROR_INFO 
                return 1
            fi
        done
        rm -f $ERROR_INFO   
    done

    pass_test
} 

# 
function output_info()
{
    clear
    echo
    echo
    echo
    echo "***********************Welcome to the SAS Automated Test Tool************************"
    echo "[1]    ATA and NCQ key words query test."
    echo "[2]    Disk negotiated link rate query test."
    echo "[3]    Wide link reset test."
    echo "[4]    Narrow link reset test."
    echo "[5]    loop narrow link reset."
    echo "[6]    loop Wide link reset."
    echo "[7]    loop enable disk."
    echo "[8]    When running FIO business, the continuous loop reset the narrow link."
    echo "[9]    When running FIO business, the continuous Loop reset wide link."
    echo "[10]   When running FIO business, enable Disconnect disk."
    echo "[11]   When running FIO business, repeatedly disk hot plug"
    echo "[12]   When running FIO business, close all phy."
    echo "[13]   When running FIO business, the frequent turn off open phy."
    echo "[14]   Close and open the phy, check the disk output information."
    echo "[15]   File transfer stability test."
    echo "[16]   The FIO tool loops through the disk read and write."
    echo "[17]   Disk read and write for a long time."
    echo "[18]   Disk data comprehensive test."
    echo "[ALL]  Run all test cases."
    echo "[exit] Exit the automated test tool."
    echo "************************************************************************************"
    echo -e "input[1-18 | ALL | exit]: \c"
}




## main
# Gets all the disk partition names
get_all_disk_part

while :
do
    output_info
    read option

    case "$option" in
        [1-9]|[1-1][0-8])
            ${cases_arrary[$option]}
            read
            ;;
        "ALL" | "all")
            index=1
            while [ $index -le "${#cases_arrary[*]}" ]
            do
                # Check the test environment
                fdisk_query
                status=$?
                if [ $status -eq 1 ]
                then
                    fail_test "When executing an ${cases_arrary[$index]} test case,The test environment \
                    checks that there is no disk, exit the test."
                    exit 1
                fi

                ${cases_arrary[$index]}
                let index=$index+1
            done
            ;;
        "exit")
            echo "Exit the automated test tool."
            break
            ;;
        * )
            echo -e "Input parameters are wrong, please choose whether to exit the test (y / n): \c"
            while :
            do
                read decide
                if [ x"$decide" = x"y" -o x"$decide" = x"n" ]
                then
                    break
                fi
                echo -e "Input errors, please re-enter(y / n): \c"
            done
        
            if [ x"$decide" = x"y" ]
            then
                echo "Exit the automated test tool."
                break
            fi
            continue
            ;;
    esac
done

# clean exit so lava-test can trust the results
exit 0

