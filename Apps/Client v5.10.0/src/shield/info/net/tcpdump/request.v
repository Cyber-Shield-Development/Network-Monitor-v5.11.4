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
		source_ip: from[0],
		source_port: from[1].int(),
		destination_ip: to[0],
		destination_port: to[1].int(),
		pkt_length: arr[arr.len-1].int()
	}

	new.flags = new.fetch_flags(arr)
	new.parse_hostname()

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

pub fn (mut td TCPDump) parse_hostname()
{
	if utils.validate_ipv4_format(td.destination_ip) {
		td.hostname_t = Protocol_T.ipv4
		return
	} else if utils.validate_ipv6_format(td.destination_ip) {
		td.hostname_t = Protocol_T.ipv6
		return
	} else if utils.validate_url_format(td.destination_ip) {
		td.hostname_t = Protocol_T.url

		// TODO: Parse IPV4 out of URL before resolving
		// 		  DNS on the domain/URL
		check := td.does_url_have_ipv4()
		if utils.validate_ipv4_format(check) {
			td.destination_ip = check
			td.hostname_t = Protocol_T.ipv4
			return
		}
		
		/* Convert to IPV4 */
		println("[ - ] ${check} Unable to get IPV4 from URL. Resolving....")
		ipv4_chk := td.hostname_to_ipv4()
		if !utils.validate_ipv4_format(ipv4_chk) {
			println("[ - ] WARNING, Unable to resolve hostname....!\r\n\t=> Hostname: ${td.destination_ip}......!\r\n\t=> Results: ${ipv4_chk}")
			return 
		}

		td.destination_ip = ipv4_chk
		td.hostname_t = Protocol_T.ipv4
	}
}


// example of lines this function parses
// c-73-32-44-63.hsd1.tn.comcast.net
// 187-072-141-082.static.ctbctelecom.com.br
// 
pub fn (mut td TCPDump) does_url_have_ipv4() string
{
    copy := td.destination_ip
	args := copy.split("-")
	if args.len < 4 { return "" }

	mut ip := rm_chrs(arr2ip(args[0..4]))

	if ip.ends_with(".") {
		ip = ip.substr(0, ip.len-1)
	}

	return ip
}

pub fn rm_chrs(data string) string {
	mut new := ""

	for ch in data {
		if ch.is_letter() { break }
		new += ch.ascii_str()
	}

	return new
}

pub fn arr2ip(arr []string)string 
{ return "${arr}".replace("['", "").replace("']", "").replace("', '", ".") }

pub fn (mut td TCPDump) hostname_to_ipv4() string
{ 
	args := os.execute("timeout 2 'host -t A ${td.destination_ip}'").output 
	return args[args.len-1].ascii_str()
}

pub fn fetch_tcpdump() []TCPDump {
	go os.execute("timeout 2 tcpdump -i ens3 -x ip > pcap_data.shield")
	os.execute("timeout 2 tcpdump -i ens3 -x ip6 >> pcap_data.shield").output
	
	time.sleep(30*time.millisecond)
	tcpdump_data := os.read_lines("pcap_data.shield") or {
		println("[ - ] WARNING, Unable to read PCAP data file.....!")
		return []TCPDump{}
	}

	mut dump_cons := []TCPDump{}

	for line in tcpdump_data {
		line_info := line.split(" ")
		if line_info.len < 3 { continue }

		/* Detection for a new connection line */
		if !line.starts_with(" ") && line_info.len > 10 {
			// Hostname will always include a period for at-least the point
			from_hostname := line_info[2].split(".")
			to_hostname := line_info[2].split(".")

			from_address := line_info[2].replace(".${from_hostname[from_hostname.len-1]}", "")
			from_port := from_hostname[from_hostname.len-1]

			to_address := line_info[2].replace(".${to_hostname[to_hostname.len-1]}", "")
			to_port := to_hostname[to_hostname.len-1]
			
			if utils.is_hostname_valid(to_address) { continue }

			dump_cons << new_req(line_info, [from_address, from_port], [to_address, to_port])
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