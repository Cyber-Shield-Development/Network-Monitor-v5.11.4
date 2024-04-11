module net

import os
import time
import net.http

import src.shield.utils
import src.shield.info.net.tcpdump as td
import src.shield.info.net.netstat as ns

pub struct Network 
{
	pub mut:
		iface 			string
		system_ip 		string
		location 		string
		isp 			string
		pps 			int
		inbound_pps		int
		outbound_pps	int
		mbits_ps		int
		mbytes_ps		int
		upload			string
		download		string
		ms				string

		curr 			string
		avg				string
		min 			string
		max 			string
		ttl 			string
		ovpn_uptime 	string
		netstat_cons 	[]ns.NetstatCon
		tcpdump_req 	[]td.TCPDump

		interfaces 		map[string][]string
}

pub fn network__init(interfacee string) Network 
{
	mut n := Network{
		iface: interfacee, 
		interfaces: get_interfaces(),
		netstat_cons: ns.grab_cons(),
	}

	n.get_ping_ms()

	if interfacee == "" { n.request_interface() } 
	else if interfacee !in n.interfaces {
		println("[ X ] Error, Invalid interface provided.....!")
		exit(0)
	}
	n.system_ip = n.interfaces[interfacee][0]

	go get_nload_info(mut &n)
	get_connection_speed(mut &n)

	return n
}

pub fn get_tcpdump_data(mut n Network) {
	n.tcpdump_req = td.fetch_tcpdump()
}

pub fn (mut n Network) get_system_location()
{
	resp := http.get_text("http://ipwho.is/")

	server_state := utils.get_key_value_from_json(resp, "regionName")
	server_country := utils.get_key_value_from_json(resp, "continent")

	n.location = "${server_state},${server_country}"
	n.isp = utils.get_key_value_from_json(resp, "org")
}

/* Request user for an interface to monitor */
pub fn (mut n Network) request_interface() 
{
	input := os.input("These interfaces were found on your system.\r\n${n.interfaces}\r\nWhich one would you want to monitor?: ")

	if input == "" {
		println("[ X ] Error, No interface provided....!")
		exit(0)
	}

	if input !in n.interfaces {
		println("[ X ] Error, Invalid interface provided.")
	}

	n.iface = input
	n.system_ip = n.interfaces[input][0]
}

/* Scan for interfaces */
pub fn get_interfaces() map[string][]string
{
	mut interfaces := map[string][]string{}
	resp := os.execute("ifconfig").output

	lines := resp.split("\n")
	for i, line in lines 
	{
		if line.trim_space() == "" { continue }
		line_info := line.split(" ")
		if line_info[0].ends_with(":") && !line.starts_with(" ") {
			interfaces[line_info[0].replace(":", "")] = [utils.rm_empty_elements(lines[i+1].split(" "))[1], utils.rm_empty_elements(lines[i+2].split(" "))[1]]
		}
	}

	return interfaces
}

/* Get Response Time In MS from Ping command */
pub fn (mut n Network) get_ping_ms()
{
	ping_results := os.execute("ping 1.1.1.1 -c 1").output.split("\n")

	if ping_results.len > 0 {
		n.ms = ping_results[1].split(" ")[(ping_results[1].split(" ").len-2)].replace("time=", "")
	}
}

/* Get connection speed from Speedtest-CLI cmd-line */
pub fn get_connection_speed(mut n Network)
{
	speed_results := os.execute("/usr/bin/speedtest").output

	for line in speed_results.split("\n")
	{
		if line.trim_space().starts_with("Download:") {
			n.download = line.trim_space().replace("Download:", "").trim_space()
		} else if line.trim_space().starts_with("Upload:") {
			n.upload = line.trim_space().replace("Upload:", "").trim_space()
		}
	}
}

/* Get nload information */
pub fn get_nload_info(mut n Network) 
{
	os.execute("timeout 1 nload ${n.iface} -m -u m > temp/t.txt").output
	
	lines := os.read_lines("temp/t.txt") or { [] }
	for line in lines 
	{

		if line.contains("Curr:") {
			n.curr = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Avg:") {
			n.avg = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Min:") {
			n.min = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Max:") {
			n.max = line.split(" ")[1].trim_space() + " MBit/s"
		} else if line.contains("Ttl:") {
			n.ttl = line.split(" ")[1].trim_space() + " MBit/s"
			break
		}
	}
}

/* Fetch inbound packet count and calculate PPS */
pub fn fetch_pps_info(mut n Network)
{
	mut rx := "/sys/class/net/${n.iface}/statistics/rx_packets"
	mut tx := "/sys/class/net/${n.iface}/statistics/tx_packets"
	
	old_rx := (os.read_file(rx) or { "" }).int()
	old_tx := (os.read_file(tx) or { "" }).int()
	time.sleep(1*time.second)
	new_rx := (os.read_file(rx) or { "" }).int()
	new_tx := (os.read_file(tx) or { "" }).int()

	inbound_pps := new_rx - old_rx
	outbound_pps := new_tx - old_tx

	n.inbound_pps = inbound_pps
	n.outbound_pps = outbound_pps
	n.mbits_ps = new_rx * 8
	n.mbytes_ps = inbound_pps * n.mbits_ps / 1000000

	n.pps = inbound_pps
}