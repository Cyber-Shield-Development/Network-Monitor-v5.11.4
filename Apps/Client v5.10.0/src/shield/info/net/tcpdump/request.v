module tcpdump

import os
import time

import src.shield.utils

pub enum Protocol_T 
{
	_null 	= 0x030
	ipv4 	= 0x031
	ipv6 	= 0x032
	url 	= 0x033
}

pub enum ConnectionDirection
{
	_null 		= 0x2000
	inbound 	= 0x2001
	outbound 	= 0x2003
}

pub struct TCPDump
{
	pub mut:
		timestamp 			string
		protocol 			string
		hostname_t 			Protocol_T
		source_ip 			string
		source_port 		int
		destination_ip 		string
		destination_port 	int
		flags 				string
		pkt_length			int
		pkt_data			[]string
		req_direction 		ConnectionDirection
}

pub fn new_req(arr []string, from []string, to []string, reqbound ConnectionDirection) TCPDump {
	mut new := TCPDump{
		timestamp: arr[0],
		protocol: arr[1],
		hostname_t: hostname2type(from[0]),
		source_ip: from[0],
		source_port: from[1].int(),
		destination_ip: to[0],
		destination_port: to[1].int(),
		pkt_length: arr[arr.len-1].int(),
		req_direction: reqbound
	}
	
	new.flags = new.fetch_flags(arr)

	if new.hostname_t == Protocol_T.url {
		new.fix_ip()
	}

	return new
}

pub fn (mut td TCPDump) fetch_flags(request_info []string) string 
{
	/* Ensure the flags are in the data provided */
	if request_info.len <= 5 || "Flags" !in request_info { return "" }

	/* Grab Flags */
	for i, element in request_info {
		if element == "Flags" { return "${request_info[i..request_info.len-2]}".replace("['", "").replace("]", "").replace("', '", " ") }
	}

	return ""
}

pub fn hostname2type(hostname string) Protocol_T {
	match true {
		utils.validate_ipv4_format(hostname) {
			return Protocol_T.ipv4
		}
		utils.validate_ipv6_format(hostname) {
			return Protocol_T.ipv6
		}
		utils.validate_url_format(hostname) {
			return Protocol_T.url
		} else { 
			return Protocol_T._null
		}
	}
}

pub fn (mut td TCPDump) fix_ip()
{
	// TODO: Parse IPV4 out of URL before resolving
	// 		  DNS on the domain/URL
	mut check := utils.retrieve_ipv4(td.destination_ip)
	
	if check.starts_with("0") {
		check = check.substr(1, check.len)
	}

	if !utils.validate_ipv4_format(check) {
		return
	}

	println("[ + ] SETTINGS ${check}")
	td.destination_ip = check
	td.hostname_t = Protocol_T.ipv4
}

pub fn (mut td TCPDump) hostname_to_ipv4() string
{ 
	args := os.execute("timeout 2 host -t A ${td.destination_ip}").output 
	return args[args.len-1].ascii_str()
}

pub fn (mut t TCPDump) retrieve_data() string
{
	return "${t.pkt_data}".replace("['", "").replace("']", "").replace("', '", "\n")
}