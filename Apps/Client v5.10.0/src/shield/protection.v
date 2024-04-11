module shield

import os
import time

import src.shield.utils
import src.shield.info.net
import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub struct Filter
{
	pub mut:
		captured_pps 		int
		captured_cons 		[]ns.NetstatCon
		captured_con_count  int

		captured_tcpdump 	[]td.TCPDump
		captured_req 		int

		blocked_ips 		[]ns.NetstatCon
		dropped_ips 		[]ns.NetstatCon
}

pub struct Protection 
{
	pub mut:
		key 					string

		last_cons 				[]ns.NetstatCon
		temporary_whitelist 	[]string
		/* Reset/Empty IPTables after an attack has finished */
		reset_tables			bool

		// Maximum PPS accepted before filtering connections
		max_pps					int

		/*
		* 	 Maximum Connections accepted before filtering/dropping connection
		*    Note: This does not include connections whitelisted to the VPS/CyberShield/OpenVPN
		*/
		max_connections			int 

		/* Maximum Connection Per Port accepted before dropping */
		max_con_per_port		int

		/* 
		* 	Add user's rule(s) after an attack has finished and iptables has been reset 
		*/ 
		auto_add_rules			bool
		personal_rules 			[]string

		/*
		*	List of IPs && Ports to allow connections during attacks while dropping connections
		*/
		whitelisted_ips 		[]string
		whitelisted_ports 		[]int

		/* {"SERVICE_PORT": ["SERVICE_NAME_OR_TYPE", "RESTART_SERVICE_COMMAND"]} */
		whitelisted_services 	map[string][]string
		server_hostname 		string
		server_ipv4				string
		server_ipv6				string
		ssh_ports 				[]int
		openvpn_port 			int
		web_ports 				[]int
}

pub const protection_filepath = "assets/settings.shield"

pub fn protection__init() Protection 
{
	mut p := Protection{ server_hostname: os.execute("hostname -f").output }
	protection_file := os.read_lines(protection_filepath) or {
		println("[ X ] Error, Unable to read protection config file\r\n\t=> Path: '${protection_filepath}'")
		exit(0)
	}

	ip_data := utils.get_block_data(protection_file, "[@PROTECTED_IPS]")
	for ip in ip_data { 
		if ip.trim_space() != "" { 
			p.whitelisted_ips << ip.trim_space()
		}
	}

	port_data := utils.get_block_data(protection_file, "[@PROTECTED_PORTS]")
	for port in port_data { 
		if port.trim_space().int() != 0 && port.trim_space() != "" { 
			p.whitelisted_ports << port.int() 
		} 
	}

	p.personal_rules = utils.get_block_data(protection_file, "[@PERSONAL_RULES]")

	settings := utils.get_block_data(protection_file, "[@SETTINGS]")
	for line in settings
	{
		println("${line}")
		if line.contains("@PERSONAL_RULES") { break }
		key_info := line.split(":")
		if key_info.len != 2 { continue}
		println("${key_info}")
		match key_info[0] 
		{
			utils.arr_starts_with(key_info, "token") {
				p.key = key_info[1]
			}
			utils.arr_starts_with(key_info, "max_pps") {
				p.max_pps = key_info[1].trim_space().int()
			}
			utils.arr_starts_with(key_info, "max_connections") {
				p.max_connections = key_info[1].trim_space().int()
			}
			utils.arr_starts_with(key_info, "max_con_per_port") {
				p.max_con_per_port = key_info[1].trim_space().int()
			}
			utils.arr_starts_with(key_info, "auto_reset_rules") {
				p.reset_tables = key_info[1].trim_space().bool()
			} else {}
		}
	}

	return p
}

pub fn (mut p Protection) add_personal_rules() 
{
	for rule in p.personal_rules
	{
		if rule.len < 2 { continue }
		os.execute("${rule}")
	}
	os.execute("iptables-save")

	println("[ + ] All rules applied....!")
}

/* 
*	[@DOC]
*	- Legitimate connection temporary whitisting for attacks
*
*	Connections that are already established before an attack is caught
*   are temporarily whitlisted during attacks then removed from the list 
*   of temporary whitisted connections
*/
pub fn (mut p Protection) temporary_whitlist_cons(mut cons []ns.NetstatCon) 
{
	for mut con in cons {
		/* Skip If the connection is already whitlisted or temporarily whitlisted */
		if con.external_ip in p.whitelisted_ips && con.external_ip in p.temporary_whitelist { continue }
		
		/* Detect for established connections to temporary whitlist */
		if con.state == ns.State_T.established {
			p.temporary_whitelist << con.external_ip
		}
	}
}

pub fn (mut p Protection) reset_temp_whitlist() 
{ p.temporary_whitelist = []string{} }

pub fn (mut p Protection) is_port_whitlisted(port int) bool
{ 
	if port in p.whitelisted_ports { 
		return true 
	}
	
	return false
}

pub fn (mut p Protection) is_con_whitlisted(ip string) bool
{
	if ip in p.whitelisted_ips || ip in p.temporary_whitelist {
		return true
	}

	return false 
}

pub fn (mut p Protection) detect_stage_one(pps int, unique_con_count int) bool 
{
	if unique_con_count > p.max_connections || pps >= p.max_pps { 
		return true
	}

	return false
}

pub fn (mut p Protection) detect_stage_two(pps int, unique_con_count int, blocked_con_count int) bool
{
	if (pps > p.max_pps && unique_con_count > p.whitelisted_ips.len) { 
		return true
	}

	return false
}

pub fn (mut p Protection) detect_stage_three(pps int) bool
{
	if pps > p.max_pps {
		return true 
	}

	return false
}