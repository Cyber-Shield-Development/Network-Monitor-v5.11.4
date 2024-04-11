module src

import os

import src.shield
import src.shield.utils
import src.shield.utils.term

pub const (
	invalid_arguments = "[ X ] Error, Invalid arguments provided!\r\nUse '--h' or '--help' for a list of command usage!"
	help_list = ""
)

pub fn local_cmd_handler(mut c shield.CyberShield) 
{
	for {
		new_cmd := os.input("[CyberShield@ControlPanel] ~ $ ")

		if new_cmd.len > 4 {
			mut args := []string{} 
			mut cmd := ""
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
				}
				"start" {
					break
				} else { println(invalid_arguments) } 
			}
		}
	}
}