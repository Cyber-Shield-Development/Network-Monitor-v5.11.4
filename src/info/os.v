module info

import os

pub struct OS
{
	pub mut:
		name		string
		kernel		string
		version 	string
		shell		string
}

pub fn grab_os_info() OS
{
	mut o := OS{}
	o.parse_os()
	o.retrieve_kernel()
	o.retrieve_shell()

	return o
}


pub fn (mut o OS) parse_os()
{
	os_info := os.read_file("/etc/os-release") or { 
		print("[!] Error - kOeDSe5R0pz1, Unable to read file....!")
		exit(0)
	}
	for line in os_info.split("\n")
	{
		if line.starts_with("NAME=\"") { o.name = line.replace("NAME=\"", "").replace("\"", "") }
		if line.starts_with("VERSION_ID=\"") { o.version = line.replace("VERSION_ID=\"", "").replace("\"", "") }
	}
}

pub fn (mut o OS) retrieve_kernel()
{
	version_file := os.read_file("/proc/version") or {
		print("[!] Error - uD1DMjcsINIR, Unable to read file....!\n")
		exit(0)
	}
	o.kernel = version_file.split(" ")[2]
}

pub fn (mut o OS) retrieve_shell()
{
	o.shell = os.environ()['SHELL']
}