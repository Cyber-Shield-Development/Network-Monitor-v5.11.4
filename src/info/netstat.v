module info

import os

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

pub struct Netstat 
{
	pub mut:
		protocol		string
		recv_bytes		int
		sent_bytes		int
		internal_ip 	string
		internal_port	int
		external_ip		string
		external_port	int
		state			State_T
}

pub fn new(arr []string) Netstat
{
	return Netstat{ 
		protocol: arr[0],
		recv_bytes: arr[1].int(),
		sent_bytes: arr[2].int(),
		internal_ip: arr[3].split(":")[0],
		internal_port: arr[3].split(":")[1].int(),
		external_ip: arr[4].split(":")[0],
		external_port: arr[4].split(":")[1].int(),
		state: state2type(arr[5])
	}
}

pub fn grab_ips() []Netstat
{
	ips_data := os.execute("netstat -tn").output.split("\n")
	mut conns := []Netstat{}
	
	for line in ips_data
	{
		line_info := line.split(" ")
		ip_info := info.remove_empty_elemets(line_info)
		if ip_info.len < 4 || !line.contains(":") { continue }
		conns << new(ip_info)
	}

	return conns
}

pub fn (mut n Netstat) is_alive() bool
{
	if n.state in [State_T.established,State_T.syn_recv, State_T.time_wait, State_T.close_wait, State_T.last_ack]
	{ 
		return true
	}

	return false
}

pub fn (mut n Netstat) is_recv_high() bool
{
	if n.recv_bytes > 50 { return true }
	return false 
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