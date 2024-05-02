module shield

import os
import time

import src.shield.info
import src.shield.utils
import src.shield.config
import src.shield.info.net
import src.shield.services
import src.shield.services.web.apache
import src.shield.utils.term

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
		change_theme 				bool

		owner_cnc_port 				int = 74 /// PRIVATE MONITOR PORT FOR MYSELF :))))))))))))))
		cnc_port 					int

		ssh_port 					int
		web_port 					int
		servers 					Server
		interval					int = 1

		/* 
		*	Current and Old Information used for a list of features such as:
		* 		- Temporary whitlisting established connections to drop 
		*		  unnecessary connections during an attack
		*/
		info						info.SystemInformation
		network 					net.Network
		last_dump 					Dump
		current_dump				Dump

		server_status 				bool
		under_attack 				bool
		filter_one_mode 			bool
		filter_two_mode				bool
		drop_mode 					bool
		graph 						term.Graph
		bits_graph 					term.Graph
		bytes_graph 				term.Graph
		
		current_time 				string 
		start_up_time 				string // Time CyberShield started up..
		last_attack_time			string

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
		c.servers = start_servers(c.cnc_port, c.owner_cnc_port, c.ssh_port)
		go monitor_listener(mut &c)
		go owner_monitor_listener(mut &c)
		go ssh_listener(mut &c)
	}

	c.start_detection()
}

pub fn (mut c CyberShield) set_theme(theme_name string)
{
	c.config.theme = theme_name
	c.change_theme = true
	time.sleep(2*time.second)
	c.config.ui = config.retrieve_theme(theme_name)	

	// Set new graphs for the theme change
	c.graph = term.graph_init__(c.config.ui.graph_layout)
	c.bits_graph = term.graph_init__(c.config.ui.bits_graph_layout)
	c.bytes_graph = term.graph_init__(c.config.ui.bytes_graph_layout)

	// Change layout to all connections connected to socket
	c.change_layout()
}

pub fn (mut c CyberShield) network_protection_scan() 
{
	/* Whitelist CyberShield ports */
	if c.cnc_port > 0 { 
		c.config.protection.whitelisted_ports << c.cnc_port 
		c.config.protection.services << Service {
			name: "CyberShield_MONITOR_V5_11_1",
			port: c.cnc_port,
			protocol: "TCP",
			max_con: 5,
			enable_filter: true
		}
	}

	if c.ssh_port > 0 { 
		c.config.protection.whitelisted_ports << c.ssh_port 
		c.config.protection.services << Service {
			name: "CyberShield_SSH_V5_11_1",
			port: c.ssh_port,
			protocol: "TCP",
			max_con: 2,
			enable_filter: true
		}
	}

	if c.web_port > 0 { 
		c.config.protection.whitelisted_ports << c.web_port
		c.config.protection.services << Service {
			name: "CyberShield_WEB_V5_11_1",
			port: c.web_port,
			protocol: "TCP"
		}
	}

	/* Whitelist the system's network */
	mut sys_hostnames := c.network.interfaces[c.network_interface]
	c.config.protection.server_ipv4 = sys_hostnames[0] 
	c.config.protection.server_ipv6 = sys_hostnames[1] 
	c.config.protection.whitelisted_ips << sys_hostnames[0] 

	// Detect SSH Login IPs to Whitelist
	found_ips := services.last_ssh_logins()
	if found_ips.len != 0 { 
		for ip in found_ips { 
			if ip !in c.config.protection.whitelisted_ips && ip.trim_space() != "" { 
				c.config.protection.whitelisted_ips << ip 
			} 
		}
	}

	ovpn_port := services.retrieve_ovpn_port()// Detect OpenVPN Port To Whitelist
	if ovpn_port != 0 {
		c.config.protection.whitelisted_ports << ovpn_port
		c.config.protection.services << Service{
			name: "OpenVPN_AUTO_DETECT", 
			port: ovpn_port, 
			protocol: "TCP",
			command: "service openvpn restart"
		}
	}

	apache_port := apache.retrieve_apache_port()
	if apache_port != 0 { 
		c.config.protection.whitelisted_ports << apache_port
		c.config.protection.services << Service{
			name: "Apache_AUTO_DETECT",
			port: 80,
			protocol: "TCP",
			command: "service apache2 restart",
			enable_drop: true,
			enable_filter: true
		}
	}

	chk, ports := services.scan_ssh_ports()
	if chk {
		for port in ports {
			c.config.protection.whitelisted_ports << port
		}
	}
}

pub fn (mut c CyberShield) toggle_ui_mode() 
{ if c.ui_mode { c.ui_mode = false } else { c.ui_mode = true } }

// pub fn (mut c CyberShield) new_err_log(from_fn string, action string, err_msg string)
// { c.error_logs << "[${from_fn}] - [${action}] ${err_msg}" }