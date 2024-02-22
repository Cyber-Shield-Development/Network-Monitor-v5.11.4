module src 

import os

import src.utils

pub struct CyberShield
{
	pub mut:
		interfacee				string
		
		ips						[]utils.Netstat

		/* Output Options */
		ui_mode					bool // Enable or Disable UI Mode for more proformance
		cnc_port 				int
		web_port				int

		/* Connection Gathering Information */
		established_cons 		int
		close_wait_cons			int
		time_wait_cons			int
}

pub fn monitor(iface string, cnc_p int, web_p int, ui bool) CyberShield 
{
	mut c := CyberShield{ interfacee: iface, cnc_port: cnc_p, web_port: web_p, ui_mode: ui }
	c.start_monitoring()

	return c
}

pub fn (mut c CyberShield) start_monitoring()
{
	mut ips_data := utils.grab_ips().split("\n")

	for line in ips_data
	{
		info := utils.remove_empty_elemets(line.split(" "))
		if info.len < 4 || !line.contains(":") { continue }
		c.ips << utils.new(info)
	}
}