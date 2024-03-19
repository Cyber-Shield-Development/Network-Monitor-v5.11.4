import os

import src
import src.utils

pub const (
	help = "Name              Description
_____________________________________________________
-i                Set an Interface
-mp               Set a Max PPS before attack mode
-s                Set a socket port
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
				println("Custom Ports: ${check}\r\nPorts:\r\n${ports}".replace("\"", "'").replace("['", "").replace("']", "").replace("', '", "\r\n"))
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
			"-mp" {
				cs.max_pps = args[i+1].int()
			}
			"-s" {
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

fn local_cmd_handler(mut c src.CyberShield) 
{
	for {
		data := os.input("__________________________\r\n ~ $ ")

		args := data.split(" ")
		cmd := args[0]

		if data.len < 2 { continue }

		match cmd {
			"theme" {
				if args.len != 2 { continue }
				c.set_theme(args[1])
			}
			"show" { 
				println("${c}")
			}
			"clear", "cls", "c" {
				println("${utils.clear}")
			}
			"-i" {
				if args.len != 2 { continue }
				c.interfacee = args[1]
			}
			"-mp" {
				if args.len != 2 { continue }
				c.max_pps = args[1].int()
			} else {} 
		}
	}
}