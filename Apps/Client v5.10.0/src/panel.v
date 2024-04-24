module src

import os

import src.shield
import src.shield.utils.term

pub const (
	invalid_arguments = "[ X ] Error, Invalid arguments provided!\r\nUse '--h' or '--help' for a list of command usage!"
	help_list = ""
)

pub fn local_cmd_handler(mut c shield.CyberShield) 
{
	mut args := []string{} 
	mut cmd := ""
	for {
		new_cmd := os.input("[CyberShield@ControlPanel] ~ $ ")

		cmd = new_cmd
		if new_cmd.len > 4 {
			if new_cmd.contains(" ") { 
				args = new_cmd.split(" ")
				cmd = args[0]
			}

			match cmd {
				"theme" {
					if args.len != 2 { continue }
					c.set_theme(args[1])
					break
				}
				"show" { 
					println("${c}")
				}
				"show_dump" {
					println("${c.current_dump}")
				}
				"show_protection" {
					println("${c.config.protection}")
				}
				"start" {
					// c.servers = shield.start_servers(c.cnc_port, c.owner_cnc_port, c.ssh_port)
					go shield.monitor_listener(mut &c)
					go shield.owner_monitor_listener(mut &c)
					println("[ + ] Monitor listeners started....!")
				}
				"restart_dump" {
					c.restart_attack_filter()
				}
				"change_port" {
					if args.len != 2 { continue }
					c.servers.monitorp = args[1].int()
					c.servers.toggle_monitor_listener() // Turn off
					c.servers.toggle_monitor_listener() // Turn on
					println("[ + ] Cyber Shield port changed and restarted.....!")
				}
				"clear", "cls", "c" {
					println("${term.clear}")
				}
				"interface" {
					if args.len != 2 { continue }
					c.network_interface = args[1]
				}
				"max_pps" {
					if args.len != 2 { continue }
					c.config.protection.max_pps = args[1].int()
				}
				"max_cons" {
					if args.len != 2 { continue }
					c.config.protection.max_connections = args[1].int()
				}
				"settings" {
					// c.output_settings()
					break
				}
				"stats" {
					// c.output_stats()
					break
				} else { println(invalid_arguments) } 
			}
		}
	}
}