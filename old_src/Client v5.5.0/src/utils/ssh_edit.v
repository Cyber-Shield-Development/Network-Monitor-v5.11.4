module utils

import os

pub fn check_custom_port_enable() ([]string, bool) 
{
	mut ssh_ports := []string{}
	mut enabled := false
	ssh_file := os.read_lines("/etc/ssh/sshd_config") or {
		println("[ X ] Error, Unable to read file OR You aren't root. Make sure to run this as root!....!")
		return ssh_ports, false
	}

	for line in ssh_file {
		if line.starts_with("#Port") { ssh_ports << line.split(" ")[1] }
		else if line.starts_with("Port ") { ssh_ports << line.split(" ")[1]  enabled = true }
	}

	return ssh_ports, enabled
}

pub fn add_port(port int)
{
	check_custom_port_enable()
	ssh_file := os.read_file("/etc/ssh/sshd_config") or { 
		println("[ X ] Error, Unable to read file OR You aren't root. Make sure to run this as root!....!")
		return
	}
	
	if ssh_file.contains("Port ${port}") { 
		println("[ X ] This SSH port already exists....!")
		return 
	}

	lines := ssh_file.split("\n")
	mut new_edit := ""

	for i, line in lines 
	{
		/* 
		*  Check #Port if its been found which only can 
		*  be changed when adding a Port 
		*/
		if i > 1 {
			if !line.starts_with("Port") && lines[i-1].starts_with("Port") {
				new_edit += "Port ${port}\n"
				continue
			}

			new_edit += "${line}\n"
		}
	}
	
	os.write_file("/etc/ssh/sshd_config", new_edit) or { 
		println("[ X ] Error, Unable to read file OR You aren't root. Make sure to run this as root!....!")
		return
	}
}

pub fn rm_port(port int)
{
	_, check := check_custom_port_enable()
	if !check && port == 22 {
		println("[ X ] You must add a port before removing 22")
	}

	ssh_file := os.read_file("/etc/ssh/sshd_config") or { "" }
	
	if !ssh_file.contains("Port ${port}") { 
		println("[ X ] This SSH port does not exists....!")
		return 
	}

	lines := ssh_file.split("\n")
	mut new_edit := ""
	for line in lines 
	{ if !line.starts_with("Port ${port}") { new_edit += "${line}\n" } }

	os.write_file("/etc/ssh/sshd_config", new_edit) or { 
		println("[ X ] Error, Unable to read file OR You aren't root. Make sure to run this as root!....!")
		return
	}
}