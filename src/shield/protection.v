module shield

import os

import src.shield.utils
import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub type CS_Con = ns.NetstatCon | td.TCPDump

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

pub struct Service {
	pub mut:
		name			string
		port 			int 
		protocol 		string // Protocol its on (Avoid dropping port which causes socket app(s) to crash)
		// App Restart command to drop the maxed port every second during the attack
		// Quick app/server restart applications can keep users connected to it during attacks. 
		// Make sure clients application have re-connect upon disconnections. Most have it by default
		command 		string 
		max_con 		int
		max_pps 		int
		enable_filter	bool
		enable_drop		bool
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
		services 				[]Service
		server_hostname 		string
		server_ipv4				string
		server_ipv6				string
		ssh_ports 				[]int
		discord_webhook_api 	string
}

pub const protection_filepath = "assets/settings.shield"

pub fn protection__init() Protection 
{
	mut p := Protection{ 
		services: []Service{},
		temporary_whitelist: []string{}
	}
	protection_file := os.read_lines(protection_filepath) or {
		println("[ X ] Error, Unable to read protection config file\r\n\t=> Path: '${protection_filepath}'")
		exit(0)
	}

	/* Get CyberShield Settings */
	for line in utils.get_block_data(protection_file, "[@SETTINGS]")
	{
		if line.contains("@PERSONAL_RULES") { break }
		key_info := line.split(":")
		if key_info.len != 2 { continue}
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
			}
			utils.arr_starts_with(key_info, "discord_webhook_api") {
				p.discord_webhook_api = key_info[1].trim_space()
			} else {}
		}
	}

	/* Retrieve Personal Rules */
	p.personal_rules = utils.get_block_data(protection_file, "[@PERSONAL_RULES]")

	/* Retrieve Whitelisted IP(s) */
	ip_data := utils.get_block_data(protection_file, "[@PROTECTED_IPS]")
	for ip in ip_data { 
		if ip.trim_space() != "" { 
			p.whitelisted_ips << ip.trim_space()
		}
	}
	
	/* Retrieve Service Protection via Config */
	for line in utils.get_block_data(protection_file, "[@PROTECTED_SERVICES]") {
		if line.trim_space() != "" { 
			line_arg := line.trim_space().split(";")

			p.services << Service{
				name: line_arg[1],
				port: line_arg[0].int(),
				protocol: line_arg[2],
				command: line_arg[3],
				max_con: line_arg[4].int(),
				max_pps: line_arg[5].int(),
				enable_filter: line_arg[6].bool(),
				enable_drop: line_arg[7].bool()
			}
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
	os.execute("iptables-save; ip6tables-save")

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
		if con.external_ip in p.whitelisted_ips || con.external_ip in p.temporary_whitelist { continue }
		
		/* Detect for established connections to temporary whitlist */
		if con.state == ns.State_T.established {
			p.temporary_whitelist << con.external_ip
		}
	}
}

/*
*	[DOC]
*	pub fn (mut p Protection) inspect_connection(mut con CS_Con) (bool, bool)
*
*	- Inspect a connection for malicious activities
*/
pub fn (mut p Protection) inspect_connection(mut con ns.NetstatCon, mut tcon td.TCPDump) (bool, Service) {
	if con != ns.NetstatCon{} {
		if p.is_con_whitlisted(con.external_ip) { return false, Service{} }

		if con.recv_bytes > 1000 {
			println("[ + ] (Netstat) This connection (${con.external_ip}) is sending mass amount of packets.....!")
			block_ipv4(con.external_ip, p.server_ipv4)
		}
		
		if p.is_port_serviced(con.internal_port) {
			port_info := p.grab_port_info(con.internal_port)
			return true, port_info
		}

		return true, Service{}
	} else if tcon != td.TCPDump{} {
		
		mut ip := tcon.destination_ip
		if tcon.req_direction == td.ConnectionDirection.inbound {
			ip = tcon.source_ip
		}

		if p.is_con_whitlisted(ip) { return false, Service{} }
		if tcon.pkt_length > 1024 {
				println("[ + ] (TCPDump) This connection (${ip}) is sending mass amount of packets.....!")
				block_ipv4(ip, p.server_ipv4)
		}

		if p.is_port_serviced(tcon.source_port) {
			port_info := p.grab_port_info(tcon.source_port)
			return true, port_info
		}
		return true, Service{}
		
	}
	return false, Service{}
}

/*
*	[@DOC]
*	pub fn (mut p Protection) reset_temp_whitlist()
*
*	- Reset the list of temporary whitelisted IPs for attack mode
*/
pub fn (mut p Protection) reset_temp_whitlist()  { 
	p.temporary_whitelist = []string{} 
}

/*
*	[@DOC]
*	pub fn (mut p Protection) is_con_whitlisted(ip string) bool
*
*	- Check if an IP is whitelisted
*/
pub fn (mut p Protection) is_con_whitlisted(ip string) bool {
	if ip in p.whitelisted_ips {
		return true
	}

	if p.temporary_whitelist.len > 0 && ip in p.temporary_whitelist {
		return true
	}

	return false 
}

/*
* 	[@DOC]
*	pub fn (mut p Protection) is_port_whitlisted(port int) bool
*
*	- Check if a port is whitelisteds
*/
pub fn (mut p Protection) is_port_whitlisted(port int) bool { 
	if port in p.whitelisted_ports { 
		return true 
	}
	
	return false
}

/*
*	[@DOC]
*	pub fn (mut p Protection) is_port_serviced(port int) bool
*
*	- Check if a port is being serviced
*/
pub fn (mut p Protection) is_port_serviced(port int) bool {
	for service in p.services {
		if port == service.port { return true }
	}

	return false
}

/*
*	[@DOC]
*	pub fn (mut p Protection) grab_port_info(p int) Service
*
*	- Get information about a serviced port
*/
pub fn (mut p Protection) grab_port_info(prt int) Service {
	for mut service in p.services {
		if service.port == prt { return service }
	}

	return Service{}
}

/*
*	[@DOC]
*	pub fn (mut p Protection) detect_stage_one(pps int, unique_con_count int) bool 
*
*	= Detecting 
*/
pub fn (mut p Protection) detect_stage_one(pps int, unique_con_count int) bool {
	if unique_con_count > p.max_connections || pps >= p.max_pps { 
		return true
	}

	return false
}

pub fn (mut p Protection) is_stage_one_done(pps int, unique_con_count int) bool 
{ return (pps < p.max_pps) }

pub fn (mut p Protection) detect_stage_two(pps int, con_count int, unique_con_count int, blocked_con_count int) bool
{
	if pps > p.max_pps && (unique_con_count == 0 || unique_con_count > (p.whitelisted_ips.len + 3)) { 
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

pub fn (mut p Protection) is_stage_two_n_three_done(pps int) bool 
{ return (pps < p.max_pps) }