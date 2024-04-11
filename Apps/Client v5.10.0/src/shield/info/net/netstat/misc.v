module netstat

import os
import src.shield.utils

pub fn grab_cons() []NetstatCon
{
	mut cons := []NetstatCon{}

	netstat_cons := os.execute("netstat -tn").output.split("\n")

	for line in netstat_cons
	{
		line_info := utils.rm_empty_elements(line.split(" "))
		if line_info.len < 4 || !line.contains(":") { continue }
		
		/* Dup Check */
		mut ncon := new_con(line_info)
		if !is_con_dupped(mut cons, ncon.external_ip) {
			ncon.dups++
			cons << ncon
			continue
		}

		// Don't add dups
		ncon.dups++
	}

	return cons
}

pub fn is_con_dupped(mut cons []NetstatCon, ip string) bool 
{
	for mut con in cons 
	{ if con.external_ip == ip && con.dups > 1 { return true } }

	return false 
}

pub fn retrieve_spammed_cons(cons []NetstatCon) NetstatCon
{
	mut current_con := NetstatCon{}
	mut highest_dups := 0

	for con in cons {
		if con.dups > highest_dups { 
			current_con = con
			highest_dups = con.dups
		}
	}

	return current_con
}