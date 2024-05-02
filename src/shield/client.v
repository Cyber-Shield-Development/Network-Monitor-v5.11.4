module shield

import net
import time

/*
*	[@DOC]
*	pub fn monitor_listener(mut c CyberShield)
*
*	- Listen for new connection and display monitor to socket
*/
pub fn monitor_listener(mut c CyberShield)
{
	for 
	{
		println("[ + ] ( MONITOR ) Listening for sockets.....")

		mut client := c.servers.pmonitor.socket.accept() or {
			println("[ X ] Error, Unable to accept connection....!")

			// Disable the listener upon new connection if the server is under attack upon new connection
			if c.servers.pmonitor.enable && c.under_attack {
				println("[ X ] Attack being detected, Turning off the monitor listener....!")
				return
			}
			continue
		}

		if c.servers.pmonitor.enable && c.under_attack {
			println("[ X ] Attack being detected, Turning off the monitor listener....!")
			client.close() or { return }
			return
		}

		client.set_read_timeout(time.infinite)
		c.servers.clients << client
		display_tui(mut c, mut client)
		go display_monitor(mut c, mut client)
	}
}

/*
*	[@DOC]
*	pub fn monitor_listener(mut c CyberShield)
*
*	- [Private Port] Listen for new connection and display monitor to socket
*/
pub fn owner_monitor_listener(mut c CyberShield)
{
	for 
	{
		println("[ + ] ( OWNER MONITOR ) Listening for sockets.....")
		mut oclient := c.servers.monitor.socket.accept() or {
			println("[ X ] Error, Unable to accept connection....!")
			
			// Disable the listener upon new connection if the server is under attack upon new connection
			if c.servers.monitor.enable && c.under_attack {
				println("[ X ] Attack being detected, Turning off the private monitor listener....!")
				return
			}

			continue
		}

		if c.servers.monitor.enable && c.under_attack {
			c.servers.monitor.toggle_monitor()
			return
		}

		oclient.set_read_timeout(time.infinite)
		c.servers.clients << oclient
		display_tui(mut c, mut oclient)
		go display_monitor(mut c, mut oclient)
	}
}

pub fn connection_chk(mut c net.TcpConn) bool 
{
	c.write_string(" ") or { return false }
	return true
}