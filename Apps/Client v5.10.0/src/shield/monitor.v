module shield

import net
import time

import src.shield.utils.term 

pub fn display_monitor(mut c CyberShield, mut socket net.TcpConn) 
{

	// TODO: Initialize Graph 
	term.set_term_size(mut socket, c.config.ui.terminal.size[0].int(), c.config.ui.terminal.size[1].int())
	term.set_title(mut socket, c.config.ui.terminal.title)

	term.place_text(mut socket, c.config.ui.connection.pps, c.config.ui.connection.value_c, "${c.network.pps}")
	
	for 
	{
		/* Display Network Data, DDoS Detection Etc */
		if c.config.ui.connection.display {

		}

		/* Display Graph Of Incoming PPS Data */
		if c.config.ui.graph.display {

		}

		/* Display Data Grid View Of Connection(s) Connected to Server */
		if c.config.ui.conntable.display {

		}
		time.sleep(1*time.second)
	}
}