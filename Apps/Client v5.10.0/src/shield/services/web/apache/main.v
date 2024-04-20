module apache

import os

pub const apache_config_filepath = "/etc/apache2/ports.conf"

pub fn scan_for_apache() bool
{ return os.exists(apache_config_filepath) }

pub fn start_apache() 
{ os.execute("sudo service apache2 start") }

pub fn stop_apache()
{ os.execute("sudo service apache2 stop") }

pub fn restart_apache() 
{ os.execute("sudo service apache2 restart") }

pub fn retrieve_apache_port() int
{
	if !scan_for_apache() { return 0 }

	apache_port_file := os.read_lines(apache_config_filepath) or { 
		println("[ X ] Error, unable to read Apache default port configuration filepath....!") 
		return 0
	}

	for line in apache_port_file
	{
		if line.starts_with("Listen") {
			return line.split(" ")[1].trim_space().int()
		}
	}

	return 0
}