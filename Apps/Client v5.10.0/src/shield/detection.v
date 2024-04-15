module shield

import os
import time

import src.shield.utils
import src.shield.utils.term
import src.shield.info.net
import src.shield.info.net.netstat as ns
import src.shield.info.net.tcpdump as td

pub fn (mut c CyberShield) start_detection()
{
	/* Start the UI if enabled */
	c.graph = term.graph_init__(c.config.ui.graph_layout,  c.config.ui.graph.data_heigth, c.config.ui.graph.data_width)
	c.bits_graph = term.graph_init__(c.config.ui.bits_graph_layout,  c.config.ui.bits_graph.data_heigth, c.config.ui.bits_graph.data_width)
	c.bytes_graph = term.graph_init__(c.config.ui.bytes_graph_layout,  c.config.ui.bytes_graph.data_heigth, c.config.ui.bytes_graph.data_width)
	for 
	{
		c.tick++
		c.current_time = utils.current_time()

		go net.fetch_pps_info(mut &c.network)
		go net.get_nload_info(mut &c.network)
		go set_tcpdump_vars(mut &c)
		
		c.network.netstat_cons = ns.grab_cons()
		go do(mut c, c.network.pps) // Render Graph
		go do_bits(mut c, c.network.mbits_ps) // Render Graph
		go do_bytes(mut c, c.network.mbytes_ps) // Render Graph

		chk_stage_one 		:= c.config.protection.detect_stage_one(c.network.pps, c.retrieve_unique_cons().len)
		chk_stage_two 		:= c.config.protection.detect_stage_two(c.network.pps, c.network.netstat_cons.len, c.retrieve_unique_cons().len, c.current_dump.blocked_cons.len)
		chk_stage_three 	:= c.config.protection.detect_stage_three(c.network.pps)

		println("[${c.current_time}] Max PPS: ${c.config.protection.max_pps} | Max Cons: ${c.config.protection.max_connections}")
		println("[${c.current_time}] PPS: ${c.network.pps} | Cons: ${c.network.netstat_cons.len} | Unique: ${c.retrieve_unique_cons().len} | Blocked: ${c.current_dump.blocked_cons.len} | Blocked_t2: ${c.current_dump.blocked_t2_cons.len} Dropped: ${c.current_dump.dropped_cons.len}")
		println("[${c.current_time}] Stage 1: ${chk_stage_one}/${c.is_filter1_running()} | Stage 2: ${chk_stage_two}/${c.is_filter2_running()} | Stage 3: ${chk_stage_three}/${c.is_drop_running()}")
		
		if !c.is_filter1_running() && chk_stage_one {
			/* Ensure user has access to the filter system */
			if !c.settings.filter_access {
				// c.new_err_log("cybershied.start_detection(mut c CyberShield)", "filter_1_access", "User has no access to the filter_1 system")
				continue
			}

			// Start filter_1 system
			c.toggle_filter1()
		}

		if !c.is_filter2_running() && chk_stage_two {
			if !c.settings.filter_access {
				// c.new_err_log("cybershied.start_detection(mut c CyberShield)", "filter_2_access", "User has no access to the filter_2 system")
				continue
			}

			// Start filter_2 system
			c.toggle_filter2()
		}

		if !c.is_drop_running() && chk_stage_three {
			if !c.settings.drop_access {
				// c.new_err_log("cybershied.start_detection(mut c CyberShield)", "drop_access", "User has no access to the drop system")
				continue
			}

			// Start dropping connections
			c.toggle_drop()
		}

		/* Attack has stopped */
		if c.under_attack && (!c.is_filter1_running() && !c.is_filter2_running() && !c.is_drop_running()) {
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
				// Create Dump File
			}

			// Send discord notification
			if c.settings.notification_access {
				// Send discord notification
			}
			
			c.restart_attack_filter()
		}

		/* Used to temporarily whitisted established connection when an attack is caught on the next loop */
		c.config.protection.last_cons = c.network.netstat_cons
		time.sleep(1*time.second)
	}
}

pub fn do(mut c CyberShield, pps int) {
	c.graph.append_to_graph(pps) or { return }
}

pub fn do_bits(mut c CyberShield, pps int) {
	c.bits_graph.append_to_graph(pps) or { return }
}

pub fn do_bytes(mut c CyberShield, pps int) {
	c.bytes_graph.append_to_graph(pps) or { return }
}

pub fn (mut c CyberShield) restart_attack_filter() 
{
	c.current_dump.dump_file()
	c.under_attack = false
	c.filter_one_mode = false
	c.filter_two_mode = false
	c.drop_mode = false
	c.current_dump = Dump{}
}

pub fn (mut c CyberShield) is_protection_running() bool 
{
	if c.is_filter1_running() || c.is_filter2_running() || c.is_drop_running() {
		return true
	}
	return false
}

pub fn (mut c CyberShield) is_filter1_running() bool
{ return c.filter_one_mode }

pub fn (mut c CyberShield) toggle_filter1()
{ 
	if c.filter_one_mode { 
		c.filter_one_mode = false 
	} else { 
		c.under_attack = true
		c.filter_one_mode = true 
		go filter_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
		}
	} 
}

pub fn (mut c CyberShield) is_filter2_running() bool
{ return c.filter_two_mode }

pub fn (mut c CyberShield) toggle_filter2()
{ 
	if c.filter_two_mode { 
		c.filter_two_mode = false
	} else { 
		c.under_attack = true
		c.filter_two_mode = true 
		go advanced_filter_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
		}
	} 
}

pub fn (mut c CyberShield) is_drop_running() bool
{ return c.drop_mode }

pub fn (mut c CyberShield) toggle_drop()
{ 
	if c.drop_mode { 
		c.drop_mode = false 
	} else { 
		c.under_attack = true
		c.drop_mode = true
		go drop_mode(mut &c, c.tick)

		if c.current_dump == Dump{} { 
			c.current_dump = start_new_dump(c.network_interface, c.network.system_ip, c.network.location, c.network.isp, c.current_time)
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

pub fn set_tcpdump_vars(mut c CyberShield) 
{
	// Detecting if the Host/IP request is outbound by validating source_ip, it should be the server's complete hostname or IPv4
	// TCPDump by default uses your full hostname instead of an IPV4 or IPV6
	// Format example below ( from and to is seperated with a right-arrow '>' )
	// When the request from the same inbound IP is first and our hostname/ipv4 is second, that means the server recieved the request
	// Time IP From_hostname > To_hostname Flags [.p] Other_Data
	net.get_tcpdump_data(mut &c.network)
	for mut con in c.network.tcpdump_req {
		if con.source_ip in [c.config.protection.server_hostname, c.config.protection.server_ipv4, c.config.protection.server_ipv6]  {
			con.req_direction = td.ConnectionDirection.outbound
		} else { con.req_direction = td.ConnectionDirection.inbound }
	}
}