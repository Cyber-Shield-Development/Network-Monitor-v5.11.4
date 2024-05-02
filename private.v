import os

import src.shield.utils
import src.shield.services

pub const (
	invalid_arguments = "[ X ] Error, Invalid arguments provided!\r\nUse '--h' or '--help' for a list of command usage!"
	start_usage = "Usage: ./shield -i <interface>"
	interface_usage = "Interface usage: -i eth0"
	optional_flags = "Extra Optional Recommanded Flags
To start up with a Theme for the monitor, use -tui
-tui simpsons_theme

Change max_pps upon start up. use -mp
-mp 7500

Auto clear new rules, use -reset only
-reset"
	start_cmd_list = "Name                  Description
_____________________________________________________
-drop 				  Drop a port.
-ssh                  View or Edit SSH Ports
     view             View all active SSH Ports
     start 			  Start the SSH Server
     stop             Stop the SSH Server
     restart          Restart the SSH server
     clear            Clear the SSH ports
     add <port>       Add another Port
     rm <port>        Remove an SSH Port

-ovpn                 OpenVPN Tools
     view             View all active OVPN Ports
     start 			  Start the OVPN Server
     stop             Stop the OVPN Server
     restart          Restart the OVPN server
     clear            Clear the OVPN ports"
)

fn main() {
	mut args := os.args.clone()

	if args.len < 2 {
		println("[ X ] Error, Invalid arguments provided....!")
		exit(0)
	} else if '--h' in args || '--help' in args {
		println(start_cmd_list)
		return
	}

	match args[1] {
		"drop" {
			if args.len < 3 { 
				println(invalid_arguments) 
				return
			}
			os.execute("fuser -k ${args[2]}/tcp > /dev/null; fuser -k ${args[2]}/udp > /dev/null")
		}
		"ssh" {
			ssh_cmd_handler(args[1], args)
		}
		"ovpn" {
			ovpn_cmd_handler(args[1], args)
		} else {}
	}
}

fn ssh_cmd_handler(cmd string, args []string)  {
	// ./program ssh
	if args.len < 2 {
		return
	}

	// ./program ssh drop 22
	//      0     1    2  3
	match args[2] {
		"view" {
			chk, ports := services.scan_ssh_ports()
			println("Custom SSH Port Enabled: ${chk} | " + utils.replace_many("${ports}", {"[": "", "]": "", "', '": ""}))
		}
		"start" {
			services.start_ssh()
		}
		"stop" {
			services.stop_ssh()
		}
		"restart" {
			services.restart_ssh()
		}
		"drop" {
			if args.len != 4 { 
				println(invalid_arguments)
				return
			}
			
			services.clear_ssh_ports(args[3].int())
		}
		"clear" {
			services.clear_ssh_ports(0)
		}
		"add" {
			if args.len != 4 { 
				println(invalid_arguments)
				return
			}
			services.add_ssh_port(args[3].int())
		}
		"rm" {
			if args.len != 4 { 
				println(invalid_arguments)
				return
			}
			services.rm_ssh_port(args[3].int())
		} else {}
	}
}

fn ovpn_cmd_handler(cmd string, args []string)  {
	// ./program ssh
	if args.len < 2 {
		return
	}

	// ./program ssh drop 22
	//      0     1    2  3
	match args[2] {
		"start" {
			services.start_ovpn()
		}
		"stop" {
			services.stop_ovpn()
		}
		"restart" {
			services.restart_ovpn()
		}
		"clear" {
			services.clear_ovpn_port()
		} else {}
	}
}