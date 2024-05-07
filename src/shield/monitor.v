module shield

import net
import time

import src.shield.utils.term 

pub fn display_tui(mut c CyberShield, mut socket net.TcpConn) {
	// TODO: Initialize Graph 
	term.set_term_size(mut socket, c.config.ui.terminal.size[0].int(), c.config.ui.terminal.size[1].int())
	term.set_title(mut socket, c.config.ui.terminal.title)

	/* Output Layout */
	socket.write_string(term.replace_colors(c.config.ui.layout)) or { 0 } // Theme Layout
	time.sleep(50*time.millisecond)
	term.list_text(mut socket, c.config.ui.graph.layout, "${c.config.ui.graph_layout}".trim_space())

	if c.config.ui.os.display {
			term.place_text(mut socket, c.config.ui.os.os_name, c.config.ui.os.value_c, "${c.info.os.name}") // Interface
			term.place_text(mut socket, c.config.ui.os.os_version, c.config.ui.os.value_c, "${c.info.os.version}") // Interface
			term.place_text(mut socket, c.config.ui.os.os_kernel, c.config.ui.os.value_c, "${c.info.os.kernel}") // Interface
			term.place_text(mut socket, c.config.ui.os.shell, c.config.ui.os.value_c, "${c.info.os.shell}") // Interface
	}

	/* Display static output(s) */
	if c.config.ui.connection.display {
			term.place_text(mut socket, c.config.ui.connection.iface, c.config.ui.connection.value_c, "${c.network_interface}") // Interface
			term.place_text(mut socket, c.config.ui.connection.max_pps, c.config.ui.connection.value_c, "${c.config.protection.max_pps}") // Max PPS
			term.place_text(mut socket, c.config.ui.connection.max_connections, c.config.ui.connection.value_c, "${c.config.protection.max_connections}") // Max Connections
			term.place_text(mut socket, c.config.ui.connection.max_con_per_port, c.config.ui.connection.value_c, "${c.config.protection.max_con_per_port}") // Max Con Per Port
			term.place_text(mut socket, c.config.ui.connection.system_ip, c.config.ui.connection.value_c, "${c.network.system_ip}") // System IP
			term.place_text(mut socket, c.config.ui.connection.ms, c.config.ui.connection.value_c, "${c.network.ms}") // MS Response
			term.place_text(mut socket, c.config.ui.connection.upload_speed, c.config.ui.connection.value_c, "${c.network.upload}") // MS Response
			term.place_text(mut socket, c.config.ui.connection.download_speed, c.config.ui.connection.value_c, "${c.network.download}") // MS Response
			term.place_text(mut socket, c.config.ui.connection.auto_reset, c.config.ui.connection.value_c, "${c.config.protection.reset_tables}") // Reset Tables
			term.place_text(mut socket, c.config.ui.connection.auto_add_rules, c.config.ui.connection.value_c, "${c.config.protection.auto_add_rules}") // Auto Add Tables
			term.place_text(mut socket, c.config.ui.connection.personal_rules_count, c.config.ui.connection.value_c, "${c.config.protection.personal_rules.len}") // Rule(s) Count
			term.place_text(mut socket, c.config.ui.connection.protected_ip_count, c.config.ui.connection.value_c, "${c.config.protection.whitelisted_ips.len}") // Whitlisted IP(s) Count
			term.place_text(mut socket, c.config.ui.connection.protected_port_count, c.config.ui.connection.value_c, "${c.config.protection.whitelisted_ports.len}") // Whitlisted Port(s) Count
			term.place_text(mut socket, c.config.ui.connection.start_time, c.config.ui.connection.value_c, "${c.start_up_time}") // Whitlisted Port(s) Count
	}
}

pub fn display_monitor(mut c CyberShield, mut socket net.TcpConn) 
{
	
	/* Updater */
	for 
	{ 
		if c.change_theme {
			socket.write_string("${term.clear}[ + ] Changing theme, Please wait.....!\r\n") or { 0 }
			time.sleep(5*time.second)
			c.change_theme = false
		}

		term.place_text(mut socket, c.config.ui.terminal.tick, c.config.ui.connection.value_c, "${c.tick}") // PPS
		/* Ensuring a user is still connected */
		socket.write_string(" ") or {  
			c.rm_socket(mut socket)
			return // Close Thread
		}

		/* Display Network Data, DDoS Detection Etc */
		if c.config.ui.connection.display {
			term.place_text(mut socket, c.config.ui.connection.pps, c.config.ui.connection.value_c, "${c.network.pps}") // PPS
			term.place_text(mut socket, c.config.ui.connection.connection_count, c.config.ui.connection.value_c, "${c.network.netstat_cons.len}") // PPS
			term.place_text(mut socket, c.config.ui.connection.mbits_ps, c.config.ui.connection.value_c, "${c.network.mbits_ps}") // PPS
			term.place_text(mut socket, c.config.ui.connection.mbytes_ps, c.config.ui.connection.value_c, "${c.network.mbytes_ps}") // PPS
			term.place_text(mut socket, c.config.ui.connection.rps, c.config.ui.connection.value_c, "${c.network.tcpdump_req.len}") // PPS
			term.place_text(mut socket, c.config.ui.connection.filter_mode, c.config.ui.connection.value_c, "${c.is_filter1_running()}") // PPS
			term.place_text(mut socket, c.config.ui.connection.filter2_mode, c.config.ui.connection.value_c, "${c.is_filter2_running()}") // PPS
			term.place_text(mut socket, c.config.ui.connection.drop_mode, c.config.ui.connection.value_c, "${c.is_drop_running()}") // PPS
			term.place_text(mut socket, c.config.ui.connection.blocked_con_count, c.config.ui.connection.value_c, "${c.current_dump.blocked_cons.len}") // PPS
			term.place_text(mut socket, c.config.ui.connection.blocked_2_con_count, c.config.ui.connection.value_c, "${c.current_dump.blocked_t2_cons.len}") // PPS
			term.place_text(mut socket, c.config.ui.connection.dropped_con_count, c.config.ui.connection.value_c, "${c.current_dump.dropped_cons.len}") // PPS
			term.place_text(mut socket, c.config.ui.connection.current_time, c.config.ui.connection.value_c, "${c.current_time}") // Whitlisted Port(s) Count
			term.place_text(mut socket, c.config.ui.connection.last_attack_time, c.config.ui.connection.value_c, "${c.last_dump.start_time}") // Last attack time
			term.place_text(mut socket, c.config.ui.connection.last_attk_pps, c.config.ui.connection.value_c, "${c.last_dump.pps_capacity}") // Last attack PPS 
			term.place_text(mut socket, c.config.ui.connection.last_attk_rps, c.config.ui.connection.value_c, "${c.last_dump.rps_capacity}") // Last attack RPS 
			term.place_text(mut socket, c.config.ui.connection.last_attk_blocked_con_count, c.config.ui.connection.value_c, "${c.last_dump.blocked_ips.len}") // Last attack blocked cons
			term.place_text(mut socket, c.config.ui.connection.last_attk_mbyteps, c.config.ui.connection.value_c, "${c.last_dump.mbytes_capacity}") // Last attack MBPS

			if c.under_attack {
				term.place_text(mut socket, c.config.ui.connection.online_status, c.config.ui.connection.value_c, "Under Attack") // PPS
			} else {
				term.place_text(mut socket, c.config.ui.connection.online_status, c.config.ui.connection.value_c, "Online") // PPS
			}
		}

		if c.config.ui.hardware.display {
			term.place_text(mut socket, c.config.ui.hardware.cpu_usage, c.config.ui.hardware.value_c, "${c.info.hdw.cpu_usage}")
			term.place_text(mut socket, c.config.ui.hardware.cpu_usage_bar, c.config.ui.hardware.value_c, term.fill_bar(("${c.info.hdw.cpu_usage}".int() * c.config.ui.hardware.spaces_in_bar) / 100, c.config.ui.hardware.spaces_in_bar))
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.bits_graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.bits_graph.data, term.replace_colors(c.bits_graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.bits_graph.data, term.replace_colors(c.bits_graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.bytes_graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.bytes_graph.data, term.replace_colors(c.bytes_graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.bytes_graph.data, term.replace_colors(c.bytes_graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Data Grid View Of Connection(s) Connected to Server */
		if c.config.ui.conntable.display {

		}
		time.sleep(c.interval*time.second)
		/*
		*	- Reset Text on Terminal to Update
		*/
		if c.config.ui.connection.display {
			term.place_text(mut socket, c.config.ui.connection.pps, c.config.ui.connection.value_c, "          ")
			term.place_text(mut socket, c.config.ui.connection.connection_count, c.config.ui.connection.value_c, "          ") // Pkt/s PS
			term.place_text(mut socket, c.config.ui.connection.mbits_ps, c.config.ui.connection.value_c, "          ") // Mbit/s PS
			term.place_text(mut socket, c.config.ui.connection.mbytes_ps, c.config.ui.connection.value_c, "          ") // Mbyte/s PS
			term.place_text(mut socket, c.config.ui.connection.rps, c.config.ui.connection.value_c, "          ") // RPS
			term.place_text(mut socket, c.config.ui.connection.filter_mode, c.config.ui.connection.value_c, "          ") // Filter 1 Mode
			term.place_text(mut socket, c.config.ui.connection.filter2_mode, c.config.ui.connection.value_c, "          ") // Filter 2 Mode
			term.place_text(mut socket, c.config.ui.connection.drop_mode, c.config.ui.connection.value_c, "      ") // Drop Mode
			term.place_text(mut socket, c.config.ui.connection.blocked_con_count, c.config.ui.connection.value_c, "     ") // Filter 1 Blocked List
			term.place_text(mut socket, c.config.ui.connection.blocked_2_con_count, c.config.ui.connection.value_c, "     ") // Filter 2 Blocked
			term.place_text(mut socket, c.config.ui.connection.dropped_con_count, c.config.ui.connection.value_c, "     ") // Dropped List
			term.place_text(mut socket, c.config.ui.connection.online_status, c.config.ui.connection.value_c, "             ") // Online Status
		}

		if c.config.ui.hardware.display {
			term.place_text(mut socket, c.config.ui.hardware.cpu_usage, c.config.ui.hardware.value_c, "       ")
			term.place_text(mut socket, c.config.ui.hardware.cpu_usage_bar, c.config.ui.hardware.value_c, term.empty_string(c.config.ui.hardware.spaces_in_bar))
		}
	}
}

pub fn (mut c CyberShield) change_layout() {
	for mut socket in c.servers.clients {
		display_tui(mut &c, mut socket)
	}
}

/*
*	- Remove a socket once disconnected
*/
pub fn (mut c CyberShield) rm_socket(mut n net.TcpConn)
{
	mut t := 0
	for mut sock in c.servers.clients 
	{
		if sock == n { 
			println("[ X ] Socket Removed && Disconnected....")
			c.servers.clients.delete(t)
			n.close() or { return }
			return
		}
		t++
	}
}