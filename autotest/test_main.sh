#!/bin/bash

##########################################
# the main entry, use to run all test work.
##########################################

. ./common_lib
. ./common_config.inc

###########################################
# 
#
function main()
{
	if [ ${RUN_SAS} -eq 1 ]; then
	    bash ${SAS_MAIN} 
	fi
}

main
