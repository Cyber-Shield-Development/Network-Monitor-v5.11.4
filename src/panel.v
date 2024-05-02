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
				"interface" {
					if args.len != 2 { continue }
					c.network_interface = args[1]
				}

				// Edit protection settings through server side terminal
				"max_pps" {
					if args.len != 2 { continue }
					c.config.protection.max_pps = args[1].int()
				}
				"max_cons" {
					if args.len != 2 { continue }
					c.config.protection.max_connections = args[1].int()
				} 
				"theme" {
					if args.len != 2 { continue }
					c.set_theme(args[1])
				}
				// SSH Functions
				"start_ssh" { go shield.ssh_listener(mut &c) }
				"sshp" { c.servers.sshp = args[1].int() }
				"sshpw" { c.servers.ssh_pw = args[1] }

				// Debugging functions
				"show" { println("${c}") }
				"show_dump" { println("${c.current_dump}") }
				"show_protection" { println("${c.config.protection}") }

				// Restart Attack/Detection/Protection Functions
				"restart" {
					// c.servers = shield.start_servers(c.cnc_port, c.owner_cnc_port, c.ssh_port)
					c.servers.pmonitor.restart_public_monitor()
					shield.monitor_listener(mut &c)
					println("[ + ] Cyber Shield monitor has been restarted.....!")
				}
				"restart_dump" {
					c.last_attack_time = c.current_time
					c.current_dump.dump_file(c.last_attack_time, mut &c)
					c.restart_attack_filter()
				}
				"change_port" {
					if args.len != 2 { continue }
					c.servers.pmonitor.change_port_n_restart()
					println("[ + ] Cyber Shield port changed and restarted.....!")
				}
				"clear", "cls", "c" {
					println("${term.clear}")
				} else { println(invalid_arguments) } 
			}
		}
	}
}