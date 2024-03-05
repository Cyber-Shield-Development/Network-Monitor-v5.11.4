module src

import time
import src.utils

/* 
*	- Display information to client via Socket
*/
pub fn start_displaying(mut c CyberShield, mut client Client)
{
	client.socket.set_read_timeout(time.infinite)
	mut graph := utils.graph_init__(c.theme.theme, 28, 71)
	println("[ + ] New socket connected")

	/* Set Terminal Title & Size */
	utils.set_term_size(mut client.socket, 40, 123)
	utils.set_title(mut client.socket, c.theme.term.title)

	/* Output Layout */
	client.socket.write_string(utils.replace_colors(c.theme.layout)) or { 0 }
	utils.list_text(mut client.socket, c.theme.graph.layout_p, c.theme.graph_layout) // Graph Layout

	/* Add Information Display */
	
	/* OS Information */
	utils.place_text(mut client.socket, c.theme.os.os_name_p, c.os_info.name)
	utils.place_text(mut client.socket, c.theme.os.os_version_p, c.os_info.version)
	utils.place_text(mut client.socket, c.theme.os.os_kernel_p, c.os_info.kernel)
	utils.place_text(mut client.socket, c.theme.os.shell_p, c.os_info.shell)
	

	/* Connection Information */
	utils.place_text(mut client.socket, c.theme.connection.download_speed_p, c.conn_info.download) // Download Speed
	utils.place_text(mut client.socket, c.theme.connection.upload_speed_p, c.conn_info.upload) // Upload Speed
	utils.place_text(mut client.socket, c.theme.connection.ms_p, c.conn_info.ms) // Upload Speed
	utils.place_text(mut client.socket, c.theme.connection.interface_p, c.interfacee) // Interface 
	utils.place_text(mut client.socket, c.theme.connection.system_ip_p, c.conn_info.system_ip) // IP Address 
	utils.place_text(mut client.socket, c.theme.connection.pps_limit_p, "${c.max_pps}") // PPS To Filter 

	
	for {
		client.socket.write_string(" ") or { 
			c.rm_socket(mut client.socket)
			return
		}

		
		utils.place_text(mut client.socket, c.theme.connection.connection_count, c.ips.len.str()) // IP Address 

		/* Display Attack & nload Information */
		utils.place_text(mut client.socket, c.theme.connection.pps_p, "\x1b[32m${c.pps}\x1b[39m") // PPS
		utils.place_text(mut client.socket, c.theme.connection.nload_curr, "\x1b[32m${c.conn_info.curr}\x1b[39m GBit/s") // nload Curr
		utils.place_text(mut client.socket, c.theme.connection.nload_avg, "\x1b[32m${c.conn_info.avg}\x1b[39m GBit/s") // nload Avg
		utils.place_text(mut client.socket, c.theme.connection.nload_min, "\x1b[32m${c.conn_info.min}\x1b[39m GBit/s") // nload Min
		utils.place_text(mut client.socket, c.theme.connection.nload_max, "\x1b[32m${c.conn_info.max}\x1b[39m GBit/s") // nload Max
		utils.place_text(mut client.socket, c.theme.connection.nload_ttl, "\x1b[32m${c.conn_info.ttl}\x1b[39m GBit/s") // nload Ttl

		
		if c.theme.graph.display {
			graph.append_to_graph(c.pps) or { continue }
			if c.under_attack { utils.list_text(mut client.socket, c.theme.graph.graph_p, utils.replace_colors(graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { utils.list_text(mut client.socket, c.theme.graph.graph_p, utils.replace_colors(graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}
		
		if c.under_attack {
			utils.place_text(mut client.socket, c.theme.connection.online_status, "\x1b[31mUnder Attack\x1b[39m") // Connection Status
		} else {
			utils.place_text(mut client.socket, c.theme.connection.online_status, "\x1b[32mOnline\x1b[39m") // Connection Status
		}

		time.sleep(1*time.second)
		/* Text Reset */
		utils.place_text(mut client.socket, c.theme.connection.online_status, "              ") // Online Status
		utils.place_text(mut client.socket, c.theme.connection.connection_count, "        ") // Connection Count
		utils.place_text(mut client.socket, c.theme.connection.pps_p, "            ") // PPS
		utils.place_text(mut client.socket, c.theme.connection.nload_curr, "              ") // nload Curr
		utils.place_text(mut client.socket, c.theme.connection.nload_avg, "              ") // nload Avg
		utils.place_text(mut client.socket, c.theme.connection.nload_min, "              ") // nload Min
		utils.place_text(mut client.socket, c.theme.connection.nload_max, "              ") // nload Max
		utils.place_text(mut client.socket, c.theme.connection.nload_ttl, "              ") // nload Ttl
	}
}