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

		mut client_ip := "${client.peer_ip()}".replace("Result('", "").replace("[::ffff:", "").split("]:")[0].trim_space()


		
		if c.servers.monitor_listener_toggle && c.under_attack && !c.config.protection.is_con_whitlisted(client_ip) {
			client.close() or { return }
			c.servers.toggle_monitor_listener()
			return
		}

		client.set_read_timeout(time.infinite)
		c.servers.clients << client
		go display_monitor(mut c, mut client)
	}
}

pub fn ssh_listener(mut c CyberShield) {
	for {
		mut ssh_client := c.servers.ssh.accept() or {
			println("[ X ] Error, Unable to accept SSH socket connections....!")
			continue
		}

		mut client_ip := "${ssh_client.peer_ip()}".replace("[::ffff:", "").split("]:")[0].trim_space()
		if c.servers.monitor_listener_toggle && c.under_attack && !c.config.protection.is_con_whitlisted(client_ip) {
			ssh_client.close() or { return }
			c.servers.ssh.close() or { return }
			return
		}

		ssh_client.set_read_timeout(time.infinite)
		c.servers.clients << ssh_client
		go ssh_client_handler(mut c, mut ssh_client)
	}
}

pub fn connection_chk(mut c net.TcpConn) bool 
{
	c.write_string(" ") or { return false }
	return true
}