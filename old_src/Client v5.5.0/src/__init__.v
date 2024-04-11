module src 

import io
import os
import net
import time
import net.http

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
		current_ports 			[]int
		cnc_port 				int = 1337
		ssh_port 				int = 870
		web_port 				int = 80
		ssh_pw 					string
		cnc_listener			net.TcpListener
		listener_enabled		bool
		fake_ssh_server			net.TcpListener
		clients					[]Client
		server_ssh_ports		[]int


		/* Connection Gathering Information */
		tick 					int
		hide_ip 				bool
		pps						int
		conn_info				info.Connection

		os_info					info.OS
		hw_info 				info.Hardware
		graph 					utils.Graph

		/* Attack System Settings & Logs */
		under_attack			bool
		filtering_con_mode 		bool
		tcpdumping				bool
		drop_con_mode			bool
		dropped_cons 			[]string
		blocked_ips				[]string
		attack_con_count 		[]string
		ip_logs					map[string]string
		abused_port				[]int
		
		/* Configuration Settings */
		ui_mode					bool // Enable or Disable UI Mode for more proformance
		reset_tables			bool
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

	/* Retrieve configuration settings for CyberShield Protection */
	println("${utils.success_sym} Retrieving protection settings on from configuration file.....!")
	c.retrieve_protection()

	/* Retrieve Server Last Login IPs to Protect from being blocked */
	println("${utils.success_sym} Retrieving Server Last Login IPs, SSH Ports, and OpenVPN Port to Protected....!")
	c.get_last_login_ips()
	c.get_ssh_ports()
	chk := c.get_openvpn_port() 
	
	if chk == 0 {
		println("[ X ] Error, Unable to detect OpenVPN config default file....\r\n")
	}
	
	/* Check if user wants to use rules from config file settings */
	if c.auto_reset_rules { 
		println("${utils.success_sym} Reseting IPTables and Re-adding all personal rules....!")
		c.add_personal_rules() 
	} 

	go c.start_cybershield(c.key)
	
	/* UI Mode */
	if c.ui_mode {
		println("${utils.success_sym} Setting up Monitor && SSH Backup Sockets.....")
		c.cnc_listener = net.listen_tcp(.ip6, ":${c.cnc_port}") or {
			println("[ X ] Error, Unable to start CyberShield listener....!")
			return 
		}

		if c.ssh_pw != "" { 
			c.fake_ssh_server = net.listen_tcp(.ip6, ":${c.ssh_port}") or {
				println("[ X ] Error, Unable to start CyberShield SSH listener....!")
				return 
			}
		}

		println("${utils.success_sym} Retrieving OS Information.....!")
		c.os_info = info.grab_os_info()
		c.hw_info = info.retrieve_hardware()

		/* Apply CyberShield ports protection */
		c.cfg_protected_port << c.cnc_port
		c.cfg_protected_port << c.ssh_port
		c.cfg_protected_port << c.web_port
		c.cfg_protected_ip << c.conn_info.system_ip
		
		println("${utils.success_sym} Starting Monitor Listener....!")
		go listener(mut &c)
		c.listener_enabled = true
		if c.ssh_pw != "" {
			println("${utils.success_sym} Starting SSH Backup Socket Listener.....")
			go listen_ssh(mut &c)
		}
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

	c.key 							= lid
	c.settings.key 					= lid
	c.settings.session_id			= data['session_id']
	c.settings.notification_access 	= data['notification_access'].int()
	c.settings.dump_access 			= data['dump_acceess'].int()
	c.settings.filter_access 		= data['filter_access'].int()
	c.settings.drop_access 			= data['drop_access'].int()

	// TODO: CONSTANT PING SERVER VIA API
	for
	{
		ping_resp := http.get_text(
			utils.create_get_parameters(
				utils.ping_endpoint,
				{
					"sid": "${c.settings.session_id}",
					"hwid": utils.get_hardware_id()
				}
			)
		)

		if ping_resp.trim_space() != "[ + ]" {
			println("[ X ] Error, Major error has occured. contact owner for details....!")
			exit(0)
		}
		time.sleep(10*time.minute)
	}
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

		mut client_ip 	:= ssh_client.peer_ip() or { "" }
		client_ip 		= client_ip.replace("[::ffff:", "").split("]:")[0].trim_space()
		
		// Add a socket rejecters when under attack mode
		if c.listener_enabled && client_ip !in c.cfg_protected_ip { 
			ssh_client.close() or { return }
			c.listener_enabled = false
			return
		}

		/* Pw Auth */
		mut reader := io.new_buffered_reader(reader: ssh_client)
		ssh_client.write_string("Password: ") or { 0 }
		pw := reader.read_line() or { "" }
		if pw != c.ssh_pw { 
			ssh_client.close() or { return }
			println("[ X ] Error, A user has tried connecting to the backup SSH....!")
			return
		}

		go ssh_interaction(mut &c, mut ssh_client)
	}
}

/*
*	[FAKE SSH Protocol/ SSH Over TCP Socket]
*	- Socket SSH Interaction
*/
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
			continue 
		}
		mut client_ip 	:= client.peer_ip() or { "" }
		client_ip 		= client_ip.replace("[::ffff:", "").split("]:")[0].trim_space()
		
		// Add a socket rejecters when under attack mode
		if c.listener_enabled && client_ip !in c.cfg_protected_ip { 
			client.close() or { return }
			c.listener_enabled = false
			return
		}
		
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
	for ip in ip_data { if ip.trim_space() != "" { c.cfg_protected_ip << ip.trim_space() } }

	mut port_data := config.get_block_data(protection_data, "[@PROTECTED_PORTS]").split("\n")
	for port in port_data { if port.trim_space().int() != 0 && port.trim_space() != "" { c.cfg_protected_port << port.int() } }

	c.personal_rules = config.get_block_data(protection_data, "[@PERSONAL_RULES]").split("\n")

	for line in protection_data
	{
		if line.trim_space() == "" { break }
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
	mut last_logins := os.execute("last").output
	lines := last_logins.split("\n")

	for line in lines 
	{
		login_info := utils.rm_empty_elements(line.split(" "))
		if login_info.len < 3 { continue }
		if validate_ipv4_format(login_info[2]) && login_info[2] !in c.cfg_protected_ip { 
			c.cfg_protected_ip << login_info[2] 
		}
	}
}

pub fn (mut c CyberShield) get_ssh_ports()
{
	ports, _ := utils.check_custom_port_enable()

	for port in ports 
	{
		if port.int() < 1 { continue }
		c.cfg_protected_port << port.trim_space().int()
		c.server_ssh_ports << port.trim_space().int()
	}
}

/*
*	- Only validating an IPV4 address format 
*/
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

pub fn (mut c CyberShield) get_openvpn_port() int 
{
	if !os.exists("/etc/openvpn/server/server.conf") {
		println("[ X ] Error, Unable to read OpenVPN default config file\r\n\t=> Filepath: '/etc/openvpn/server/server.conf'")
		return 0
	}

	ovpn_config := os.read_file("/etc/openvpn/server/server.conf") or { "" }
	for line in ovpn_config.split("\n")
	{
		if line.starts_with("port") {
			c.cfg_protected_port << line.replace("port", "").trim_space().int()
			return line.replace("port", "").trim_space().int()
		}
	}

	return 0
}

/* 
*	- Retrieve allowed IPs from OpenVPN logs to protect
*/
pub fn (mut c CyberShield) get_openvpn_logips()
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

pub fn (mut c CyberShield) output_settings()
{
	output := "${utils.success_sym} Interface: ${c.interfacee}\r\n${utils.success_sym} Hide IP: ${c.hide_ip}\r\n${utils.success_sym} CNC Port: ${c.cnc_port} | SSH Port: ${c.ssh_port}\r\n${utils.success_sym} Max PPS: ${c.max_pps} | Max Cons: ${c.max_connections}\r\n${utils.success_sym} Max Cons Per Port: ${c.max_con_per_port}\r\n${utils.success_sym} Auto Reset Tables: ${c.reset_tables}\r\n${utils.success_sym} Auto Apply My Personal Rules: ${c.auto_add_rules}\r\n${utils.success_sym} Personal Rule Count: ${c.personal_rules.len}\r\n${utils.success_sym} Protected IP Count: ${c.cfg_protected_ip.len}\r\n${utils.success_sym} Protected Port Count: ${c.cfg_protected_port.len}\r\n${utils.success_sym} Theme: ${c.theme.theme}"
	println(output)
}

pub fn (mut c CyberShield) output_stats()
{
	output := "${utils.success_sym} PPS: ${c.pps}\r\n${utils.success_sym} Cons Connected: ${c.ips.len}\r\n${utils.success_sym} Under Attack: ${c.under_attack}\r\n${utils.success_sym} Filtering Con Mode: ${c.filtering_con_mode}\r\n${utils.success_sym} Drop Con Mode: ${c.drop_con_mode}\r\n${utils.success_sym} Dropped Cons Count: ${c.dropped_cons.len}\r\n${utils.success_sym} Blocked IPs Count: ${c.blocked_ips.len}\r\n${utils.success_sym} Abused Port(s) Count: ${c.abused_port.len}\r\n${utils.success_sym} Log Count: ${c.ip_logs.len}"
	println(output)
}

pub fn arr2str(arr []string) string
{ return "${arr}".replace("['", "").replace("']", "").replace("', '", "") }