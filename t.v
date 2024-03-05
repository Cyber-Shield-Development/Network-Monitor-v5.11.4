import os
import src.utils

fn main() 
{
	mut unique_ips := []string{}
	mut last_logins := os.execute("last").output

	lines := last_logins.split("\n")

	for line in lines 
	{
		login_info := utils.rm_empty_elements(line.split(" "))
		if login_info.len != 10 { continue }
		chk := validate_ipv4_format(login_info[2])
		if chk { if login_info[2] !in unique_ips { unique_ips << login_info[2] } }
	}

	println("${unique_ips}".replace("['", "").replace("']", "").replace("', '", "\r\n"))
}

pub fn validate_ipv4_format(ip string) bool 
{
	args := ip.split(".")
	if args.len != 4 { return false }

	if args[0].int() < 1 && args[0].int() > 255 { return false }
	if args[1].int() < 0 && args[1].int() > 255 { return false }
	if args[2].int() < 0 && args[2].int() > 255 { return false }
	if args[3].int() < 0 && args[3].int() > 255 { return false }

	return true
}