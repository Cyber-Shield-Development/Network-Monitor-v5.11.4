/*
*	- Parse all Blocked IPs into one file
*/
import os
import src
import src.config

fn main()
{
	files := os.ls("assets/dumps/") or { return }
	mut ip_list := []string{}

	for file in files 
	{
		file_data := os.read_lines("assets/dumps/${file}") or { [] }

		ips := config.get_block_data(file_data, "[@IPS_BLOCKED]").split("\n")
		for ip in ips { if ip !in ip_list { ip_list << ip } }
	}
	os.write_file("logs.txt", "${ip_list}".replace("['", "").replace("']", "").replace("', '", "\n")) or { return }
}