module netstat 

import src.shield.utils

pub enum Protocol_T
{
	_null 			= 0x00000
	udp 			= 0x00001
	tcp 			= 0x00002
}

pub enum IP_T 
{
	_null 			= 0x20000
	ipv4 			= 0x20001
	ipv6			= 0x20002
}

pub enum State_T
{
	_null			= 0x10001
	close_wait		= 0x10002
	closed			= 0x10003
	established		= 0x10004
	fin_wait1		= 0x10005
	fin_wait2 		= 0x10006
	last_ack		= 0x10007
	listen			= 0x10008
	syn_recv		= 0x10009
	syn_sent		= 0x10010
	time_wait		= 0x10011
	closing			= 0x10012
}

pub struct NetstatCon
{
	pub mut:
		protocol		Protocol_T
		recv_bytes		int
		sent_bytes		int
		internal_ip 	string
		internal_port	int
		external_ip		string
		external_port	int
		state			State_T
		pid_n_process	string
		dups 			int
		ip_t 			IP_T
}

pub fn new_con(arr []string) NetstatCon
{
	mut new := NetstatCon{ 
		protocol: detect_protocol_t(arr[0]),
		recv_bytes: arr[1].int(),
		sent_bytes: arr[2].int(),
		internal_ip: arr[3].split(":")[0],
		internal_port: arr[3].split(":")[1].int(),
		external_ip: arr[4].split(":")[0],
		external_port: arr[4].split(":")[1].int(),
		ip_t: detect_ip_t(arr[4].split(":")[0]),
		state: state2type(arr[5])
		// pid_n_process: arr[6]
	}

	// if new.external_ip.split(":").len > 2 {
	// 	new.external_ip = arr[4].replace(":" + arr[4].split(":")[arr[4].split(":").len-1], "")
	// }

	return new
}

pub fn (mut n NetstatCon) to_str() string {
	return "\t[${n.protocol}:${n.ip_t}] ${n.state} ${n.external_ip}:${n.external_port} > ${n.internal_ip}:${n.internal_port} Recv: ${n.recv_bytes} | Sent: ${n.sent_bytes}"
}

pub fn trim_elements(arr []string) []string
{
	mut new := []string{}
	for element in arr { if element != "" { new << arr } }
	return new
}

pub fn state2type(st string) State_T
{
	match st
	{
		"close_wait".to_upper() { return State_T.close_wait }
		"closed".to_upper() { return State_T.closed }
		"established".to_upper() { return State_T.established }
		"fin_wait1".to_upper() { return State_T.fin_wait1 }
		"fin_wait2".to_upper() { return State_T.fin_wait2}
		"last_ack".to_upper() { return State_T.last_ack }
		"listen".to_upper() { return State_T.listen }
		"syn_recv".to_upper() { return State_T.syn_recv }
		"syn_sent".to_upper() { return State_T.syn_sent }
		"time_wait".to_upper() { return State_T.time_wait }
		"closing".to_upper() { return State_T.closing }
		else { return State_T._null }
	}

	return State_T._null
}

pub fn detect_ip_t(hostname string) IP_T 
{
	if utils.validate_ipv4_format(hostname) {
		return IP_T.ipv4
	} else if utils.validate_ipv6_format(hostname) {
		return IP_T.ipv6
	}

	return IP_T._null
}

pub fn detect_protocol_t(protocol string) Protocol_T
{
	if protocol == "tcp" || protocol.to_lower() == "ip" { return Protocol_T.tcp }
	return Protocol_T.udp
}