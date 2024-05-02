module shield

import os

import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub struct Dump
{
	pub mut:
		interfacee			string
		interface_ip 		string

		location 			string
		isp 				string

		current_pps 		int 
		max_pps_reached		int
		max_mbytes_reached 	f64
		max_mbits_reached	f64
		max_cons_captured 	int
		max_rps_reached		int

		// New settings implementation
		pps_capacity		int // Pkt/s
		rps_capacity		int // Rq/s
		mbits_capcity		f64 // Mbit/s
		mbytes_capacity 	f64 // Mbyte/s

		con_count 			int // Total Connection(s) Count
		unique_cons			int // Whitelisted Connection(s)
		malicious_cons  	int // Malicious Connection(s) Attacking the Network
		

		blocked_ips 		[]string // Block IPs (Used for checking blocked cons)

		/*
		*	Log all connections and request info to ensure protection stages doesn't
		*	dup block and for packet analyzing via dump file
		*/
		blocked_cons 		[]ns.NetstatCon
		blocked_t2_cons 	[]td.TCPDump
		dropped_cons 		[]ns.NetstatCon
		abused_ports 		[]string

		captured_pkt_data 	map[string]string
		start_time 			string
		end_time 			string
}

pub fn start_new_dump(iface string, ip string, locate string, isp string, stime string) Dump 
{
	return Dump{
		interfacee: iface,
		interface_ip: ip,
		location: locate,
		isp: isp,
		blocked_cons: []ns.NetstatCon{},
		abused_ports: []string{},
		mbits_capcity: 0.0,
		mbytes_capacity: 0.0,
		captured_pkt_data: map[string]string{},
		start_time: stime
	}
}

/*
*	[@DOC]
*	pub fn (mut d Dump) append_pkt_data(ip string, pkt_data string)
*
*	- Append packet data to the general list of packet data inbound
*/
pub fn (mut d Dump) append_pkt_data(ip string, pkt_data string)
{ d.captured_pkt_data["${ip}"] = pkt_data }

pub fn (mut d Dump) is_ip_blocked(ip string) bool 
{
	if ip in d.blocked_ips { return true }

	return false 
}

/*
*	[@DOC]
*	pub fn (mut d Dump) update_current_stats(cpps int, cmbitps int, mbyteps int, cons_count int)
*
*	- Update the highest reached statistics such as pps, mbitps, mbyteps, con count etc
*/
pub fn (mut log Dump) update_current_stats(cpps int, mbitps f64, mbyteps f64, rps int) {
	if cpps > log.pps_capacity { log.pps_capacity = cpps }
	if mbitps > log.mbits_capcity { log.mbits_capcity = mbitps }
	if mbyteps > log.mbytes_capacity { log.mbytes_capacity = mbyteps }
	if rps > log.rps_capacity { log.rps_capacity = rps }
}

pub fn (mut log Dump) update_current_con_stats(con_c int, unique_c int, malicious_c int) {
	if con_c > log.con_count { log.con_count = con_c }
	if unique_c > log.unique_cons { log.unique_cons = unique_c }
	if malicious_c > log.malicious_cons { log.malicious_cons = malicious_c }
}

/*
*	[@DOC]
*	pub fn (mut d Dump) is_con_dropped(ip string) bool 
*
*	- Validate if an IP has been dropped in the drop system
*/
pub fn (mut d Dump) is_con_dropped(ip string) bool 
{
	for mut con in d.dropped_cons {
		if con.external_ip == ip { return true }
	}

	return false
}

pub fn (mut d Dump) block_con(mut con ns.NetstatCon, mut svc Service)
{
	if d.is_ip_blocked(con.external_ip) { return }
	d.blocked_ips << con.external_ip
	d.blocked_cons << con 
	d.max_cons_captured = d.blocked_cons.len

	/* Block IP */
	if svc.enable_filter || (!svc.enable_filter && svc != Service{}) {
		if con.ip_t == ns.IP_T.ipv4 {
			os.execute("sudo iptables -A INPUT -s ${con.external_ip} -j DROP; sudo iptables -A OUTPUT -s ${con.external_ip} -j DROP")
		} else if con.ip_t == ns.IP_T.ipv6 {
			os.execute("sudo ip6tables -A INPUT -s ${con.external_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.external_ip} -j DROP")
		}
	}

	/* Drop Port If not used for hosting */
	if (svc.enable_drop && svc != Service{}) || (svc == Service{}) {
		println("Port Dropped: ${svc.port}")
		os.execute("fuser -k ${con.internal_port}/tcp; service ssh restart > /dev/null")
	}

}

pub fn (mut d Dump) adv_block_con(mut con td.TCPDump, mut svc Service)
{	
	/* Block IP */
	match con.req_direction {
		.outbound {
			d.append_pkt_data(con.destination_ip, con.retrieve_data())
			if !d.is_ip_blocked(con.destination_ip) { 
				// SERVER IS REPLYING TO THE ATTACK (OUT-GOING DATA)
				if con.hostname_t == td.Protocol_T.ipv4 {
					os.execute("sudo iptables -A INPUT -s ${con.destination_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.destination_ip} -p tcp -j DROP")
				} else if con.hostname_t == td.Protocol_T.ipv6 {
					os.execute("sudo ip6tables -A INPUT -s ${con.destination_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.destination_ip} -j DROP")
				}
			}
			d.blocked_ips << con.destination_ip
		}
		.inbound {
			d.append_pkt_data(con.source_ip, con.retrieve_data())
			if !d.is_ip_blocked(con.source_ip) { 
				// INCOMING REQ/ATTACK (IN-COMING DATA)
				if con.hostname_t == td.Protocol_T.ipv4  {
					os.execute("sudo iptables -A INPUT -s ${con.source_ip} -j DROP; sudo iptables -A OUTPUT -s ${con.source_ip} -j DROP")
				} else if con.hostname_t == td.Protocol_T.ipv6 {
					os.execute("sudo ip6tables -A INPUT -s ${con.source_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.source_ip} -j DROP")
				}
				d.blocked_ips << con.source_ip
			}
		} else {}
	}

	/* Drop Port If not used for hosting */
	if (svc.enable_drop && svc != Service{}) || (svc == Service{}) {
		println("Port Dropped: ${svc.port}")
		os.execute("fuser -k ${con.source_port}/tcp; service ssh restart > /dev/null")
	}

	d.blocked_t2_cons << con
}

pub fn (mut d Dump) dump_file(current_datetime string, mut c CyberShield)
{
	d.end_time = current_datetime
	file_name := current_datetime.replace("/", "_").replace(":", "_")
	mut dump_data := "@CyberShield Dump File ${d.start_time} - ${d.end_time}\r\n[@NETWORK_INFO]\r\n{\r\n"

	// Send discord notification
	if c.settings.notification_access {
		c.post_discord_log("The current attack has end......!", "${file_name}.shield")
	}

	network_info := {
		"\tCon/s": "${c.network.netstat_cons.len}",
		"\tPkt/s Per Second": "${c.network.pps}", 
		"\tMbit/s Per Second": "${c.network.mbits_ps}", 
		"\tMbyte/s Per Second": "${c.network.mbytes_ps}"
	}

	for label, value in network_info { dump_data += "\t${label}: ${value}\r\n" }
	dump_data += "}\r\n\r\n[@ATTACK_INFO]\r\n{\r\n"

	attack_info := {
		"\tMost IP/s Captured": "${d.blocked_ips.len}",
		"\tHighest Pkt/s Per Second Captured": "${d.max_pps_reached}",
		"\tHighest Mbit/s Per Second Reached": "${d.max_mbits_reached}",
		"\tHighest Mbyte/s Per Second Reached": "${d.max_mbytes_reached}",
		"\tMost Request/s Captured & Blocked [TCPDump]": "${d.blocked_t2_cons.len.str()}",
		"\tMost Dropped Connection/s [Netstat]": "${d.blocked_cons.len.str()}"
	}

	for label, value in attack_info { dump_data += "\t${label}: ${value}\r\n" }
	dump_data += "}\r\n\r\n[@FULL_CAPTURED_PKT_DATA]\r\n{\r\n"

	for key, val in d.captured_pkt_data {
		dump_data += "\t${key}:\r\n\t${val}\r\n"
	}

	dump_data += "}\r\n\r\n[@CONS_CAPTURED]\r\n{\r\n"
	for mut con in d.blocked_cons {
		dump_data += "${con.to_str()}\r\n"
	}

	dump_data += "\r\n}\r\n\r\n[@REQUEST_PKT_DATA]\r\n{\r\n"
	for mut req in d.blocked_t2_cons {
		dump_data += "\t${req.to_str().replace('\n', '\n\t')}\r\n"
	}
	dump_data += "}\r\n"

	os.write_file("assets/dumps/${file_name}.shield", "${dump_data}") or { return }
	os.execute("cp assets/dumps/${file_name}.shield /var/www/html;  sed -r 's/\n/<br />/g' /var/www/html/${file_name}.shield; service apache2 restart")
	println("[ + ] (${c.current_time}) Attack dump file created.....!\r\n\t=> Filepath: 'assets/dumps/${file_name}.shield'...!")
}

pub fn save_tables() {
	os.execute("sudo iptables-save")
}