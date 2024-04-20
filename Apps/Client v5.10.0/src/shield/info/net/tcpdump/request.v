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

pub fn new_req(arr []string, from []string, to []string) TCPDump {
	mut new := TCPDump{
		timestamp: arr[0],
		protocol: arr[1],
		hostname_t: hostname2type(from[0]),
		source_ip: from[0],
		source_port: from[1].int(),
		destination_ip: to[0],
		destination_port: to[1].int(),
		pkt_length: arr[arr.len-1].int()
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

pub fn fetch_tcpdump() []TCPDump {
	go os.execute("timeout 2 tcpdump -i ens3 -x -n ip > pcap_data.shield")
	os.execute("timeout 2 tcpdump -i ens3 -x ip6 >> pcap_data.shield").output
	
	time.sleep(30*time.millisecond)
	tcpdump_data := os.read_lines("pcap_data.shield") or {
		println("[ - ] WARNING, Unable to read PCAP data file.....!")
		return []TCPDump{}
	}

	mut dump_cons := []TCPDump{}

	for line in tcpdump_data {
		line_args := line.split(" ")
		if line_args.len < 3 { continue }

		/* Detection for a new connection line */
		if !line.starts_with(" ") && line_args.len > 10 {
			_ := line_args[2] // from_raw_addr
			from_args := line_args[2].split(".")

			_ := line_args[4] // to_raw_addr
			to_args := line_args[4].split(".")

			from_addr := utils.arr2ip(from_args[0..(from_args.len-1)])
			mut from_port := from_args[from_args.len-1] 

			to_addr := utils.arr2ip(to_args[0..(to_args.len-1)])
			mut to_port := to_args[to_args.len-1].replace(":", "")
			
			if from_port == "http" { from_port = "80" }
			if to_port == "http" { to_port = "80" }
			
			if from_addr.contains("ovh") { continue }
			if !utils.is_hostname_valid(from_addr) { continue }

			dump_cons << new_req(line_args, [from_addr, from_port], [to_addr, to_port])
		} else {
			if dump_cons.len > 0 {
				dump_cons[dump_cons.len-1].pkt_data << line.trim_space()
			}
		}
	}

	return dump_cons
}

pub fn (mut t TCPDump) retrieve_data() string
{
	return "${t.pkt_data}".replace("['", "").replace("']", "").replace("', '", "\n")
}