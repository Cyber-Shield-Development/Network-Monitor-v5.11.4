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
		pkt_data			map[string]string
		req_direction 		ConnectionDirection
}

/*
*	[@DOC]
*	pub fn new_req(arr []string, from []string, to []string, reqbound ConnectionDirection) TCPDump
*
*	- Build new TCPDump request instance
*/
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
		req_direction: reqbound,
		pkt_data: map[string]string{}
	}
	
	new.flags = new.fetch_flags(arr)
	return new
}

/*
*	[@DOC]
*	pub fn (mut td TCPDump) to_str() string
*
*	- Return a decent string of request information for dump file
*/
pub fn (mut td TCPDump) to_str() string {
	mut output := "[Request Time: ${td.timestamp}]\r\n\t{\r\n\t\tHostname Type: ${td.hostname_t} => ${td.source_ip}:${td.source_port} > ${td.destination_ip}:${td.destination_port}\r\n"
	output += "\t\tProtocol: ${td.protocol} | Request Direction: ${td.req_direction} | Packet Length: ${td.pkt_length}\r\n\t\t[@PACKET_DATA]\r\n\t\t{\r\n"

	for tstamp, pdata in td.pkt_data {
		output += "\t\t\t${tstamp}: ${pdata.replace('\n', '\n\t\t\t\t')}\r\n"
	}

	output += "\t\t}\r\n\t}\r\n"
	return output
}

/*
*	[@DOC]
*	pub fn (mut td TCPDump) fetch_flags(request_info []string) string
*
*	- Parse and retrieve request flags
*/
pub fn (mut td TCPDump) fetch_flags(request_info []string) string {
	/* Ensure the flags are in the data provided */
	if request_info.len <= 5 || "Flags" !in request_info { return "" }

	/* Grab Flags */
	for i, element in request_info {
		if element == "Flags" { return utils.arr2str(request_info[i..request_info.len-2], " ") }
	}

	return ""
}

/*
*	[@DOC]
*	pub fn hostname2type(hostname string) Protocol_T
*
*	- Detect hostname type
*/
pub fn hostname2type(hostname string) Protocol_T {
	match true {
		utils.validate_ipv4_format(hostname) { return Protocol_T.ipv4 }
		utils.validate_ipv6_format(hostname) { return Protocol_T.ipv6 }
		utils.validate_url_format(hostname) { return Protocol_T.url } 
		else { }
	}
	return Protocol_T._null
}

/*
*	[@DOC]
*	pub fn (mut t TCPDump) retrieve_data() string
*
*	- Return packet data in a plain text string
*/
pub fn (mut t TCPDump) retrieve_data() string {
	return "${t.pkt_data}".replace("{'", "").replace("'}", "").replace("', '", "\n")
}