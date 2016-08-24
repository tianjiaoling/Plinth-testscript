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
# GNU General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software 
# Foundation, Inc.,Shenzhen, China
# 
# Author: chenliangfei <liangfei2015@foxmail.com> 



# loading library
. include/auto-test-lib


## Test case definitions
# Disk data comprehensive test.
function disk_data_comprehensive_test()
{
	TEST="disk_data_comprehensive_test"
	if [ ! -e fio -a ! -e $FIO_CONFIG ]
	then
		fail_test "fio and fio.conf file does not exist, \
			test case execution failed."

		return 1
	fi

	for dev in `fdisk -l | grep "Disk" | grep "/dev" | awk '{print $2}' | awk -F: '{print $1}'`
	do
		dev_count=`fdisk -l "$dev" | grep "$dev"|wc -l`
		if [ $dev_count -eq 1 ]
		then
			dev_partition $dev 1>/dev/null
		fi
	
        	for dev_part in `fdisk -l $dev? | grep "Disk" | awk '{print $2}' | awk -F ':' '{print $1}'`
		do
			dev_filename=`echo $dev_part | sed 's#\/#\\\/#g'`
			for bs in "${fio_comprehensive_test_IO_size[@]}"
			do
				sed -i "{s/^bs=.*/bs=$bs/g;s/^filename=.*/filename=$dev_filename/g;\
					s/^runtime=.*/runtime=$fio_comprehensive_test_time/g;}" $FIO_CONFIG
				fio $FIO_CONFIG 1>$ERROR_INFO 2>&1
				status=$?
				info=`grep -iw 'error' $ERROR_INFO`
				if [ x"$info" != x"" -a $status -ne 0 ]
				then
					fail_test "when useing fio to read and write $dev_part partition failed, \
						test case execution failed."

					return 1
				fi
			done
			#		
			echo "y" | mkfs.ext4 $dev_part 1>/dev/null
			mount -t ext4 $dev_part /mnt 1>/dev/null
			temp_info=`mount | grep -w "^$dev_part"`
			if [ x"$temp_info" = x"" ]
			then
				fail_test "Mount "$dev_part" disk failure, \
						test case execution failed."

				return 1
			fi
		
			#
			time dd if=/dev/zero of=/mnt/test.img bs=1M count=15 1>/dev/null
			if [ $? -ne 0 ]
			then
				fail_test "dd tools read data error, \
						test case execution failed."

				return 1
			fi

			#
			init_value=`md5sum /mnt/test.img | awk -F ' ' '{print $1}'`
			for i in $(seq $Disk_file_consistency_test_count)
			do
				cp /mnt/test.img ~/test.img.$i
        			value=`md5sum ~/test.img.$i | awk -F ' ' '{print $1}'`
        			if [ x"$init_value" != x"$value" ]
        			then
                			fail_test "The test.img($init_value) file is not equal to the MD5 value of the ~/test.img.$i($value) file, \
						test case execution failed."

					return 1
        			fi
        			rm -f ~/test.img.$i
			done
			rm -f /mnt/test.img

			#
			umount $dev_part
			temp_info=`mount | grep -w "^$dev_part"`
                        if [ x"$temp_info" != x"" ]
                        then
                                fail_test "Failed to uninstall the "$dev_part" disk, \
						test case execution failed."

				return 1
			fi

			rm -f $ERROR_INFO	
		done
	done

	pass_test
}

# When running the FIO service, the continuous loop reset the narrow link  
function runing_fio_link_reset()
{
	TEST="runing_fio_link_reset"
	if [ x"$runing_fio_link_reset_file_name" = x"" -o ! -e fio ]
	then
		fail_test "Disk link reset file name is empty, \
                        Please check the 'runing_fio_link_reset_file_name' parameters of the configuration file, \
			Or check the current directory 'fio' file is not there, \
                        test case execution failed."

		return 1
	fi

	fio -filename=$runing_fio_link_reset_disk -direct=1 -iodepth 1 -thread -rw=randwrite \
		-ioengine=psync -bs=512B -numjobs=64 -runtime=$runing_fio_link_reset_time \
		-group_reporting -name=mytest 1>$ERROR_INFO 2>&1 &

	while true
	do 

		if [ `ps -ef | grep fio | grep -v grep | grep -v vfio-irqfd | wc -l` -eq 0 ]
		then
			break
		fi
		echo 1 > $runing_fio_link_reset_file_name
		sleep 1
	done
	
	info=`grep -iw 'error' $ERROR_INFO`
	kill_info=`ps | grep "Killed"`
        if [ x"$info" != x"" -o x"$kill_info" != x"" ]
        then
		fail_test "FIO tools to run the exception,  The system runs normally,\
			\"runing_fio_link_reset\" test case execution failed."

		return 1
	fi

	rm -f $ERROR_INFO
	pass_test
}

# When running the FIO service, Loop reset wide connection
function runing_fio_hard_reset()
{
	TEST="runing_fio_hard_reset"
	if [ x"$runing_fio_link_reset_file_name" = x"" -o ! -e fio ]
        then    
                fail_test "Disk link reset file name is empty, \
                        Please check the 'runing_fio_link_reset_file_name' parameters of the configuration file, \
			Or check the current directory 'fio' file is not there, \
                        test case execution failed."

		return 1
        fi

	fio -filename=$dev_file -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=512B \
		-numjobs=64 -runtime=$runing_fio_hard_reset_time -group_reporting -name=mytest 1>$ERROR_INFO 2>&1 &
		
	while true
	do 

		if [ `ps -ef | grep fio | grep -v grep | grep -v vfio-irqfd | wc -l` -eq 0 ]
		then
			break
		fi

		echo 1 > $runing_fio_hard_reset_file_name
		sleep 1
	done
	
	info=`grep -iw 'error' $ERROR_INFO`
	kill_info=`ps | grep "Killed"`
        if [ x"$info" != x"" -o x"$kill_info" != x"" ]
        then
		fail_test "FIO tools to run the exception,  The system runs normally, \
			test case execution failed."

		return 1
        fi

	rm -f $ERROR_INFO
	pass_test
}

# File transfer stability test
function file_transfer_stability_test()
{
	TEST="file_transfer_stability_test"
	if [ x"$file_transfer_stability_test_disk" = x"" -o ! -e iozone ]
	then
		fail_test "File transfer stability test disk is empty, \
			Please check the 'file_transfer_stability_test_disk' parameters of the configuration file, \
			Or check the current directory 'iozone' file is not there, \
			test case execution failed."

		return 1
	fi

	echo "y" | mkfs.ext4 $file_transfer_stability_test_disk 1>/dev/null 2>&1
        mount -t ext4 $file_transfer_stability_test_disk /mnt 1>/dev/null 2>&1
        temp_info=`mount | grep -w "^$file_transfer_stability_test_disk"`

        if [ x"$temp_info" = x"" ]
        then
        	fail_test "Mount "$file_transfer_stability_test_disk" disk failure, \
			test case execution failed."

		return 1
	fi

	iozone -a -n 1g -g 10g -i 0 -i 1 -i 2 -f /mnt/iozone -V 5aa51ff1 1 > $ERROR_INFO 2>&1
	status=$?
        info=`grep -iw 'error' $ERROR_INFO`
	if [ $status -ne 0 -a x"$info" != x"" ]
	then
		fail_test "File transfer stability test, IO read and write exception, \
			test case execution failed."

		return 1
	fi

	umount $file_transfer_stability_test_disk
	rm -f $ERROR_INFO

	pass_test
}

#
function main()
{
	if [ $is_disk_data_comprehensive_test -eq 1 ]
	then
		disk_data_comprehensive_test
	fi

	if [ $is_runing_fio_link_reset -eq 1 ]
	then
		runing_fio_link_reset
	fi

	if [ $is_runing_fio_hard_reset -eq 1 ]
	then
		runing_fio_hard_reset
	fi

	if [ $is_file_transfer_stability_test -eq 1 ]
	then
		file_transfer_stability_test
	fi
}

#################################################################
#
#
#
#
#################################################################

#echo 8 > /proc/sys/kernel/printk
#cat /proc/sys/kernel/printk 1>/dev/null

if [ -e $INFO_LOG ]
then
	rm -f $INFO_LOG
fi

# run the tests
main

# clean exit so lava-test can trust the results
exit 0

