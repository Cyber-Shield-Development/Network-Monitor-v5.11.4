module info

import os
import net.http

pub struct Connection
{
	pub mut:
		iface		string
		system_ip	string
		max_pps		int
		pps			int
		upload		string
		download	string
		ms			string

		curr 		string
		avg			string
		min 		string
		max 		string
		ttl 		string
}

pub fn connection(iface string) Connection
{
	mut c := Connection{
		iface: iface
		system_ip: http.get_text("https://api.ipify.org")
	}
	c.get_ping_ms()
	c.get_connection_speed()
	return c
}

/* 
*	Get connection ping MS (millseconds) 
*/
pub fn (mut c Connection) get_ping_ms()
{
	ping_results := os.execute("timeout 1 ping 1.1.1.1").output.split("\n")

	if ping_results.len > 0 {
		c.ms = ping_results[1].split(" ")[(ping_results[1].split(" ").len-2)].replace("time=", "")
	}
}

/* 
*	Get upload/download speed 
*/
pub fn (mut c Connection) get_connection_speed()
{
	speed_results := os.execute("/usr/bin/speedtest").output

	for line in speed_results.split("\n")
	{
		if line.trim_space().starts_with("Download:") {
			c.download = line.trim_space().replace("Download:", "").trim_space()
		} else if line.trim_space().starts_with("Upload:") {
			c.upload = line.trim_space().replace("Upload:", "").trim_space()
		}
	}
}

/* 
* 	Used in the socket display function 
*/
pub fn get_nload_info(mut c Connection) 
{
	os.execute("timeout 1 nload ${c.iface} -m -u m > t.txt").output
	
	lines := os.read_lines("t.txt") or { [] }
	for line in lines 
	{

		if line.contains("Curr:") {
			c.curr = line.split(' ')[1].trim_space() + " MBit/s"
		} else if line.contains("Avg:") {
			c.avg = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Min:") {
			c.min = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Max:") {
			c.max = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Ttl:") {
			c.ttl = line.split(" ")[1].trim_space() + " MBit/s"
			break
		}
	}
}