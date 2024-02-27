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
}

pub struct CyberShield
{
	pub mut:
		interfacee				string
		
		ips						[]info.Netstat
		pps						int

		/* Output Options */
		ui_mode					bool // Enable or Disable UI Mode for more proformance
		theme					config.UI
		cnc_port 				int
		cnc_listener			net.TcpListener
		clients					Client
		web_port				int

		/* Connection Gathering Information */
		established_cons 		int
		close_wait_cons			int
		time_wait_cons			int
}

pub fn monitor(iface string, cnc_p int, web_p int, ui bool) CyberShield 
{
	mut c := CyberShield{ interfacee: iface, cnc_port: cnc_p, web_port: web_p, ui_mode: ui }
	//go start_monitoring(mut &c)

	/* UI Mode */
	if c.ui_mode {
		c.cnc_listener = net.listen_tcp(.ip6, ":444") or {
			println("[ X ] Error, Unable to start CyberShield listener....!")
			return c
		}

		// Start system/os information listener/grabber
	}

	/* Start protection */
	go start_monitoring(mut &c)

	return c
}

pub fn (mut c CyberShield) set_theme(name string) 
{
	c.theme = config.new_theme(name)
}

pub fn listener(mut c CyberShield)
{
	for {

		mut client := c.cnc_listener.accept() or { continue }
		client.set_read_timeout(time.infinite)
	}
}

pub fn start_monitoring(mut c CyberShield)
{
	/* Start the UI if enabled */
	for 
	{
		/* Grab information to parse and detect */
		old_pps := info.fetch_pps_info(c.interfacee)
		time.sleep(1*time.second)
		new_pps := info.fetch_pps_info(c.interfacee)

		c.pps = (old_pps.tx - new_pps.tx) - (old_pps.rx - new_pps.rx)

		/* Detection */
		mut ips_data := info.grab_ips().split("\n")
		for line in ips_data
		{
			ip_info := info.remove_empty_elemets(line.split(" "))
			if ip_info.len < 4 || !line.contains(":") { continue }
			c.ips << info.new(ip_info)

			// protection goes in here
		}
	}
}

pub fn (mut c CyberShield) start_displaying(mut client Client)
{
	print("${c.theme.layout}")
	// for {
	// }
}