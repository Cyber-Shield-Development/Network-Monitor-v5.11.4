module src

import os
import x.json2 as json

pub struct VPN
{
	pub mut:
		name			string
		ip_address		string
		username 		string
		password 		string
		location		string
		plan			int
}

pub fn (mut v VPN) vpn2str() string
{ return "${v.name},${v.ip_address},${v.username},${v.password},${v.location},${v.plan}" }

pub fn get_vpn_file(vpn_name string) string 
{ 
	if !os.exists("assets/db/vpns/${vpn_name}.ovpn") {
		println("[ X ] Error, File cant be found......\r\n\t=> VPN Name: '${vpn_name}'")
		return ""
	}

	return os.read_file("assets/db/vpns/${vpn_name}.ovpn") or { "" } 
}
