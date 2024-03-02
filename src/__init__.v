module src 

import os
import net
import time

import src.info
import src.config

pub struct Client
{
	pub mut:
		socket		net.TcpConn
		disable_ui	bool
}

pub struct CyberShield
{
	pub mut:
		interfacee				string
		
		ips						[]info.Netstat
		cnc_port 				int
		cnc_listener			net.TcpListener
		clients					[]Client
		web_port				int

		/* Output Options & Settings */
		ui_mode					bool // Enable or Disable UI Mode for more proformance
		reset_tables			bool
		under_attack			bool
		theme					config.UI
		pps						int
		max_pps					int

		/* Connection Gathering Information */
		conn_info				info.Connection
		os_info					info.OS
		hw_info 				info.HW
		established_cons 		int
		close_wait_cons			int
		time_wait_cons			int
		blocked_ips				[]string
		ip_logs					map[string]string
		abused_port				[]int
		
		max_connections			int
		max_con_per_port		int
		auto_add_rules			bool
		cfg_protected_ip		[]string
		cfg_protected_port 		[]int
}

/*
*
*	The Start Of CyberShield
*
*	- Start connection informaton
*	- Start listener and retrieve hardware and OS informaton
*	- Start info grab and detecting ddos to protect.
*/
pub fn monitor(mut c CyberShield) 
{
	c.conn_info = info.connection(c.interfacee)
	c.retrieve_protection()
	
	/* UI Mode */
	if c.ui_mode {
		c.cnc_listener = net.listen_tcp(.ip6, ":444") or {
			println("[ X ] Error, Unable to start CyberShield listener....!")
			return 
		}
		c.os_info = info.grab_os_info()
		go listener(mut &c)
	}

	/* Start protection */
	c.start_monitoring()
}

/*
*	- Change theme
*/
pub fn (mut c CyberShield) set_theme(name string) 
{
	c.theme = config.new_theme(name)
}

/*
* 	- Listen for new users connecting via Socket
*/
pub fn listener(mut c CyberShield)
{
	for {
		println("[ + ] Listening for sockets....!")
		mut client := c.cnc_listener.accept() or { 
			println("[ X ] Socket rejected")
			time.sleep(30*time.second)
			continue 
		}
		
		// Add a socket rejecters when under attack mode
		if c.under_attack { continue }
		
		client.set_read_timeout(time.infinite)
		mut n := Client{socket: client}
		c.clients << n
		go start_displaying(mut &c, mut &n)
	}
}

/*
*	- Remove a socket once disconnected
*/
pub fn (mut c CyberShield) rm_socket(mut n net.TcpConn)
{
	mut t := 0
	for mut client in c.clients 
	{
		if client.socket == n { 
			println("[ X ] Socket Removed && Disconnected....")
			c.clients.delete(t)
			n.close() or { return }
			return
		}
		t++
	}
}

/*
*	- Retrieve Configuration Protection
*/
pub fn (mut c CyberShield) retrieve_protection() 
{
	mut protection_data := os.read_lines("assets/protection.shield") or {
		println("[ X ] Error, Unable to read config protection.shield file....!")
		return
	}

	mut ip_data := config.get_block_data(protection_data, "[@PROTECTED_IPS]").split("\n")
	for ip in ip_data { if ip != "" { c.cfg_protected_ip << ip } }

	mut port_data := config.get_block_data(protection_data, "[@PROTECTED_PORTS]").split("\n")
	for port in port_data { if port.int() != 0 { c.cfg_protected_port << port.int() } }

	for line in protection_data
	{
		if line.ends_with("false") { continue }

		if line.trim_space().starts_with("max_connections") {
			c.max_connections = line.trim_space().replace("max_connections:", "").trim_space().int()
		} else if line.trim_space().starts_with("pps_to_filter") {
			if c.max_pps != 0 { continue }
			c.max_pps = line.trim_space().replace("pps_to_filter:", "").trim_space().int()
		} else if line.trim_space().starts_with("max_con_per_port") {
			c.max_con_per_port = line.trim_space().replace("max_con_per_port:", "").trim_space().int()
		}
	}
}