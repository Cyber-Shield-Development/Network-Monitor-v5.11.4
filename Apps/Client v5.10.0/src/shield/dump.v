module shield

import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub struct Dump
{
	pub mut:
		interfacee			string
		interface_ip 		string
		location 			string
		isp 				string
		current_pps 		int
		max_pps_reached		int
		current_cons 		int
		cons_count 			int
		max_cons_reeached 	int

		blocked_cons 		[]ns.NetstatCon
		blocked_t2_cons 	[]td.TCPDump
		dropped_cons 		[]ns.NetstatCon
		abused_ports 		[]string

		captured_pkt_data 	map[string]string
		/*
		* {
		*	"current_time": ["PPS", "CON_COUNT", "ATTACKED_PORT", "EXTERNAL_IP", "EXTERNAL_PORT"]
		* }
		*/
		ip_logs 			map[string][]string
		start_time 			string
		end_time 			string
}

pub fn start_new_dump(iface string, ip string, locate string, isp string, stime string) Dump 
{
	return Dump{
		interfacee: iface,
		interface_ip: ip,
		location: locate,
		isp: isp,
		blocked_cons: []ns.NetstatCon{},
		abused_ports: []string{},
		captured_pkt_data: map[string]string{},
		ip_logs: map[string][]string{},
		start_time: stime
	}
}

/*
*	[@DOC]
*	pub fn (mut d Dump) append_pkt_data(ip string, pkt_data string)
*
*	- Append packet data to the general list of packet data inbound
*/
pub fn (mut d Dump) append_pkt_data(ip string, pkt_data string)
{ d.captured_pkt_data["${ip}"] = pkt_data }

/*
*	[@DOC]
*	pub fn (mut d Dump) is_con_blocked(ip string) bool 
*
*	- Validate if an IP has been blocked in the filter system
*/
pub fn (mut d Dump) is_con_blocked(mut con_chk ns.NetstatCon) bool 
{
	for mut con in d.blocked_cons {
		if con.external_ip == con_chk.external_ip { return true }
	}

	d.block_con(mut con_chk)
	return false
}

/*
*	[DOC]
*	pub fn (mut d Dump) is_con_blocked2(ip string) bool
*
*	- Validate if an IP has been blocked in the advanced filter system
*/
pub fn (mut d Dump) is_con_blocked2(mut con_chk td.TCPDump) bool 
{
	for mut con in d.blocked_t2_cons {
		if con.source_ip == con_chk.source_ip { return true }
	}

	d.adv_block_con(mut con_chk)
	return false
}

/*
*	[@DOC]
*	pub fn (mut d Dump) is_con_dropped(ip string) bool 
*
*	- Validate if an IP has been dropped in the drop system
*/
pub fn (mut d Dump) is_con_dropped(ip string) bool 
{
	for mut con in d.dropped_cons {
		if con.external_ip == ip { return true }
	}

	return false
}

fn (mut d Dump) block_con(mut con ns.NetstatCon)
{
	d.blocked_cons << con
	d.max_cons_reeached = d.blocked_cons.len
}

fn (mut d Dump) adv_block_con(mut con td.TCPDump)
{
	d.blocked_t2_cons << con
}

pub fn (mut d Dump) dump_file()
{

}