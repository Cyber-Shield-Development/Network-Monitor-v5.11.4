// TODO: 
// 		- Cyber Shield start time and uptime display 
// 		- Add a theme updaters
//	 	- Hardware Information Display
module src

import time
import shield.utils

/* 
*	- Display information to client via Socket
*/
pub fn start_displaying(mut c CyberShield, mut client Client)
{
	/* Set Terminal Settings & Display Information that doesn't constantly update */
	client.socket.set_read_timeout(time.infinite)
	println("[ + ] New socket connected")

	/* Set Terminal Title & Size */
	utils.set_term_size(mut client.socket, c.theme.term.size[0].int(), c.theme.term.size[1].int())
	utils.set_title(mut client.socket, c.theme.term.title)

	/* Output Layout */
	client.socket.write_string(utils.replace_colors(c.theme.layout)) or { 0 } // Theme Layout
	time.sleep(50*time.millisecond)
	utils.list_text(mut client.socket, c.theme.graph.layout_p, "${c.theme.graph_layout}".trim_space(), "Graph Layout") // Graph Layout
	
	/* OS Information */
	if c.theme.os.display { 
		utils.place_text(mut client.socket, c.theme.os.os_name_p, 		c.theme.os.value_c, c.os_info.name)
		utils.place_text(mut client.socket, c.theme.os.os_version_p, 	c.theme.os.value_c, c.os_info.version)
		utils.place_text(mut client.socket, c.theme.os.os_kernel_p, 	c.theme.os.value_c, c.os_info.kernel)
		utils.place_text(mut client.socket, c.theme.os.shell_p, 		c.theme.os.value_c, c.os_info.shell)
	}
	

	/* Connection Information */
	if c.theme.connection.display {
		utils.place_text(mut client.socket, c.theme.connection.download_speed_p, 		c.theme.connection.value_c, c.conn_info.download) // Download Speed
		utils.place_text(mut client.socket, c.theme.connection.upload_speed_p, 			c.theme.connection.value_c, c.conn_info.upload) // Upload Speed
		utils.place_text(mut client.socket, c.theme.connection.ms_p, 					c.theme.connection.value_c, c.conn_info.ms) // Upload Speed
		utils.place_text(mut client.socket, c.theme.connection.interface_p, 			c.theme.connection.value_c, c.interfacee) // Interface 
		utils.place_text(mut client.socket, c.theme.connection.pps_limit_p, 			c.theme.connection.value_c, "${c.max_pps}") // PPS To Filter 
		utils.place_text(mut client.socket, c.theme.connection.max_connections, 		c.theme.connection.value_c, "${c.max_connections.str()}") // PPS To Filter 
		utils.place_text(mut client.socket, c.theme.connection.auto_reset, 				c.theme.connection.value_c, "${c.reset_tables}") // Reset Tables
		utils.place_text(mut client.socket, c.theme.connection.auto_add_rules,			c.theme.connection.value_c, "${c.auto_add_rules}") // Personal Rules Count
		utils.place_text(mut client.socket, c.theme.connection.personal_rules_count,	c.theme.connection.value_c, "${c.personal_rules.len}") // Personal Rules Count
		utils.place_text(mut client.socket, c.theme.connection.protected_ip_count, 		c.theme.connection.value_c, "${c.cfg_protected_ip.len}") // Personal Rules Count
		utils.place_text(mut client.socket, c.theme.connection.protected_port_count,  	c.theme.connection.value_c, "${c.cfg_protected_port.len}") // Personal Rules Count
		if !c.hide_ip { 
			utils.place_text(mut client.socket, c.theme.connection.system_ip_p, c.theme.connection.value_c, c.conn_info.system_ip) // IP Address
			// utils.place_text(mut client.socket, c.theme.connection.socket_port_p,  		c.theme.connection.value_c, "${c.cnc_port}") // Socket Port 
		}
	}

	
	/* Constantly Update The Monitor */
	for {

		/* Ensuring a user is still connected */
		client.socket.write_string(" ") or { 
			c.rm_socket(mut client.socket) // Close Socket 
			return // Close Thread
		}

		/* Display Connection Information, DDoS Detection Settings, Attack Information */
		if c.theme.connection.display {
			utils.place_text(mut client.socket, c.theme.connection.pps_p, 				c.theme.connection.value_c, "${c.pps}") // PPS
			utils.place_text(mut client.socket, c.theme.connection.nload_curr, 			c.theme.connection.value_c, "${c.conn_info.curr}") // nload Curr
			utils.place_text(mut client.socket, c.theme.connection.nload_avg, 			c.theme.connection.value_c, "${c.conn_info.avg}") // nload Avg
			utils.place_text(mut client.socket, c.theme.connection.nload_min, 			c.theme.connection.value_c, "${c.conn_info.min}") // nload Min
			utils.place_text(mut client.socket, c.theme.connection.nload_max, 			c.theme.connection.value_c, "${c.conn_info.max}") // nload Max
			utils.place_text(mut client.socket, c.theme.connection.nload_ttl, 			c.theme.connection.value_c, "${c.conn_info.ttl}") // nload Ttl
			utils.place_text(mut client.socket, c.theme.connection.connection_count, 	c.theme.connection.value_c, "${c.ips.len}") // Connection Count
			utils.place_text(mut client.socket, c.theme.connection.under_attack, 		c.theme.connection.value_c, "${c.under_attack}") // Under Attack
			utils.place_text(mut client.socket, c.theme.connection.filter_mode, 		c.theme.connection.value_c, "${c.filtering_con_mode}") // Filter System Mode
			utils.place_text(mut client.socket, c.theme.connection.drop_mode, 			c.theme.connection.value_c, "${c.drop_con_mode}") // Drop System Mode
			utils.place_text(mut client.socket, c.theme.connection.dump_mode, 			c.theme.connection.value_c, "${c.tcpdumping}") // Dump System Mode
			utils.place_text(mut client.socket, c.theme.connection.blocked_con_count,  		c.theme.connection.value_c, "${c.blocked_ips.len}") // Personal Rules Count
			utils.place_text(mut client.socket, c.theme.connection.protected_port_count,  	c.theme.connection.value_c, "${c.abused_port.len}") // Personal Rules Count
		}

		/* Display Graph */
		if c.theme.graph.display {
			if c.under_attack { utils.list_text(mut client.socket, c.theme.graph.data_p, utils.replace_colors(c.graph.render_graph().replace("#", "{RED}#{DEFAULT}")), "Graph") } 
			else { utils.list_text(mut client.socket, c.theme.graph.data_p, utils.replace_colors(c.graph.render_graph().replace("#", "{GREEN}#{DEFAULT}")), "Graph") }
		}
		
		/* Display Server Network Status */
		if c.under_attack && c.theme.connection.display {
			utils.place_text(mut client.socket, c.theme.connection.online_status, c.theme.graph.offline_data_c, "\x1b[31mUnder Attack\x1b[39m") // Connection Status
		} else {
			utils.place_text(mut client.socket, c.theme.connection.online_status, c.theme.graph.online_data_c, "\x1b[32mOnline\x1b[39m") // Connection Status
		}

		/* Display Logo as Server Status */
		if c.theme.connection.logo_as_status && c.theme.connection.logo_p != ["0","0"] && c.under_attack {
			utils.list_text(mut client.socket, c.theme.connection.logo_p, "${utils.c_red}${c.theme.logo}${utils.c_default}", "Logo")
		} else if c.theme.connection.logo_as_status && c.theme.connection.logo_p != ["0","0"] {
			utils.list_text(mut client.socket, c.theme.connection.logo_p, "${utils.c_green}${c.theme.logo}${utils.c_default}", "Logo")
		}

		time.sleep(1*time.second) // ---------------------------------------------------------------------------------------------------------

		/* Text Reset */	
		utils.place_text(mut client.socket, c.theme.connection.pps_p, 				c.theme.connection.value_c, "         ") // PPS
		utils.place_text(mut client.socket, c.theme.connection.nload_curr, 			c.theme.connection.value_c, "                  ") // nload Curr
		utils.place_text(mut client.socket, c.theme.connection.nload_avg, 			c.theme.connection.value_c, "                  ") // nload Avg
		utils.place_text(mut client.socket, c.theme.connection.nload_min, 			c.theme.connection.value_c, "                  ") // nload Min
		utils.place_text(mut client.socket, c.theme.connection.nload_max, 			c.theme.connection.value_c, "                  ") // nload Max
		utils.place_text(mut client.socket, c.theme.connection.nload_ttl, 			c.theme.connection.value_c, "                  ") // nload Ttl
		utils.place_text(mut client.socket, c.theme.connection.connection_count, 	c.theme.connection.value_c, "      ") // Connection Count
		utils.place_text(mut client.socket, c.theme.connection.under_attack, 		c.theme.connection.value_c, "            ") // Under Attack
		utils.place_text(mut client.socket, c.theme.connection.online_status, c.theme.graph.offline_data_c, "            ") // Connection Status
		utils.place_text(mut client.socket, c.theme.connection.filter_mode, 		c.theme.connection.value_c, "      ") // Filter System Mode
		utils.place_text(mut client.socket, c.theme.connection.drop_mode, 			c.theme.connection.value_c, "      ") // Drop System Mode
		utils.place_text(mut client.socket, c.theme.connection.dump_mode, 			c.theme.connection.value_c, "      ") // Dump System Mode
		utils.place_text(mut client.socket, c.theme.connection.blocked_con_count,  		c.theme.connection.value_c, "      ") // Personal Rules Count
		utils.place_text(mut client.socket, c.theme.connection.protected_port_count,  	c.theme.connection.value_c, "      ") // Personal Rules Count
	}
}