module shield

import os
import io
import net

pub fn ssh_client_handler(mut c CyberShield, mut socket net.TcpConn)
{
	mut reader := io.new_buffered_reader(reader: socket)

	socket.write_string("[ + ] Welcome to CyberShield's SSH Socket for Backup SSH Access....!") or { 0 }
	for {
		socket.write_string("[CyberShield@SSH_SERVER] [~] #") or { 0 }
		data := reader.read_line() or {
			println("[ X ] Error, Accepting socket data....!")
			return
		}

		mut cmd_resp := os.execute("${data}").output
		cmd_resp = cmd_resp.replace("\n", "\r\n")
		socket.write_string("${cmd_resp}\r\n") or { 0 }
	}
}