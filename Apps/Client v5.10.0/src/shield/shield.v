module shield

import os
import time

import src.shield.info.net
import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub fn filter_mode(mut c CyberShield, current_tick int)
{
	for 
	{
		/* Filter Mode Toggle */
		if !c.config.protection.detect_stage_one(c.network.pps, c.retrieve_unique_cons().len) { 
			c.toggle_filter1()
			return 
		}

		for mut con in c.network.netstat_cons
		{
			/* Skip if connection is whitlisted (DO NOT BLOCK OR DROP) */
			if c.config.protection.is_con_whitlisted(con.external_ip) { continue }

			/* Skip if connection has already been blocked */
			if c.current_dump.is_con_blocked(mut con) { continue }
			
			if con.ip_t == ns.IP_T.ipv4 {
				os.execute("sudo iptables -A INPUT -s ${con.external_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.external_ip} -p tcp -j DROP")
			} else {
				os.execute("sudo ip6tablesln -A INPUT -s ${con.external_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.external_ip} -j DROP")
			}
		}
		
		os.execute("sudo iptables-save; sudo ip6tables-save")
		println("[ + ] (FILTER;${current_tick}:${c.tick}) ${c.current_dump.blocked_cons.len} Connections blocked. Checking if attack has stopped or block more connections.....!")
		time.sleep(1*time.second)
	}
}

pub fn advanced_filter_mode(mut c CyberShield, current_tick int)
{
	for 
	{
		/* Filter Mode Toggle */
		if !c.config.protection.detect_stage_two(c.network.pps, c.network.netstat_cons.len, c.retrieve_unique_cons().len, c.current_dump.blocked_t2_cons.len) { 
			c.toggle_filter2()
			return 
		}

		for mut con in c.network.tcpdump_req
		{
			/* Skip if the connection is whitelisted */
			if c.config.protection.is_con_whitlisted(con.source_ip) { continue }

			/* Add pkt data of a possible connection attacking the network and skip if already blocked */
			c.current_dump.append_pkt_data(con.source_ip, con.retrieve_data())
			if c.current_dump.is_con_blocked2(mut con) { continue }

			/* Block block block */
			if con.req_direction == .outbound && con.hostname_t == .ipv4  {
				os.execute("sudo iptables -A INPUT -s ${con.source_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.source_ip} -p tcp -j DROP")
			} else if con.req_direction == .outbound && con.hostname_t == .ipv6 {
				os.execute("sudo ip6tables -A INPUT -s ${con.source_ip} -j DROP; sudo ip6tables -A OUTPUT -s ${con.source_ip} -j DROP")
			}
		}
		os.execute("sudo ip6tables-save; sudo ip6tables-save")
		println("[ + ] (ADVANCED_FILTER;${current_tick}:${c.tick}) ${c.current_dump.blocked_t2_cons.len} Connections blocked. Checking if attack has stopped or block more connections.....!")
		time.sleep(2*time.second)
	}
}

pub fn drop_mode(mut c CyberShield, current_tick int)
{
	for 
	{
		/* Drop Mode Toggle */
		if !c.config.protection.detect_stage_three(c.network.pps) { 
			c.toggle_drop()
			return 
		}

		for mut con in c.network.netstat_cons 
		{
			/* Skip if connection is whitlisted (DO NOT BLOCK OR DROP) */
			if c.config.protection.is_con_whitlisted(con.external_ip) { continue }

			/* Skip if connection has already been blocked */
			if c.current_dump.is_con_dropped(con.external_ip) { continue }

			/* Skip if port is whitlisted */
			if c.config.protection.is_port_whitlisted(con.internal_port) { continue }

			c.current_dump.dropped_cons << con
			
			// Find PID or Kill Port
			if con.pid_n_process.split("/")[0].int() > 0 { 
				println("Connection Detected to be attached to an on-going process(${con.pid_n_process.split('/')[0]}): ${con.pid_n_process}")
				// os.execute("kill ${con.pid_n_process.split('/')[0]}")
			} else {
				os.execute("fuser -k ${con.internal_port}/tcp; service ssh restart > /dev/null")
			}
		}
		println("[ X ] (FILTER;${current_tick}:${c.tick}) ${c.current_dump.dropped_cons.len} Connection were blocked. Checking if attack has stopped or block more connections.....!")
		time.sleep(1*time.second)
	}
}