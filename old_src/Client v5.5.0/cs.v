/*
*
*	[ CYBER SHIELD ]
*
*	@title: CyberShield
*	@version: 5.2.0
*	@author: Jeffery / Algorithm
*	@since:  2/20/24
*/
import os
import time

import shield
import shield.utils

pub const (
	help = "Name              Description
_____________________________________________________
-i                Set an Interface
-mp               Set a Max PPS before attack mode
-p                Set a socket port
-pw 			  Set a password for backup SSH
-w                Set an API port
-d                Drop connections on a port
     <port>       Port to drop all connections on
-tui              Set a TUI Theme Pack
     <theme_name> Name of the theme
-ssh              View or Edit SSH Ports
     -add <port>  Add another Port
     -rm <port>   Remove an SSH Port
     <view>       View all active SSH Ports"
	 
	invalid_argument = "[ X ] Error, Invalid arguments provided\r\nUse --h|--help flag for a list of help commands"
)

fn main() 
{

	args := os.args.clone()
	mut port := 0
	
	/* Start-up command handler */
	if args.len < 3 {
		println("[ X ] Error, Invalid arguments provided\r\nUse --h|--help flag for a list of help commands")
		exit(0)
	} else if '--h' in args || '--help' in args {
		println(help)
		exit(0)
	} else if "--d" in args {
		if args.len != 3 {
			println(invalid_argument) exit(0)
		}
		os.execute("fuser -k ${args[2]}")
	}  else if '-ssh' in args {
		/*
		*	- SSH Argument Handler
		*/
		if args.len < 2 { println(invalid_argument) exit(0) }
		match args[2]
		{
			"view" {
				ports, check := utils.check_custom_port_enable()
				println("Custom Ports: ${check}\r\nPorts:")
				for prt in ports { println(prt) }
			}
			"add" {
				port = args[3].int()
				if port == 0 { println(invalid_argument) exit(0) }

				utils.add_port(port)
			}
			"rm" {
				port = args[3].int()
				if port == 0 { println(invalid_argument) exit(0) }

				utils.rm_port(port)
			} else {
				println(invalid_argument)
			}
		}
		exit(0)
	}

	/* Ensure the following argument flags are provided */
	for element in ['-i', '-mp']
	{
		if element !in args { 
			println("[ X ] Error, Invalid arguments provided\r\nUse --h|--help flag for a list of help commands")
			exit(0)
		}
	}
	
	/* 
	*  Initatalize CyberShield struct and toggle settings 
	*  from start-up command line
	*/
	mut cs := src.CyberShield{}
	for i, arg in args 
	{
		match arg 
		{
			"-i" {
				cs.interfacee = args[i+1]
			}
			"-pw" {
				if args.len < i+1 { println("${invalid_argument}") exit(0) }
				cs.ssh_pw = args[i+1]
				cs.ssh_port = args[i+2].int()
				println("${utils.success_sym} Starting backup SSH on ${cs.ssh_port}.....")
			}
			"-mp" {
				cs.max_pps = args[i+1].int()
			}
			"-p" {
				cs.cnc_port = args[i+1].int()
			}
			"-tui" {
				cs.ui_mode = true
				cs.set_theme(args[i+1])
			}
			"-hide" {
				cs.hide_ip = true
			}
			"-reset" {
				cs.reset_tables = true
			} else {}
		}
	}
	
	/* Thread the monitor */
	go src.monitor(mut &cs)

	/* Local CMD-Line tool */
	local_cmd_handler(mut cs)
}