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
# Author: chenlingfei <liangfei2015@foxmail.com> 


# loading library
. include/auto-test-lib


## Test case definitions
# Run FIO business, the frequent turn off open phy.
function fio_run_phy_frequently_flash()
{
    TEST="fio_run_phy_frequently_flash"
    if [ x"$frequently_phy_addr" = x"" ]
    then 
        fail_test "When the \"fio_run_phy_frequently_flash\" test, the PHY address is empty, \
            exit the test, please check the value of the \"frequently_phy_addr\" parameter, \
            test case execution failed."

        return 1
    fi

    fio -filename=$frequently_fio_disk -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync \
        -bs=512B -numjobs=64 -runtime=$frequently_fio_time -group_reporting -name=mytest 1>$ERROR_INFO 2>&1 &
    while true
    do
        if [ `ps -ef | grep fio | grep -v grep | grep -v vfio-irqfd | wc -l` -eq 0 ]
        then
            break
        fi

        for phy_addr in `echo $frequently_phy_addr | sed 's/|/ /g'`
        do
            devmem2 $phy_addr w 0x06 1>/dev/null 2>&1
            devmem2 $phy_addr w 0x07 1>/dev/null 2>&1
        done
        sleep 10
    done

    info=`grep -iw 'error' $ERROR_INFO`
    if [ x"" != x"" ]
    then
        fail_test " Business is not interrupted, the system is normal, \
            test case execution failed."

        return 1
    fi

    rm -f $ERROR_INFO
    pass_test
}   

# Frequent link reset, disk check
function reset_link_loop()
{
    TEST="reset_link_loop"
    for i in `seq $reset_link_loop_more`
    do
        echo 1 > $loop_rest_link_file
        echo 1 > $loop_rest_hard_file

        sleep 10
        if [ x"`fdisk -l`" = x"" ]
        then
            fail_test "After repeating the reset link, the query disk failed, \
                test case execution failed."

            return 1
        fi
    done
    pass_test
}


# Long time PHY port occupancy test
function fio_long_time_run()
{
    TEST="fio_long_time_run"
    fio -filename=$fio_long_run_disk -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync \
        -bs=512B -numjobs=64 -runtime=$fio_long_run_time -group_reporting -name=mytest 1>$ERROR_INFO 2>&1
    results=$?
    info=`grep -iw 'error' $ERROR_INFO`
    if [ x"" != x"" -a $results -ne 0 ]
    then
        fail_test "fio long time run, fio Abnormal operation, \
            test case execution failed."

        return 1
    fi

    rm -f $ERROR_INFO
    pass_test
}

# Frequently read and write tests on disk
function fio_loop_run()
{
    TEST="fio_loop_run"
    write_log " [INFO ] " "Frequently read and write tests on disk begin."
    for i in `seq $fio_loop_run_more`
    do
        fio -filename=$fio_loop_run_disk -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=4K \
            -numjobs=64 -runtime=$fio_loop_run_time -group_reporting -name=mytest 1>$ERROR_INFO 2>&1
        results=$?
        
        info=`grep -iw 'error' $ERROR_INFO`
        if [ x"$info" != x"" -a $results -ne 0 ]
        then
            fail_test "fio loop ruing, fio Abnormal operation, test case execution failed, \
                test case execution failed."

            return 1
        fi
    done
    
    rm -f $ERROR_INFO
    pass_test
}

# Run the business, repeatedly disk hot plug
function run_business_repeatedly_disk_hot_plug()
{
    TEST="run_business_repeatedly_disk_hot_plug"
    if [ ! -e $hot_plug_disk_enable_file -a ! -e $hot_plug_disk_file ]
    then
        fail_test "'$hot_plug_disk_enable_file' file or '$hot_plug_disk_file' file does not exist, \
            please check the value of the 'hot_plug_disk_enable_file' \
			parameter and 'hot_plug_disk_file' parameter, test case execution failed."

        return 1
    fi

    fio -filename=$hot_plug_disk_file -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=512k \
        -numjobs=10 -runtime=$hot_plug_fio_run_time -group_reporting -name=mytest 1>/dev/null &
    begin_time=`date +%s`
    while true
    do
        if [ `ps -ef | grep fio | grep -v grep | grep -v vfio-irqfd | wc -l` -eq 0 ]
        then
            break
        fi
        
        echo 0 > $hot_plug_disk_enable_file
        sleep 10
        echo 1 > $hot_plug_disk_enable_file
        sleep 10
            
        end_time=`date +%s`
        if [ `expr $end_time-$begin_time` -ge `2*$hot_plug_fio_run_time` ]
        then
            pid=`ps -ef | grep fio | grep -v grep | grep -v vfio-irqfd | awk -F ' ' '{print $2}'`
            kill -9 $pid

            fail_test " IO read and write timeout, can not normally exit, \
                test case execution failed."

            return 1
        fi
    done
    pass_test
}

#
function main()
{
    if [ $is_fio_run_phy_frequently_flash -eq 1 ]
    then
        fio_run_phy_frequently_flash
    fi

    if [ $is_reset_link_loop -eq 1 ]
    then
        reset_link_loop
    fi

    if [ $is_fio_long_time_run -eq 1 ]
    then
        fio_long_time_run
    fi

    if [ $is_fio_loop_run -eq 1 ]
    then
        fio_loop_run
    fi

    if [ $is_run_business_repeatedly_disk_hot_plug -eq 1 ]
    then
        run_business_repeatedly_disk_hot_plug
    fi
}


#######################################################################
#
#
#
#
######################################################################

#echo 8 > /proc/sys/kernel/printk
#cat /proc/sys/kernel/printk 1>/dev/null

if [ -e $INFO_LOG ]
then
    rm -rf $INFO_LOG
fi

# run the tests
main

# clean exit so lava-test can trust the results
exit 0
