import os 

import src.shield.net

pub struct TCPDump
{
	timestamp 	string
	protocol 	string
}

fn main() 
{

}

fn capture_n_log_tcpdump() {
	os.execute("rm pcap_data.shield; touch pcap_data.shield")
	go os.execute("tcpdump -i ens3 -x >> pcap_data.shield")
}

fn parse_tcpdump() {
	os.execute("tcpdump -i ens3 -x > pcap_data.shield")
	tcpdump_data := os.read_lines("pcap_data.shield") or {
		println("[ - ] WARNING, Unable to read PCAP data file.....!")
		exit(0)
	}

	for line in tcpdump_data {
		line_info := line.split(" ")
		if line_info.len < 3 { continue }

		/* Detection for a new connection line */
		if !line_info.starts_with(" ") && line.info.len > 10 {

			// Hostname will always include a period for at-least the point
			from_hostname := line_info[2].split(".")
			to_hostname := line_info[2].split(".")

			from_address := line_info[2].replace(".${from_hostname[from_hostname.len-1]}", "")
			from_port := from_hostname[from_hostname.len-1]

			to_address := line_info[2].replace(".${to_hostname[to_hostname.len-1]}", "")
			to_port := to_hostname[to_hostname.len-1]
			
			

		}
	}
}

pub fn detect_hostname_t(from_address string) 
{

}