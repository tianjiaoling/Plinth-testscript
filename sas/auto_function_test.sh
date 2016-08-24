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
. include/auto-test-lib


## Test case definitions
# Turn off and turn on the PHY port to check if there is a disk log output
function inquire_open_close_phy_info()
{
	TEST="inquire_open_close_phy_info"
	open_init_number=`dmesg | grep -w "Write\ Protect\ is\ off" | wc -l`

	close_all_phy
	open_all_phy
	
	#Waiting for phy open successfully.
	sleep 60

	open_curr_number=`dmesg | grep -w "Write\ Protect\ is\ off" | wc -l`
	close_curr_number=`dmesg | grep -w "found\ dev" | wc -l`
	

	if [ $open_init_number -eq $open_curr_number ]
    then
		fail_test "phy value close, dmesg has no 'Write Protect is off' info, \
			test case execution failed."
		
		return 1
    fi

	if [ $close_init_number -eq $close_curr_number ]
	then
		fail_test "phy value close, dmesg has no 'found dev' info, \
			test case execution failed."
		
		return 1
    fi	

	fdisk_query
	pass_test
}


# Wide link reset
function hard_reset()
{
	TEST="hard_reset"
	if [ x"$hard_reset_file_name" = x"" ]
	then
		fail_test "Disk wide connection file is empty,\
			Please check the 'link_reset_file_name' parameters of the configuration file, \
			test case execution failed."
			
		return 1
	fi
	
	echo 1 > $hard_reset_file_name 1>/dev/null
	if [ $? -ne 0 ]
	then
		fail_test "Disk wide connection reset ERROR, \
			test case execution failed."
		
		return 1
	fi
	
	fdisk_query
	pass_test


# Narrow link reset
function link_reset()
{
	TEST="link_reset"
	if [ x"$link_reset_file_name" = x"" ]
	then
		fail_test "Disk narrow connection file is empty, \
			Please check the 'link_reset_file_name' parameters of the configuration file, \
			test case execution failed."
			
			return 1
	fi
	
	echo 1 > $link_reset_file_name 1>/dev/null
	if [ $? -ne 0 ]
	then
		fail_test "Disk narrow connection reset ERROR, \
			test case execution failed."
		
		return 1
	fi
	
	fdisk_query
	pass_test
}


# disk negotiated link rate query 
function disk_negotiated_link_rate_query()
{
	TEST="disk_negotiated_link_rate_query"
	if [ x"$disk_negotiated_link_rate_file_name" = x"" ]
	then
		fail_test "negotiated link rate file name is empty, \
			Please check the 'disk_negotiated_link_rate_file_name' \
			parameters of the configuration file, test case execution failed."
		
		return 1
	fi
		
	rate_value=`cat $disk_negotiated_link_rate_file_name | awk -F '.' '{print $1}'`
	BRate=0
	for rate in `echo $disk_negotiated_link_rate_value | sed 's/|/ /g'`
	do
		if [ $rate_value -eq $rate ]
		then
			BRate=1
			break
		fi
	done
	
	if [ $BRate -eq 1 ]
	then
		fail_test "negotiated link rate query ERROR, \"disk_negotiated_link_rate_query\" \
			\"disk_negotiated_link_rate_query\" test case execution failed."
		
		return 1
	fi
	
	pass_test
	
}


#
function mod_version_query()
{
	TEST="mod_version_query"
	if [ ! -e $mod_main_file]
	then
		fail_test "$mod_main_file Module file does not exist, \
			test case execution failed."
		
		return 1
	fi
	info=`modinfo $mod_main_file | grep vermagic: | awk -F ' ' '{print $2}' | awk -F '-' '{print $1}'`
	
	if [ x"$info" != x"$mod_version" ]
	then
		fail_test " Driver version information is not consistent with the actual release version, \
			Check the correctness of the 'mod_version' configuration item value of the configuration file, \
			test case execution failed."
		
		return 1
	fi
	
	pass_test
}

#
function rmmod_module()
{
	TEST="rmmod_module"
	if [ -e $mod_v1_file -a -e $mod_v2_file -a -e $mod_main_file ]
	then
		fail_test  "$mod_v1_file|$mod_v2_file|$mod_main_file Module file does not exist,Exit test, \
			test case execution failed."	
		
		return 1
	fi

	rmmod $mod_v2_file 1>/dev/null 2>&1
    rmmod $mod_v1_file 1>/dev/null 2>&1
    rmmod $mod_main_file 1>/dev/null 2>&1

	mod_file_name=`echo $mod_main_file | awk -F '.' '{print $1}'`
	cmd_info=`lsmod | grep -w $mod_file_name`
	if [ x"$cmd_info" != x"" ]
	then
        fail_test "System uninstall module failed,Exit \"rmmod_module\" test, \
			test case execution failed."
		
		return 1
	fi
	
	pass_test
}

#
function insmod_and_rmmod_module()
{
	TEST="insmod_and_rmmod_module"
	if [ ! -e $mod_v1_file -a ! -e $mod_v2_file -a ! -e $mod_main_file ]
    then
        fail_test "$mod_v1_file|$mod_v2_file|$mod_main_file Module file does not exist,Exit test, \
			test case execution failed."
            
		return 1
    fi

	insmod $mod_main_file 1>/dev/null 2>&1
    insmod $mod_v1_file 1>/dev/null 2>&1
    insmod $mod_v2_file 1>/dev/null 2>&1
		
    cmd_info=`lsmod | grep -w "hisi_sas_main"`
    if [ x"$cmd_info" = x"" ]
    then
        fail_test "System loading module failed,Exit test, \
				test case execution failed."
				
		return 1
    fi
		
	fdisk_query
    pass_test
		
	mod_version_query
		
	rmmod_module
}
 
# ATA and NCQ key words query
function Key_words_query()
{
	TEST="Key_words_query"
	info=`dmesg | grep ATA`
	if [ x"$info" == x"" ]
	then
		fail_test "Get information ATA failed, test case execution failed."
	
		return 1
	fi
	
	info=`dmesg | grep NCQ`
	if [ x"$info" == x"" ]
	then
		fail_test "Get information NCQ failed, test case execution failed."
		
		return 1
	fi
	pass_test
}

#
function main()
{
	if [ $is_link_reset -eq 1 ]
	then
		link_reset
	fi

	if [ $is_hard_reset -eq 1 ]
	then
		hard_reset
	fi
	
	if [ $is_insmod_and_rmmod_module -eq 1 ]
	then
		insmod_and_rmmod_module
	fi

	if [ $is_Key_words_query -eq 1 ]
	then
		Key_words_query
	fi
	
	if [ $is_inquire_open_close_phy_info -eq 1 ]
	then
		inquire_open_close_phy_info
	fi
}

#########################################################
#
#
#
#
#########################################################

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

