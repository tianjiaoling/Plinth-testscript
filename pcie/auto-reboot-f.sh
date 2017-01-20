#!/bin/bash

file=reboot_f_pci_$(date "+%Y%m%d")

board_reboot 6
expect -c '
	set timeout -1
	set file '${file}'
	set nMax 1000
	set n1 0
	spawn board_connect 6
	send "\r"
	while {${n1} < ${nMax}} {
		expect -re {Press any other key in [0-9]+ seconds to stop automatical booting}
		send "e"
		send "\r"
		expect "login:"
		send "root\r"
		expect "Password:"
		send "root\r"
		expect -re {root@ubuntu:.*#}
		if {${n1} == 0} {
			send "echo >${file}\r"
		}
		send "echo \"lspci:\" >>${file}\r"
                send "lspci &>>${file}\r"
                send "echo \"lspci -k:\" >>${file}\r"
                send "lspci -k &>>${file}\r"
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
                send "lspci -vvv &>>${file}\r"
		sleep 10
                send "echo \"lsblk:\" >>${file}\r"
                send "lsblk >>${file}\r"
		sleep 10
		send "echo \"#############reboot${n1}##################\" >>${file}\r"
		expect -re {root@ubuntu:.*#}
		send "reboot -f\r"
		incr n1 +1
	}
	#send "sync\r"
	#expect eof
'
