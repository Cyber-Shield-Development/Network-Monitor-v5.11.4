module src

import os
import time
import shield.utils

/* 
*	- Filtering System, Blocking unwanted IPs
*/
pub fn (mut c CyberShield) filter(tick int)
{
	current_time := "${time.now()}".replace("-", "_").replace(" ", "_")

	/* Send starting attack data to discord */
	fields := {
		"{CONTENT_DATA}": "A new attack has started",
		"{IP_ADDRESS}": "${c.conn_info.system_ip}",
		"{LOCATION}": "Canada",
		"{PROVIDER}": "OVH",
		"{CONS_CONNECTED}": "${c.ips.len}",
		"{UNDER_ATTACK}": "${c.under_attack}",
		"{FILTERING_CON_MODE}": "${c.filtering_con_mode}",
		"{DROP_CON_MODE}": "${c.drop_con_mode}",
		"{BLOCKED_IPS}": "${c.blocked_ips.len}",
		"{ABUSED_PORT}": "${c.abused_port.len}",
		"{CURRENT_TIME}": "${current_time}",
	}
	utils.send_discord_msg(fields)

	for {

		if c.pps < c.max_pps && c.ips.len < c.max_connections {
			println("${utils.success_sym} [FILTER;${tick}/${c.tick}] Attack seems to be be finished...\r\n\t=> Filtering system blocked ${c.blocked_ips.len} connections....\r\n\t=> Exiting the drop system.")
			c.filtering_con_mode = false
			return 
		}

		/* Block Unwanted IPs */
		for con in c.ips {
			/* Skip if IP is protected */
			if con.external_ip in c.cfg_protected_ip { continue }
			/* Skip, if IP already has been blocked, Avoid dup rules */
			if con.external_ip in c.blocked_ips { continue }

			c.blocked_ips << con.external_ip

			if validate_ipv4_format(con.external_ip) {
				os.execute("sudo iptables -A INPUT -s ${con.external_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.external_ip} -p tcp -j DROP")
			} else {
				os.execute("sudo ip6tables -A INPUT -s ${con.external_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.external_ip} -j DROP")
			}
			println("${utils.failed_sym} [FILTER;${tick}/${c.tick}] Blocking Possible IP Attacking ${con.external_ip}....!")
		}
		os.execute("sudo iptables-save; sudo ip6tables-save")
		println("${utils.failed_sym} [FILTER;${tick}/${c.tick}] Sleeping for 1 seconds to determine if attack is still going....")
		time.sleep(1*time.second)
	}
}

/*
* 	[EMERGENCY MODE] [THREADED]
* 	- Start pinging and detect more than 5 steady timeout
*/
pub fn (mut c CyberShield) check_if_offline() 
{
	/* new way of detecting if server is lagging or offline */
	for 
	{
		/* Exit when attack is done */
		if (!c.under_attack && !c.filtering_con_mode && !c.drop_con_mode) || !c.tcpdumping { break }
		ping_data := os.read_file("ping.txt") or { continue }
		timeouts := c.count_timeouts(ping_data)
		if timeouts > 5 {

		}
		time.sleep(1*time.second)
	}
}

pub fn (mut c CyberShield) count_timeouts(data string) int 
{
	mut cnt := 0
	mut steady := false
	for line in data.split("\n")
	{
		if line.trim_space() == "ping: sendmsg: Operation not permitted" {
			println("${utils.failed_sym} [WANRING] The server has timed out....!")
			exit(0)
			cnt++
		}

		/* Emenrgency mode */
		if steady && cnt > 5 {
			println("${utils.failed_sym} The server seems to be offline....")
		}
		time.sleep(1*time.second)
	}

	return cnt
}

/*
*	TCPdump and Drop/Block Connections
*/
pub fn (mut c CyberShield) tcpdump_n_drop(tick int)
{
	for { 

		/* Exit when attack is done */
		if c.ips.len < c.max_connections || c.pps <= c.max_pps { c.tcpdumping = false break }

		data := os.read_file("raw_pcap.txt") or {
			println("${utils.failed_sym} [TCPDUMP;${tick}/${c.tick}] Error, Something went wrong with tcpdump....!")
			return
		}

		for line in data.split("\n")
		{
			if line.len < 3 { continue }
			if line.contains(">") && line.contains(":") {
				address_info := line.split(">")[1].split(":")[0].trim_space()
				port := address_info.split(".")[address_info.split(".").len-1]
				ip_address := address_info.replace(".${port}", "")


				/* Skip cons on ports running services and legitimate user IPs allowed to the server */
				if ip_address in c.cfg_protected_ip { continue }
				if port.int() in c.cfg_protected_port { continue }

				/* Skip connection if its already blocked */
				if ip_address in c.blocked_ips { continue }

				/* Block block block */
				if validate_ipv4_format(ip_address) && !ip_address.contains(".com") && !ip_address.contains(".net") && !ip_address.contains("-") {
					os.execute("sudo iptables -A INPUT -s ${ip_address} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${ip_address} -p tcp -j DROP")
				} else if ip_address.split(":").len > 2 && !ip_address.contains(".com") && !ip_address.contains(".net") && !ip_address.contains("-") {
					os.execute("sudo ip6tables -A INPUT -s ${ip_address} -j DROP; sudo ip6tables -A OUTPUT -s ${ip_address} -j DROP")
				}
				println("${utils.success_sym} [TCPDUMP;${tick}/${c.tick}] Blocking Possible Connection Attacking: ${ip_address}:${port}")
			}
		}
		os.execute("sudo iptables-save; ip6tables-save")
		println("${utils.failed_sym} [TCPDUMP;${tick}/${c.tick}] Sleeping for 1 seconds to determine if attack is still going....")
		time.sleep(1*time.second)
	}
}

/*
*	- Drop all connections within a Port
*/
pub fn (mut c CyberShield) drop_attack(tick int)
{
	for {

		if c.pps < c.max_pps && c.ips.len < c.max_connections {
			println("${utils.success_sym} [DROP;${tick}/${c.tick}] Attack seems to be be finished...\r\n\t=> Drop system dropped ${c.blocked_ips.len} connections....\r\n\t=> Exiting the drop system.")
			c.drop_con_mode = false
			return 
		}
		for con in c.ips {
			if con.internal_port == c.cnc_port || con.internal_port !in c.server_ssh_ports { continue }
			/* 
			* 	Do not drop port unless there more than expected connection on the port (Request Spam)
			*/ 
			if con.internal_port in c.cfg_protected_port && c.count_port_used(con.internal_port) > c.max_con_per_port { 

			}

			/*
			*	Skip, IP if its in the Protected IP list
			*/
			if con.external_ip in c.cfg_protected_ip { continue }

			if con.internal_port in c.abused_port { continue }

			/* Add port to a list of abused ports */
			c.abused_port << con.internal_port
			c.dropped_cons << con.external_ip

			println("${utils.failed_sym} [DROP;${tick}] Port ${con.internal_port} being attacked....!")
			os.execute("fuser -k ${con.internal_port}/tcp; service ssh restart > /dev/null")

			println("${utils.failed_sym} [DROP;${tick}/${c.tick}] Connections on ${con.internal_port} Dropped...!")
		}
		println("${utils.failed_sym} [DROP;${tick}/${c.tick}] Sleeping for 1 seconds to determine if attack is still going....")
		time.sleep(1*time.second)
	}
}

/*
*	- Find ports being abused to drop
*/
pub fn (mut c CyberShield) get_abused_port() int {
	mut ports_used := map[int]int{}

	for con in c.ips {
		if con.internal_port !in ports_used
		{ ports_used[con.external_port] = 0 }

		ports_used[con.internal_port]++
	}

	mut abused_port := 0
	mut highest_count := 0
	for port, count in ports_used
	{
		if count > highest_count && port !in c.cfg_protected_port { 
			highest_count = count 
			abused_port = port
		}
	}

	return abused_port
}