module shield

import os
import time

import src.shield.info.net.tcpdump as td
import src.shield.info.net.netstat as ns

/*
*	[@DOC]
*	pub fn filter_mode(mut c CyberShield, current_tick int)
*
*	- Block all connections that is spamming the server with request/s
*/
pub fn filter_mode(mut c CyberShield, current_tick int) {
	c.config.protection.temporary_whitlist_cons(mut c.network.netstat_cons)
	for 
	{

		for mut con in c.network.netstat_cons
		{
			/* Filter Mode Toggle */
			if c.config.protection.is_stage_one_done(c.network.pps, c.random_cons_count()) { 
				c.toggle_filter1()
				return 
			}
			
			mut chk, _ := c.config.protection.inspect_connection(mut con, mut td.TCPDump{})
			if !chk { continue }

			mut service := c.config.protection.grab_port_info(con.internal_port)
			c.current_dump.block_con(mut con, mut service)
		}
		
		os.execute("sudo iptables-save; sudo ip6tables-save")
		c.config.protection.temporary_whitlist_cons(mut c.network.netstat_cons)
		// println("[ + ] (FILTER;${current_tick}:${c.tick}) ${c.current_dump.blocked_cons.len} Connections blocked. Checking if attack has stopped or block more connections.....!")
		time.sleep(1*time.second)
	}
}

/*
*	[@DOC]
*	pub fn advanced_filter_mode(mut c CyberShield, current_tick int)
*
*	- Block all connections that is spamming the server with request/s
*/
pub fn advanced_filter_mode(mut c CyberShield, current_tick int) {
	for 
	{
		c.retrieve_tcpdump_req()

		for mut con in c.network.tcpdump_req
		{
			/* Filter Mode Toggle */
			if c.config.protection.is_stage_two_n_three_done(c.network.pps) { 
				c.toggle_filter2()
				return 
			}

			mut chk, _ := c.config.protection.inspect_connection(mut ns.NetstatCon{}, mut con)
			if !chk { continue }

			/* Block block block */
			mut service := c.config.protection.grab_port_info(con.source_port)
			c.current_dump.adv_block_con(mut con, mut service)
		}

		os.execute("sudo iptables-save; sudo ip6tables-save")
		c.config.protection.temporary_whitlist_cons(mut c.network.netstat_cons)
		// println("[ + ] (ADVANCED_FILTER;${current_tick}:${c.tick}) ${c.current_dump.blocked_t2_cons.len} Connections blocked. Checking if attack has stopped or block more connections.....!")
	}
}

/*
*	[@DOC]
*	pub fn drop_mode(mut c CyberShield, current_tick int)
*
*	- Drop all connection within a port that isn't whitelisted or on
*	  a port that isn't being serviced.
*/
pub fn drop_mode(mut c CyberShield, current_tick int)
{
	for 
	{
		/* Disable and exit when attack has end */
		if c.config.protection.is_stage_two_n_three_done(c.network.pps) { 
			c.toggle_drop()
			return 
		}

		/* Detect Attacked Ports */
		for mut con in c.network.netstat_cons 
		{
			/* Skip if whitelisted, port serviced, or already dropped */
			if c.config.protection.is_con_whitlisted(con.external_ip) || c.current_dump.is_con_dropped(con.external_ip) || c.config.protection.is_port_serviced(con.internal_port) { continue }

			c.current_dump.dropped_cons << con
			os.execute("fuser -k ${con.internal_port}/tcp; service ssh restart > /dev/null")
		}
		// println("[ X ] (FILTER;${current_tick}:${c.tick}) ${c.current_dump.dropped_cons.len} Connection were blocked. Checking if attack has stopped or block more connections.....!")
		time.sleep(1*time.second)
	}
}

pub fn block_ipv4(ip string, network_ipv4 string) {
	if ip != network_ipv4 {
		return
	}
	os.execute("sudo iptables -A INPUT -s ${ip} -j DROP; sudo iptables -A OUTPUT -s ${ip} -j DROP")
}