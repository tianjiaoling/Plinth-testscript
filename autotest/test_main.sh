#!/bin/bash

###########################################
# the main entry, use to run all test work.
###########################################

THIS_FILE_DIR=`dirname $0`
if [ `echo "$0" | grep -c "/" ` -le 0 ]; then
    THIS_FILE_DIR= `pwd`
	
. ${THIS_FILE_DIR}/common_lib
. ${THIS_FILE_DIR}/common_config.inc

###########################################
function update_image()
{
    SERVER_SFTP_DIR=~/sftp
	cp ${IMAGE_FILE} ${SERVER_SFTP_DIR}
	[ $? != 0 ] && echo "Update Image failed." && return 1
}


###########################################
#  connect the board and run test script
#  IN: $1 board no
#      $2 login user
#      $3 login password
#      $4 server user
#      $5 server password
#      $6 test run script       
#  OUT: N/A
function board_run()
{
    board_reboot $1
	[ $? != 0 ] && echo "board reboot failed." && return 1
	
	expect -c '
	        set boardno '$1'
			set user '$2'
			set passwd '$3'
			set autotest_zip '${AUTOTEST_ZIP_FILE}'
			spawn board_connect ${boardno}
			send "\r"
		    expect -re {Press any other key in [0-9]+ seconds to stop automatical booting}
			send "e"
		    send "\r"
		    expect "login:"
		    send "${user}\r"
		    expect "Password:"
		    send "${passwd}\r"
			expect ".*#"
			
			# cp test script from server
			set server_user '$4'
			set server_passwd '$5'
		    send "scp ${server_user}@${SERVER_IP}:~/${autotest_zip} ~/\r"
			expect "Are you sure you want to continue connecting (yes/no)?"
			send "yes\r"
			
			expect "password:"
			send "${server_passwd}\r"
			
			expect "@.*#"
			send "tar -zxvf ${autotest_zip}\r"
			
			set test_run_script '$6'
			expect "@.*#"
			send "cd autotest;bash -x ${test_run_script}"
	'
}

###########################################
# 
#
function main()
{	
	#update_image
	
	AUTOTEST_ZIP_FILE=autotest.tar.gz
	cd ~/
	tar -zcvf  ${AUTOTEST_ZIP_FILE} autotest
	[ $? != 0 ] && echo "tar test script failed." && return 1
	
	if [ ${RUN_SAS} -eq 1 ]; then
	    board_run ${SAS_BORADNO} ${SAS_REMOTE_USER} ${SAS_REMOTE_PASSWD} ${SAS_SERVER_USER} ${SAS_SERVER_PASSWD} ${SAS_MAIN}
	fi
}

main
