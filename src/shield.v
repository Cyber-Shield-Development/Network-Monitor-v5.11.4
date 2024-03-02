module src

import os
import src.utils

/* 
*	- Filtering System, Blocking unwanted IPs
*/
pub fn (mut c CyberShield) filter()
{
	mut ips := c.connection_count()

	/* Block Unwanted IPs */
	for con in c.ips {
		/* Skip if IP is protected */
		if con.external_ip in c.cfg_protected_ip { continue }
		/* Skip, if IP already has been blocked, Avoid dup rules */
		if con.external_ip in c.blocked_ips { continue }

		c.blocked_ips << con.external_ip
		os.execute("sudo iptables -A OUTPUT -s ${con.external_ip} -p tcp -j DROP; sudo iptables -A OUTPUT -s ${con.external_ip} -p tcp -j DROP; sudo iptables-save")
		println("${utils.c_red}[ + ]${utils.c_default} Blocking Possible IP Attacking ${con.external_ip}....!")
	}
}

/*
*	- Drop all connections within a Port
*/
pub fn (mut c CyberShield) drop_attack()
{
	for con in c.ips {
		if con.internal_port in c.cfg_protected_port && c.count_port_used(con.internal_port) < c.max_con_per_port { continue }
		if con.external_ip in c.cfg_protected_ip { continue }
		c.abused_port << con.internal_port
		println("${utils.c_red}[ + ]${utils.c_default} ${con.internal_port} being attacked, Dropping Connections on Port ${con.internal_port}....!")
		os.execute("fuser -k ${con.internal_port}/tcp; service ssh restart > /dev/null")
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