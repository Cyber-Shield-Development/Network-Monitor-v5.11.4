import os

import src
import src.shield
import src.shield.info.net.netstat as ns 

pub const (
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
-i                     Set an Interface
-hide                  Hide IP on the Monitor
-mp                    Set a Max PPS before attack mode
-p                     Set a socket port
-pw 			       Start a SSH backup access port
     <pw>              Set a password for SSH backup access
	 <port>            Set a socket port for SSh backup access

-w                     Start an API server
     <port>            Set a port for API server

-d                     Drop connections on a port
     <port>            Port to drop all connections on

-tui                   Set a TUI Theme Pack
     <theme_name>      Name of the theme

-ssh                  View or Edit SSH Ports
     add <port>       Add another Port
     rm <port>        Remove an SSH Port
     <view>           View all active SSH Ports

-ovpn                 OpenVPN Tools
     port <port>      Change OpenVPN port
     type <udp/tcp>   Change OpenVPN Protocol"
)

fn main() 
{
	mut c := shield.CyberShield{}
	mut theme := ""

	args := os.args.clone()

	if args.len < 2 {
		println(src.invalid_arguments)
		exit(0)
	} else if args[0] in ['--h', '--help'] {
		println(start_cmd_list)
		exit(0)
	}

	/* Retrieve Main Startup Flags */
	if "-i" !in args {
		println("${src.invalid_arguments}\r\n${interface_usage}")
		exit(0)
	}

	if "-i" in args { c.network_interface = get_flag_value(args, "-i") }
	if "-tui" in args { theme = get_flag_value(args, "-tui") }
	if "-p" in args { c.cnc_port = get_flag_value(args, "-p").int() }
	go shield.cyber_shield(mut &c, theme)
	
	/* Handle optional flags */
	handle_startup_cmd(mut c, args)

	src.local_cmd_handler(mut c)
}

pub fn handle_startup_cmd(mut c shield.CyberShield, args []string)
{
	for arg in args 
	{
		match arg 
		{
			"-p" {
				c.cnc_port = get_flag_value(args, "-p").int()
				// TODO: Write a function to restart server upon port change 
			}
			"-mp" {
				c.config.protection.max_pps = get_flag_value(args, "-mp").int()
			}
			"-mc" {
				c.config.protection.max_connections = get_flag_value(args, "-mc").int()
			}
			"-sshp" {
				c.ssh_port = get_flag_value(args, "-sshp").int()
			}
			"-pw" {
				c.servers.ssh_pw = get_flag_value(args, "-pw")
			} else {}
		}
	}
}

pub fn get_flag_value(arr []string, flag string) string {
	for i, element in arr {
		if flag == element { return arr[i+1] }
	}

	return ""
}