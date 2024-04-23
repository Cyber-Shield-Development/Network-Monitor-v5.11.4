module shield

import os
import time
import arrays

import src.shield.utils
import src.shield.utils.term
import src.shield.info.net
import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub fn (mut c CyberShield) start_detection()
{
	/* Start the UI if enabled */
	c.graph = term.graph_init__(c.config.ui.graph_layout)
	c.bits_graph = term.graph_init__(c.config.ui.bits_graph_layout)
	c.bytes_graph = term.graph_init__(c.config.ui.bytes_graph_layout)
	for 
	{
		c.tick++
		c.current_time = utils.current_time()

		/* Retrieve Network Information */
		go net.fetch_pps_info(mut &c.network)
		c.network.netstat_cons = ns.grab_cons()

		/* Append data and render graph */
		go do(mut c, c.network.pps) // Render PPS Graph
		go do_bits(mut c, c.network.mbits_ps.str().int()) // Render MBIT/s Graph
		go do_bytes(mut c, c.network.mbytes_ps.str().int()) // Render MBYTE/S Graph

		/* Get DDOS Detection Status */
		chk_stage_one 		:= c.config.protection.detect_stage_one(c.network.pps, c.retrieve_unique_cons().len)
		chk_stage_two 		:= c.config.protection.detect_stage_two(c.network.pps, c.network.netstat_cons.len, c.retrieve_unique_cons().len, c.current_dump.blocked_cons.len)
		chk_stage_three 	:= c.config.protection.detect_stage_three(c.network.pps)

		/* Handle DDOS Attack */
		if !c.is_filter1_running() && chk_stage_one && c.settings.filter_access {
			c.toggle_filter1()
		}

		if !c.is_filter2_running() && chk_stage_two && c.settings.filter_access {
			c.toggle_filter2()
		}

		if !c.is_drop_running() && chk_stage_three && c.settings.drop_access {
			c.toggle_drop()
		}

		/* Attack has stopped */
		if c.under_attack && !c.is_protection_running() {
			/* Reset IPTables if enabled via config */
			if c.config.protection.reset_tables {
				go os.execute("iptables -F")
			}

			/* Add all user's rules after reseting IPTables */
			if c.config.protection.auto_add_rules {
				c.config.protection.add_personal_rules()
			}

			// Create dump file
			if c.settings.dump_access {
				c.last_attack_time = c.current_time
				c.current_dump.dump_file(c.last_attack_time, mut &c)
			}

			// Send discord notification
			if c.settings.notification_access {
				c.post_discord_log("The current attack has end......!")
			}
			
			c.restart_attack_filter()
		}

		/* Used to temporarily whitisted established connection when an attack is caught on the next loop */
		c.config.protection.last_cons = c.network.netstat_cons
		time.sleep(1*time.second)
	}
}

/*
*
*	[ Graph Functionalities ]
*
*/
pub fn do(mut c CyberShield, pps int) {
	c.graph.append_to_graph(pps) or { return }
}

pub fn do_bits(mut c CyberShield, pps int) {
	c.bits_graph.append_to_graph(pps) or { return }
}

pub fn do_bytes(mut c CyberShield, pps int) {
	c.bytes_graph.append_to_graph(pps) or { return }
}

/*
*
*	[ Detection && Protection Controls ]
*
*/

/*
*	[@DOC]
*	pub fn (mut c CyberShield) restart_attack_filter()
*
*	- Disable attack mode, all protection stages.
*	- Restart dump
*/
pub fn (mut c CyberShield) restart_attack_filter() 
{
	c.config.protection.temporary_whitelist = []string{}
	c.under_attack = false
	c.filter_one_mode = false
	c.filter_two_mode = false
	c.drop_mode = false
	c.current_dump = Dump{}
}

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) is_protection_running() bool 
*
*	- Detect if any of the protection stages are running.
*/
pub fn (mut c CyberShield) is_protection_running() bool 
{
	if c.is_filter1_running() || c.is_filter2_running() || c.is_drop_running() {
		return true
	}
	return false
}

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) is_filter1_running() bool
*
*	Check if filter 1 protection is running.
*/
pub fn (mut c CyberShield) is_filter1_running() bool
{ return c.filter_one_mode }

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) toggle_filter1()
*
*	Disable or enable filter 1 based of its power toggle settings
*	Trigger the filter 1 to start
*	Restart dump if needed for the new attack
*/
pub fn (mut c CyberShield) toggle_filter1()
{ 
	if c.filter_one_mode { 
		c.filter_one_mode = false 
	} else { 
		c.under_attack = true
		c.filter_one_mode = true 
		go filter_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			if c.settings.notification_access { c.post_discord_log("An attack has started......!") }
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
		}
	} 
}

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) is_filter2_running() bool
*
*	Check if filter 2 protection is running.
*/
pub fn (mut c CyberShield) is_filter2_running() bool
{ return c.filter_two_mode }

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) toggle_filter2()
*
*	Disable or enable filter 2 based of its power toggle settings
*	Trigger the filter 2 to start
*	Restart dump if needed for the new attack
*/
pub fn (mut c CyberShield) toggle_filter2()
{ 
	if c.filter_two_mode { 
		c.filter_two_mode = false
	} else { 
		c.under_attack = true
		c.filter_two_mode = true 
		go advanced_filter_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			if c.settings.notification_access { c.post_discord_log("An attack has started......!") }
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
		}
	} 
}

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) is_drop_running() bool
*
*	Check if drop mode protection is running.
*/
pub fn (mut c CyberShield) is_drop_running() bool
{ return c.drop_mode }

/* 
*	[@DOC]
*	pub fn (mut c CyberShield) toggle_drop()
*
*	Disable or enable filter 2 based of its power toggle settings
*	Trigger the filter 2 to start
*	Restart dump if needed for the new attack
*/
pub fn (mut c CyberShield) toggle_drop()
{ 
	if c.drop_mode { 
		c.drop_mode = false 
	} else { 
		c.under_attack = true
		c.drop_mode = true
		go drop_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			if c.settings.notification_access { c.post_discord_log("An attack has started......!") }
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
		}
	} 
}

/* 
*
*	[ Network Information Retrieving & Parsing ]
*
*/

pub fn (mut c CyberShield) retrieve_tcpdump_req()
{
	go os.execute("timeout 1.2 tcpdump -i ens3 -x -n ip > ipv4_dump.shield")
	os.execute("timeout 1.2 tcpdump -i ens3 -x -n ip6 > ipv6_dump.shield")

	ipv4_dump := os.read_lines("ipv4_dump.shield") or { [] }
	ipv6_dump := os.read_lines("ipv6_dump.shield") or { [] }
	full_dump := arrays.merge(ipv4_dump, ipv6_dump)
	
	if full_dump == [] {
		println("[ X ] Error, No TCPDump Req has been found. This shouldn't happen....!\r\n")
	}

	for line in full_dump {
		mut reqbound := td.ConnectionDirection.inbound
		line_args := line.split(" ")

		/* Detection for a new connection line */
		if !line.starts_with(" ") && line_args.len > 8 {
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
			

			if !utils.is_hostname_valid(from_addr) { continue }
			if from_addr == c.config.protection.server_ipv4 || from_addr == c.config.protection.server_ipv6 || from_addr == c.config.protection.server_hostname {
				reqbound = td.ConnectionDirection.outbound
			}

			c.network.tcpdump_req << td.new_req(line_args, [from_addr, from_port], [to_addr, to_port], reqbound)
		} else {
			if c.network.tcpdump_req.len > 0 {
				c.network.tcpdump_req[c.network.tcpdump_req.len-1].pkt_data << line.trim_space()
			}
		}
	}
}

/*
*	[@DOC]
*	- Retrieve a unique a list of connections excluding whitlisted
* 	  connections or temporary whitlisted IPs
*/
pub fn (mut c CyberShield) retrieve_unique_cons() []ns.NetstatCon
{
	mut cons := []ns.NetstatCon{}
	for con in c.network.netstat_cons 
	{
		if !c.config.protection.is_con_whitlisted(con.external_ip) && con !in cons  {
			cons << con
		}
	}

	return cons
}

pub fn (mut c CyberShield) post_discord_log(data string) {
	/* Send attack data to discord */
	fields := {
		"{CONTENT_DATA}": "${data}",
		"{IP_ADDRESS}": "${c.config.protection.server_ipv4}",
		"{LOCATION}": "Canada",
		"{PROVIDER}": "OVH",
		"{CONS_CONNECTED}": "${c.network.netstat_cons.len}",
		"{INCOMING_REQ}": "${c.network.tcpdump_req.len}",
		"{UNDER_ATTACK}": "${c.under_attack}",
		"{STAGE_1_MODE}": "${c.filter_one_mode}",
		"{STAGE_2_MODE}": "${c.filter_two_mode}",
		"{STAGE_3_MODE}": "${c.drop_mode}",
		"{BLOCKED_1_IPS}": "${c.current_dump.blocked_cons.len.str()}",
		"{BLOCKED_2_IPS}": "${c.current_dump.blocked_t2_cons.len.str()}",
		"{ABUSED_PORT}": "${c.current_dump.abused_ports.len}",
		"{START_TIME}": "${c.current_dump.start_time}",
		"{END TIME}": "${c.current_dump.end_time}",
		"{CURRENT_TIME}": "${c.current_time}"
	}
	utils.send_discord_msg(fields)
}