module shield

import os
import src.shield.info
import src.shield.utils
import src.shield.config
import src.shield.info.net
import src.shield.services
import src.shield.info.net.netstat as ns

pub struct Config 
{
	pub mut:
		theme 					string
		ui						config.Theme
		protection 				Protection
}

pub struct GlobalSettings 
{
	pub mut:
		key 				string
		session_id 			string

		/* User Plan Settings */
		notification_access bool = true
		dump_access 		bool = true
		filter_access 		bool = true
		drop_access			bool = true
}

pub struct CyberShield 
{
	pub mut:
		network_interface 			string
		key 						string
		config 						Config // Configuration File(s)
		settings 					GlobalSettings // License Access Settings 

		tick 						int
		ui_mode 					bool
		cnc_port 					int
		ssh_port 					int
		web_port 					int
		servers 					Server

		/* 
		*	Current and Old Information used for a list of features such as:
		* 		- Temporary whitlisting established connections to drop 
		*		  unnecessary connections during an attack
		*/
		info						info.SystemInformation
		network 					net.Network

		server_status 				bool
		under_attack 				bool
		filter_one_mode 			bool
		filter_two_mode				bool
		drop_mode 					bool

		current_dump				Dump
		
		current_time 				string 
		start_up_time 				string // Time CyberShield started up..

		error_logs 					[]string
}

/* 
*	[@DOC]
*	- Arguments: License ID & Interface 
*/
pub fn cyber_shield(mut c CyberShield, theme string) 
{

	c.start_up_time = utils.current_time()
	println("[ + ] (${c.start_up_time}) Starting up Cyber Shield.....!")

	println("[ + ] (${c.start_up_time}) Retrieving System Information.....!")
	c.info 	  = info.system__init(c.network_interface)
	println("[ + ] (${c.start_up_time}) Retrieving Connection Information to Monitor....")
	c.network = net.network__init(c.network_interface)

	println("[ + ] (${c.start_up_time}) Retrieving Configuration file(s).....!")
	if theme != "" {
		c.toggle_ui_mode()
		c.config.ui = config.retrieve_theme(theme)
	}
	c.config.protection = protection__init()

	println("[ + ] (${c.start_up_time}) Scanning for port services.....!")
	c.config.protection.add_personal_rules()
	c.network_protection_scan()

	if c.cnc_port != 0 {
		c.servers = start_servers(c.cnc_port, c.ssh_port)
		go monitor_listener(mut &c)
	}

	c.start_detection()
}

pub fn (mut c CyberShield) set_theme(theme_name string)
{
	c.config.theme = theme_name
	c.config.ui = config.retrieve_theme(theme_name)
}

pub fn (mut c CyberShield) network_protection_scan() 
{
	/* Whitelist CyberShield ports */
	if c.cnc_port > 0 { c.config.protection.whitelisted_ports << c.cnc_port }
	if c.ssh_port > 0 { c.config.protection.whitelisted_ports << c.ssh_port }
	if c.web_port > 0 { c.config.protection.whitelisted_ports << c.web_port }

	// Detect SSH Login IPs to Whitelist
	found_ips := services.last_ssh_logins()
	if found_ips.len > 0 { 
		for ip in found_ips { 
			if ip !in c.config.protection.whitelisted_ips { 
				c.config.protection.whitelisted_ips << ip 
			} 
		}
	} else { 
		println("[ - ] WARNING, No IPs was found in last SSH logins. This is used to whitlist the owner of the server! Whitelist your IP via configuration file for pre-caution reasons")
	}

	// Detect OpenVPN Port To Whitelist
	if !services.check_for_ovpn() {
		println("[ + ] OpenVPN was not found. Whitlisting the server port....!")
	}

	ovpn_port := services.retrieve_ovpn_port()
	if ovpn_port == 0 {
		println("[ - ] WARNING, No port was found for OpenVPN via its default configuration filepath.... Whitelist the server port via configuration file for pre-caution reasons")
	} else {
		println("[ + ] OpenVPN was found... Whitlisting its Port.....!")
		c.config.protection.whitelisted_ports << ovpn_port
	}


	mut sys_hostnames := c.network.interfaces[c.network_interface]
	c.config.protection.server_hostname = os.execute("hostname -f").output
	c.config.protection.server_ipv4 = sys_hostnames[0]
	c.config.protection.server_ipv6 = sys_hostnames[1]

	// Detect Apache/Nginx and//or any other web server hosted on the network
}

pub fn (mut c CyberShield) toggle_ui_mode() 
{ if c.ui_mode { c.ui_mode = false } else { c.ui_mode = true } }

// pub fn (mut c CyberShield) new_err_log(from_fn string, action string, err_msg string)
// { c.error_logs << "[${from_fn}] - [${action}] ${err_msg}" }