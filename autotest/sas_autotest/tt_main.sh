#!/bin/bash

declare -A case_map=(
["tt02"]="true"   #fdsfsdfsd   
["tt03"]="true"  #dfsfsdfsd
)

for key in "${!case_map[@]}"
do
   if [ x"${case_map[$key]}" = x"true" ]
   then
       commd="${key}.sh"
       source $commd
   fi
done
