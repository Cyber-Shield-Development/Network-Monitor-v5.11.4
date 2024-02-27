module info

import os
import time

const packet_path = "/sys/class/net/{interface}/statistics/{mode}_packets"

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
	rx_f := packet_path.replace("{interface}", iface).replace("{mode}", "rx")
	tx_f := packet_path.replace("{interface}", iface).replace("{mode}", "tx")
	return PPS{
		rx: (os.read_file(rx_f) or { "" }).int(),
		tx: (os.read_file(tx_f) or { "" }).int()
	}
}