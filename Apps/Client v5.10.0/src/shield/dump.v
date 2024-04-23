module shield

import os

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

pub fn (mut d Dump) is_ip_blocked(ip string) bool 
{
	for con in d.blocked_cons {
		if con.external_ip == ip { return true }
	}

	for tcp_con in d.blocked_t2_cons {
		if tcp_con.destination_ip == ip { 
			return true 
		}
	}

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

pub fn (mut d Dump) block_con(mut con ns.NetstatCon)
{
	d.blocked_cons << con
	d.max_cons_reeached = d.blocked_cons.len + d.blocked_t2_cons.len
	
	if con.ip_t == ns.IP_T.ipv4 {
		os.execute("sudo iptables -A INPUT -s ${con.external_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.external_ip} -p tcp -j DROP")
	} else if con.ip_t == ns.IP_T.ipv6 {
		os.execute("sudo ip6tables -A INPUT -s ${con.external_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.external_ip} -j DROP")
	}
}

pub fn (mut d Dump) adv_block_con(mut con td.TCPDump)
{
	d.blocked_t2_cons << con
	d.max_cons_reeached = d.blocked_cons.len + d.blocked_t2_cons.len
	
	if con.hostname_t == td.Protocol_T.ipv4 || con.hostname_t == .ipv4  {
		os.execute("sudo iptables -A INPUT -s ${con.destination_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.destination_ip} -p tcp -j DROP")
	} else if con.hostname_t == td.Protocol_T.ipv6 || con.hostname_t == .ipv6 {
		os.execute("sudo ip6tables -A INPUT -s ${con.destination_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.destination_ip} -j DROP")
	}

	
}

pub fn (mut d Dump) dump_file(current_datetime string)
{
	os.write_file("test.txt", "${d}") or { return }
}