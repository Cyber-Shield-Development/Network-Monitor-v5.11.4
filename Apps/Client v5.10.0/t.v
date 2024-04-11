import os
import time

fn main()
{
	old_rx := (os.read_file("/sys/class/net/ens3/statistics/rx_packets") or { "" }).int()
	old_tx := (os.read_file("/sys/class/net/ens3/statistics/tx_packets") or { "" }).int()
	time.sleep(1*time.second)
	new_rx := (os.read_file("/sys/class/net/ens3/statistics/rx_packets") or { "" }).int()
	new_tx := (os.read_file("/sys/class/net/ens3/statistics/tx_packets") or { "" }).int()

	inbound_pps := new_rx - old_rx
	outbound_pps := new_tx - old_tx
	
	print("${pps}")
}