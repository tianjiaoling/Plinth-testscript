#!/bin/bash

boardNo=6
file=reboot_pci_178_$(date "+%Y%m%d")
nMax=1000
n1=0
while [ ${n1} -lt ${nMax} ]; do
	board_reboot ${boardNo}
	expect -c '
		set boardNo1 '${boardNo}'
		set n1 '${n1}'
		set file '${file}'
		set timeout -1
		spawn board_connect ${boardNo1}
		send "\r"
		expect -re {Press any other key in [0-9]+ seconds to stop automatical booting}
		send "e"
		send "\r"
		expect "login:"
		send "root\r"
		expect "Password:"
		send "root\r"
		expect "ubuntu"

		if {${n1} == 0} {
			send "echo >${file}\r"
		}
		send "echo #####${n1} begin datetime[\$(date \"+%Y%m%d_%H%M%S_%N\")] >>${file}\r"

		send "echo \"lspci:\" >>${file}\r"
		send "lspci >>${file}\r"
		send "echo \"lspci -k:\" >>${file}\r"
		send "lspci -k >>${file}\r"
		send "echo \"devmem 0xa00a0080 #1P NA PCIE2:\" >>${file}\r"
                send "devmem 0xa00a0080 >>${file}\r"
                send "echo \"devmem 0x8a0200080 #1P NB PCIE1:\" >>${file}\r"
                send "devmem 0x8a0200080  >>${file}\r"
                send "echo \"devmem 0x8a0090080 #1P NB PCIE0:\" >>${file}\r"
                send "devmem 0x8a0090080 >>${file}\r"
                send "echo \"devmem 0x600a00a0080 #2P NA PCIE2:\" >>${file}\r"
                send "devmem 0x600a00a0080 >>${file}\r"
                send "echo \"devmem 0x700a0200080 #2P NB PCIE1:\" >>${file}\r"
                send "devmem 0x700a0200080 >>${file}\r"
                send "echo \"devmem 0x700a0090080 #2P NB PCIE0:\" >>${file}\r"
                send "devmem 0x700a0090080 >>${file}\r"
		send "echo \"lspci -tv:\" >>${file}\r"
		send "lspci -tv >>${file}\r"
		send "echo \"lspci -vvv:\" >>${file}\r"
		send "lspci -vvv >>${file}\r"
                send "echo \"lsblk:\" >>${file}\r"
                send "lsblk >>${file}\r"	
		sleep 10\r

		send "echo #####${n1} end   datetime[\$(date \"+%Y%m%d_%H%M%S_%N\")] >>${file}\r"
		expect -re {root@ubuntu:.*#}
		#send "sync\r"
		#expect eof
	'
	let n1+=1
done
