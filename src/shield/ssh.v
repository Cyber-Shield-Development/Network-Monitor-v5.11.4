module shield

import os
import io
import net
import time

import src.shield.utils.term

/*
*	[@DOC]
*	pub fn ssh_listener(mut c CyberShield)
*
*	- [Private Port] Listen for new connection for SSH access/interaction
*/
pub fn ssh_listener(mut c CyberShield) {
	for {
		println("[ + ] ( SSH ) Listening for sockets.....")
		mut ssh_client := c.servers.ssh.accept() or {
			println("[ X ] Error, Unable to accept SSH socket connections....!")
			continue
		}

		if c.servers.enable && c.under_attack {
			c.servers.ssh.close() or { return }
			return
		}

		ssh_client.set_read_timeout(time.infinite)
		c.servers.clients << ssh_client
		go ssh_client_handler(mut c, mut ssh_client)
	}
}

/*
*	[@DOC]
*	pub fn ssh_client_handler(mut c CyberShield, mut socket net.TcpConn)
*
*	- SSH Access/Interaction Through Socket
*/
pub fn ssh_client_handler(mut c CyberShield, mut socket net.TcpConn)
{
	mut reader := io.new_buffered_reader(reader: socket)
	term.set_title(mut socket, "CyberShield SSH Backup Access")

	/* Request password upon SSH access */
	socket.write_string("Password: \x1b[30m") or { 0 }
	get_pw := reader.read_line() or { return }
	if get_pw != c.servers.ssh_pw {
		socket.close() or { return }
		return
	}

	socket.write_string("\x1b[32m[ + ]\x1b[39m Welcome to CyberShield's SSH Socket for Backup SSH Access....!\r\n") or { 0 }
	for {
		pwd := (os.execute("pwd").output).trim_space()
		socket.write_string("[CyberShield@SSH_SERVER] [${pwd}] #") or { 0 }
		data := reader.read_line() or {
			c.rm_socket(mut socket)
			println("[ X ] Error, Unable to accepting socket data....!")
			return
		}

		mut cmd_resp := os.execute("${data}").output
		cmd_resp = cmd_resp.replace("\n", "\r\n")
		socket.write_string("${cmd_resp}\r\n") or { 0 }
	}
}