module src

import os
import time
import src.info

/*
*
*	THE MOST UNHITTABLE METHOD IN THE COM
*
*/
pub fn (mut c CyberShield) start_monitoring()
{
	/* Start the UI if enabled */
	for 
	{
		current_time := "${time.now()}".replace("-", "/").replace(" ", "-")
		if c.ui_mode {
			go info.get_nload_info(mut &c.conn_info)
		}

		/* Grab PPS information to parse and detect */
		mut old_pps := info.fetch_pps_info(c.interfacee)
		time.sleep(1*time.second)
		mut new_pps := info.fetch_pps_info(c.interfacee)

		/* Grab Netstat Info & Calculate PPS */
		c.pps = (old_pps.tx - new_pps.tx) - (old_pps.rx - new_pps.rx)
		c.ips = info.grab_ips()

		/* 
		* 	Detect Config Max Connections and Enable Filtering System
		*
		*	Enable filtering system once the max con OR max PPS has been reached
		*/
		if c.count_unique_cons() > c.max_connections || c.pps >= c.max_pps { 
			go c.ip2logs(c.ips)
			go c.filter()
			c.under_attack = true
		}

		/*
		* Enable drop connection system once the max PPS has been reached
		*/
		if !c.drop_con_mode && c.pps >= c.max_pps {
			go c.drop_attack()
		}

		/*
		*	- Detecting for finished or dropped attack then disables all system
		*	  and create a custom dump file.
		*/
		if (c.under_attack && !c.drop_con_mode) && c.pps < c.max_pps { 
			c.under_attack = false 
			c.drop_con_mode = false
			if c.ip_logs.len > 0 && c.blocked_ips.len > 0  { 
				c.create_log_file()
				if c.reset_tables { os.execute("sudo iptables -F; sudo iptables-save") }
				if c.auto_add_rules { c.add_personal_rules() }
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
	mut highest := 0
	for con in c.ips 
	{
		if c.count_port_used(con.internal_port) > c.max_con_per_port {
			last_port = con.internal_port
			highest = c.count_port_used(con.internal_port)
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

	
	os.write_file("assets/dumps/${current_time}.csd", log) or { os.File{} }
	c.ip_logs = map[string]string{}
	c.abused_port = []int{}
}