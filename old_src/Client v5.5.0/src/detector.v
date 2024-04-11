module src

import os
import time
import shield.info
import shield.utils

pub fn do(mut c CyberShield, pps int) {
	c.graph.append_to_graph(c.pps) or { return }
}

/*
*
*	THE MOST UNHITTABLE METHOD IN THE COM
*
*/
pub fn (mut c CyberShield) start_monitoring()
{
	/* Start the UI if enabled */
	c.graph = utils.graph_init__(c.theme.graph_layout,  c.theme.graph.data_heigth, c.theme.graph.data_width)
	for 
	{
		c.tick++
		if c.ui_mode {
			go info.get_nload_info(mut &c.conn_info)
		}

		/* Grab PPS information to parse and detect */
		mut old_pps := info.fetch_pps_info(c.interfacee)
		time.sleep(1*time.second)
		mut new_pps := info.fetch_pps_info(c.interfacee)

		/* Grab Netstat Info & Calculate PPS */
		c.pps = (old_pps.tx - new_pps.tx) - (old_pps.rx - new_pps.rx)
		if c.pps < 0 { c.pps = 0 }
		c.ips = info.grab_ips()
		
		go do(mut c, c.pps) // Render Graph

		if c.settings.filter_access == 1 {
			/* 
			* 	Detect Config Max Connections and Enable Filtering System
			*
			*	Enable filtering system once the max con OR max PPS has been reached
			*/
			if (c.count_unique_cons() > c.max_connections || c.pps >= c.max_pps) && !c.filtering_con_mode { 
				/* Send Updaters Via Remote Execution */
				// go os.execute("screen -dm ping 1.1.1.1 > ping.txt")
				go os.execute("timeout 1 tcpdump -i ${c.interfacee} >> raw_pcap.txt")

				/* Enable Connection Checksums for Filter/Drop */ 
				go c.filter(c.tick)
				go c.ip2logs(c.ips)
				// go c.check_if_offline()
				c.under_attack = true
				c.filtering_con_mode = true
			}

			/* Emergency route to retrieve IPs ( Mostly internals / UDP ) */
			if c.under_attack && !c.tcpdumping && c.blocked_ips.len < 10 && c.count_unique_cons() < 10 {
				go c.tcpdump_n_drop(c.tick)
				c.under_attack = true
				c.tcpdumping = true
				c.filtering_con_mode = true
			}
		}

		if c.settings.drop_access == 1 {
			/*
			* Enable drop connection system once the max PPS has been reached
			*/
			if !c.drop_con_mode && c.pps >= c.max_pps {
				go c.drop_attack(c.tick)
				c.drop_con_mode = true
			}
		}
		
		if c.settings.dump_access == 1 {
			/*
			*	- Detecting for finished or dropped attack then disables all system
			*	  and create a custom dump file.
			*/
			if (c.under_attack && !c.filtering_con_mode && !c.drop_con_mode) && c.pps < c.max_pps { 
				c.under_attack = false 
				c.drop_con_mode = false
				c.tcpdumping = false
				os.execute("sudo killall ping")
				if c.ip_logs.len > 0 && c.blocked_ips.len > 0  {
					println("${utils.success_sym} Creating dump file.....") 
					go c.create_log_file()
					if c.reset_tables { os.execute("sudo iptables -F; sudo iptables-save; sudo ip6tables -F; sudo ip6tables-save") }
					if c.auto_add_rules { go c.add_personal_rules() }
				}
			}
		}
	}
}

pub fn (mut c CyberShield) add_personal_rules() 
{
	all_current_tables := os.execute("sudo iptables -S").output.split("\n")
	os.execute("sudo iptables -F; sudo iptables-save")

	for rule in c.personal_rules {
		if rule.len < 1 { continue }
		if rule in all_current_tables { continue }

		os.execute("${rule}")
		time.sleep(60*time.millisecond)
	}
	os.execute("sudo iptables-save")
}

pub fn (mut c CyberShield) count_unique_cons() int 
{
	mut b := 0 
	for con in c.ips 
	{
		if con.external_ip !in c.cfg_protected_ip {
			b++
		}
	}

	return b
}

pub fn (mut c CyberShield) connection_count() int { return c.ips.len }

pub fn (mut c CyberShield) find_abused_port() int
{
	mut last_port := 0
	for con in c.ips 
	{
		if c.count_port_used(con.internal_port) > c.max_con_per_port {
			last_port = con.internal_port
		}
	}

	return last_port
}

pub fn (mut c CyberShield) count_port_used(port int) int
{
	mut g := 0
	for con in c.ips 
	{
		if con.internal_port == port { g++ }
	}

	return g
}

pub fn (mut c CyberShield) ip2logs(cons []info.Netstat) 
{
	current_time := "${time.now()}".replace("-", "/").replace(" ", "-")

	mut log := ""
	for con in cons
	{
		if con.external_ip !in c.cfg_protected_ip 
		{ log += "\t\t('${con.protocol}','${con.recv_bytes}','${con.sent_bytes}','${con.internal_ip}','${con.internal_port}','${con.external_ip}','${con.external_port}','${con.state}')\n"}
	}

	c.ip_logs[current_time] = log
}

pub fn (mut c CyberShield) create_log_file() 
{
	current_time := "${time.now()}".replace("-", "_").replace(" ", "_")
	mut log := "[@ATTACK_LOG]\n{\n"
	log += "\tPPS: ${c.pps} | Current Setting: ${c.max_pps}\n"
	log += "\tPort Most Abused: ${c.abused_port}\n"
	log += "\tIPs Block Count: ${c.blocked_ips.len}\n"
	log += "[@IPS_BLOCKED]\n{\n\t" + "${c.blocked_ips}".replace("['", "").replace("']", "").replace("', '", "\n\t") + "\n}\n"

	if c.ip_logs.len > 0 {
		log += "[@IP_LOGS]\n{\n"
		for date, ip_log in c.ip_logs
		{
			log += "\t[@${date}]\n{\n${ip_log}"
		}
		log += "}\n"
	} else { log += "No IPs Detected, Possible UDP and//or Internal Attack\n" }

	/* Save dump file! */
	os.write_file("assets/dumps/${current_time}.csd", log) or { os.File{} }
	println("[ X ] Dump file has been created!\r\n\t=> 'assets/dumps/${current_time}.csd")
	
	/* Send attack data to discord */
	fields := {
		"{CONTENT_DATA}": "Attack has ended....",
		"{IP_ADDRESS}": "${c.conn_info.system_ip}",
		"{LOCATION}": "Canada",
		"{PROVIDER}": "OVH",
		"{CONS_CONNECTED}": "${c.ips.len}",
		"{UNDER_ATTACK}": "${c.under_attack}",
		"{FILTERING_CON_MODE}": "${c.filtering_con_mode}",
		"{DROP_CON_MODE}": "${c.drop_con_mode}",
		"{BLOCKED_IPS}": "${c.blocked_ips.len}",
		"{ABUSED_PORT}": "${c.abused_port.len}",
		"{CURRENT_TIME}": "${current_time}",
	}
	utils.send_discord_msg(fields)

	/* Reset objects */
	c.ip_logs = map[string]string{}
	c.blocked_ips = []string{}
	c.abused_port = []int{}
}

pub fn (mut c CyberShield) port_used_count(port int) int
{
	mut cnt := 0 
	for con in c.ips {
		if con.internal_port == port { cnt++ }
	}

	return cnt
}