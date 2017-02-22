#!/bin/bash

# Load common function
. config/sas_test_lib

# Get all disk partition information
get_all_disk_part

# main
for key in "${!case_map[@]}"
do
   if [ x"${case_map[$key]}" = x"on" ]
   then
       commd="${key}.sh"
       source $TEST_CASE_PATH/$commd
   fi

   case "${case_map[$key]}" in
       on)
           commd="${key}.sh"
           source $TEST_CASE_PATH/$commd
       ;;
       off)
       ;;
       *)
           echo "sas_test_config file test case flag parameter configuration error."
           echo "please configure on and off."
           echo "on  - open test case."
           echo "off - close test case."
       ;;
done
