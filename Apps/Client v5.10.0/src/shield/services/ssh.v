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
	for i, line in ssh_config
	{
		if line.starts_with("Port") && !ssh_config[i+1].starts_with("Port") {
			new_edit += "Port ${port}\n"
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