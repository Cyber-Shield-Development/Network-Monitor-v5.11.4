module services

import os
import src.shield.utils

pub enum Protocol 
{
	_null 	= 0x020
	udp 	= 0x021
	tcp 	= 0x022
}

pub const config_filepath = "/etc/openvpn/server.conf"

pub fn check_for_ovpn() bool
{ return os.exists(config_filepath) }

pub fn start_ovpn()
{ os.execute("sudo service openvpn start") }

pub fn stop_ovpn()
{ os.execute("sudo service openvpn stop") }

pub fn restart_ovpn()
{ os.execute("sudo service openvpn restart") }

pub fn clear_ovpn_port() 
{ os.execute("fuser -k ${retrieve_ovpn_port()}/tcp; fuser -k ${retrieve_ovpn_port()}/udp") }

pub fn retrieve_ovpn_port() int
{
	if !check_for_ovpn() { return 0 }

	ovpn_config := os.read_lines(config_filepath) or {
		println("[ X ] Error, Unable to read OpenVPN config file....!")
		exit(0)
	}

	for line in ovpn_config
	{
		if line.starts_with("port") {
			return line.split(" ")[1].trim_space().int()
		}
	}

	return 0
}

pub fn retrieve_ovpn_protocol() Protocol
{
	if !check_for_ovpn() { return Protocol._null }

	ovpn_config := os.read_lines(config_filepath) or {
		println("[ X ] Error, Unable to read OpenVPN config file....!")
		exit(0)
	}

	for line in ovpn_config
	{
		if line.starts_with("proto") {
			if line.split(" ")[1].trim_space() == "udp" {
				return Protocol.udp
			} else { return Protocol.tcp }
		}
	}

	return Protocol._null 
}

pub fn grab_ovpn_uptime() string
{
	service_status := os.execute("service openvpn status").output
	status_args := service_status.split("\n")[2].split(" ")

	return utils.arr2str(status_args[4..status_args.len], " ")
}