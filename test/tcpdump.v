import os 
import time
import arrays

import src.shield.utils
import src.shield.info.net.tcpdump as td

fn main() 
{
	parse_tcpdump()
}

fn parse_tcpdump() {
	go os.execute("timeout 1.2 tcpdump -i ens3 -x -n ip > ipv4_dump.shield")
	os.execute("timeout 1.2 tcpdump -i ens3 -x -n ip6 > ipv6_dump.shield")

	ipv4_dump := os.read_lines("ipv4_dump.shield") or { [] }
	ipv6_dump := os.read_lines("ipv6_dump.shield") or { [] }
	full_dump := arrays.merge(ipv4_dump, ipv6_dump)
	
	if full_dump == [] {
		println("[ X ] Error, No TCPDump Req has been found. This shouldn't happen....!\r\n")
	}

	mut reqs := []td.TCPDump{}
	for line in full_dump {
		mut reqbound := td.ConnectionDirection.inbound
		line_args := line.split(" ")
		if line_args.len < 8 || line.starts_with("tcpdump") || line.starts_with("listening") { continue }

		/* Detection for a new connection line */
		println("[ + ] Parsing: ${line_args}")
		if !line.starts_with(" ") && line_args[1] == "IP" {
			_ := line_args[2] // from_raw_addr
			from_args := line_args[2].split(".")

			_ := line_args[4] // to_raw_addr
			to_args := line_args[4].split(".")

			from_addr := utils.arr2ip(from_args[0..(from_args.len-1)])
			mut from_port := from_args[from_args.len-1] 

			to_addr := utils.arr2ip(to_args[0..(to_args.len-1)])
			mut to_port := to_args[to_args.len-1].replace(":", "")
			
			if from_port == "http" { from_port = "80" }
			if to_port == "http" { to_port = "80" }
			
			println("[ + ] Detected as a new request => ${from_addr}....!")
			if !utils.is_hostname_valid(from_addr) { continue }
			if from_addr == "192.99.69.164" { reqbound = td.ConnectionDirection.outbound }

			reqs << td.new_req(line_args, [from_addr, from_port], [to_addr, to_port], reqbound)
			continue
		}
		
		if reqs.len > 0 {
			println("[ + ] Added packet data to ${reqs[reqs.len-1].destination_ip}....!")
			reqs[reqs.len-1].pkt_data << line.trim_space()
		}
	}

	for mut req in reqs {
		println(req.to_str())
	}
}

pub fn current_time() string {
	return "${time.now()}".replace("-", "/").replace(" ", "-")
}