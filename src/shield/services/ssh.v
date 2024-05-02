module services

import os

import src.shield.utils

pub const ssh_config_filepath = "/etc/ssh/sshd_config"

pub fn start_ssh() 
{ os.execute("sudo service ssh start") }

pub fn stop_ssh() 
{ os.execute("sudo service ssh stop") }

pub fn restart_ssh() 
{ os.execute("sudo service ssh restart") }

pub fn clear_ssh_ports(p int) {
	if p != 0 { 
		os.execute("fuser -k ${p}/tcp > /dev/null; service ssh restart") 
		return
	}

	chk, ports := scan_ssh_ports()
	if !chk { 
		os.execute("fuser -k 22/tcp; service ssh restart")
		return 
	}

	for port in ports {
		os.execute("fuser -k ${port}/tcp > /dev/null; fuser -k ${port}/udp > /dev/null; service ssh restart")
	}
}

pub fn scan_ssh_ports() (bool, []int)
{
	mut custom_port_enabled := false
	mut ports := []int{}

	ssh_config := os.read_lines(ssh_config_filepath) or { 
		return false, ports
	}

	for line in ssh_config {
		if line.starts_with("#Port") { 
			ports << 22
			return false, ports 
		}

		if line.starts_with("Port") {
			custom_port_enabled = true
			ports << line.split(" ")[1].int()
		}
	}

	return custom_port_enabled, ports
}

pub fn add_ssh_port(port int) bool
{
	_, ports := scan_ssh_ports()

	if port in ports {
		println("[ X ] Error, This port is already in use!")
		return false
	}

	ssh_config := os.read_lines(ssh_config_filepath) or { return false }
	mut new_edit := ""
	for _, line in ssh_config
	{
		if line.starts_with("#AddressFamily any") {
			new_edit += "Port ${port}\n${line}\n"
			continue
		}

		new_edit += "${line}\n"
	}

	os.write_file(ssh_config_filepath, new_edit) or {
		println("[ X ] Error, Unable to save new SSH edit.....!")
		return false
	}

	return true
} 

pub fn rm_ssh_port(port int)
{
	chk, _ := scan_ssh_ports()
	if !chk && port == 22 {
		println("[ X ] You must add a port before removing 22")
	}

	ssh_file := os.read_file(ssh_config_filepath) or { "" }
	
	if !ssh_file.contains("Port ${port}") { 
		println("[ X ] This SSH port does not exists....!")
		return 
	}

	lines := ssh_file.split("\n")
	mut new_edit := ""
	for line in lines 
	{ if !line.starts_with("Port ${port}") { new_edit += "${line}\n" } }

	os.write_file(ssh_config_filepath, new_edit) or { 
		println("[ X ] Error, Unable to read file OR You aren't root. Make sure to run this as root!....!")
		return
	}
}

pub fn last_ssh_logins() []string
{
	mut last_logins := os.execute("last").output.split("\n")
	mut ips := []string{}

	for line in last_logins 
	{
		login_info := utils.rm_empty_elements(line.split(" "))
		if login_info.len < 3 { continue }
		if utils.validate_ipv4_format(login_info[2]) && login_info[2] !in ips { 
			ips << login_info[2] 
		}
	}

	return ips
}