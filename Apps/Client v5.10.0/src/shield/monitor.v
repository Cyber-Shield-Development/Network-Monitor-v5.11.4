module shield

import net
import time

import src.shield.utils.term 

pub fn display_monitor(mut c CyberShield, mut socket net.TcpConn) 
{

	// TODO: Initialize Graph 
	term.set_term_size(mut socket, c.config.ui.terminal.size[0].int(), c.config.ui.terminal.size[1].int())
	term.set_title(mut socket, c.config.ui.terminal.title)

	/* Output Layout */
	socket.write_string(term.replace_colors(c.config.ui.layout).trim_space()) or { 0 } // Theme Layout
	time.sleep(50*time.millisecond)
	term.list_text(mut socket, c.config.ui.graph.layout, "${c.config.ui.graph_layout}".trim_space())
	
	for 
	{
		/* Display Network Data, DDoS Detection Etc */
		if c.config.ui.connection.display {
			term.place_text(mut socket, c.config.ui.connection.pps, c.config.ui.connection.value_c, "${c.network.pps}")
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.bits_graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.bits_graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.bits_graph.data, term.replace_colors(c.graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.bytes_graph.display {
			if c.under_attack { term.list_text(mut socket, c.config.ui.bytes_graph.data, term.replace_colors(c.bytes_graph.render_graph().replace("#", "{RED}#{DEFAULT}"))) } 
			else { term.list_text(mut socket, c.config.ui.bytes_graph.data, term.replace_colors(c.bytes_graph.render_graph().replace("#", "{GREEN}#{DEFAULT}"))) }
		}

		/* Display Data Grid View Of Connection(s) Connected to Server */
		if c.config.ui.conntable.display {

		}
		time.sleep(1*time.second)
	}
}