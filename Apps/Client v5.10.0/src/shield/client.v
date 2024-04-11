module shield

import net
import time

pub fn monitor_listener(mut c CyberShield)
{
	for 
	{
		println("[ + ] ( MONITOR ) Listening for sockets.....")
		mut client := c.servers.monitor.accept() or {
			println("[ X ] Error, Unable to accept connection....!")
			continue
		}

		mut client_ip := "${client.peer_ip()}".replace("[::ffff:", "").split("]:")[0].trim_space()
		if c.servers.monitor_listener_toggle && client_ip !in c.config.protection.whitelisted_ips {
			client.close() or { return }
			c.servers.toggle_monitor_listener()
			return
		}

		client.set_read_timeout(time.infinite)
		c.servers.clients << client
		display_monitor(mut c, mut client)
	}
}

pub fn connection_chk(mut c net.TcpConn) bool 
{
	c.write_string(" ") or { return false }
	return true
}