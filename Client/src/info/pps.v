module info

import os

pub struct PPS 
{
	pub mut:
		iface		string
		rx			int
		tx 			int

		pps			int
}

pub fn fetch_pps_info(iface string) PPS
{
	mut rx := "cat /sys/class/net/$iface/statistics/rx_packets"
	mut tx := "cat /sys/class/net/$iface/statistics/tx_packets"
	mut t := PPS{
		rx: (os.execute(rx).output).int(),
		tx: (os.execute(tx).output).int()
	}
	return t
}