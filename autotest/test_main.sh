#!/bin/bash

###########################################
# the main entry, use to run all test work.
###########################################


# Load configuration file
. config/common_lib

# Update boot Image file
# IN : N/A
# OUT: N/A
function update_image()
{
    [ ! -e ${IMAGE_FILE} ] && echo "${IMAGE_FILE} file does not exist, do not update the Image file" && return 1
    cp ${IMAGE_FILE} ${IMAGE_DIR_PATH}
    [ $? != 0 ] && echo "Update Image failed." && return 1
}

# connect the board and run test script
# IN : $1 board no
#      $2 test run script
# OUT: N/A
function board_run()
{
    board_reboot $1
    [ $? != 0 ] && echo "board reboot failed." && return 1
	
    expect -c '
        set timeout -1
        set boardno '$1'
	set user '$SYSTEM_USER'
	set passwd '$SYSTEM_PASSWD'
	set server_user '$SERVER_USER'
	set server_passwd '$SERVER_PASSWD'
	set test_run_script '$2'
        set SERVER_IP '$SERVER_IP'
	set autotest_zip '${AUTOTEST_ZIP_FILE}'
        set report_path '${REPORT_PATH}'
	spawn board_connect ${boardno}
	send "\r"
	expect -re {Press any other key in [0-9]+ seconds to stop automatical booting}
	send "\r"
	send "\r"
	expect "login:"
	send "${user}\r"
	expect "Password:"
	send "${passwd}\r"
	expect ".*#"
			
	# cp test script from server
        send "rm -f ~/.ssh/known_hosts\r"
	send "scp ${server_user}@${SERVER_IP}:~/${autotest_zip} ~/\r"
	expect "Are you sure you want to continue connecting (yes/no)?"
	send "yes\r"
		
	expect "password:"
	send "${server_passwd}\r"
		
	expect ".*#"
	send "tar -zxvf ${autotest_zip}\r"
	expect ".*#"
	send "cd ~/autotest;bash -x ${test_run_script}\r"
	expect -re ":.*#"
        send "scp report/report.csv ${server_user}@${SERVER_IP}:${report_path}\r"
	expect "password:"
	send "${server_passwd}\r"
	expect -re ":.*#"
        send "cd ~;rm -rf ~/autotest;rm -rf ${autotest_zip}\r"
	expect -re ":.*#"
    '
}

# Main operation function
# IN : N/A
# OUT: N/A
function main()
{	
    #update_image
    update_image

    cd ~/
    tar -zcvf  ${AUTOTEST_ZIP_FILE} autotest
    [ $? != 0 ] && echo "tar test script failed." && return 1

    #Output log file header
    echo "Module Name,JIRA ID,Test Item,Test Case Title,Test Result,Remark" > ${REPORT_PATH}/${REPORT_FILE}

    #SAS Module Main function call
    [ ${RUN_SAS} -eq 1 ] && board_run ${SAS_BORADNO} ${SAS_MAIN} &
    #PXE Module Main function call
    [ ${RUN_PXE} -eq 1 ] && board_run ${PXE_BORADNO} ${PXE_MAIN} &
    #PCIE Module Main function call
    [ ${RUN_PCIE} -eq 1 ] && board_run ${PCIE_BORADNO} ${PCIE_MAIN} &	

    # Wait for all background processes to end
    wait
}

main

# clean exit so lava-test can trust the results
exit 0

