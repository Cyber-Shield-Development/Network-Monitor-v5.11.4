module shield

import net
import rand

/*
*	MONITOR SERVER
*	PUBLIC AND PRIVATE USER PORT(s) Incase public port gets maxed bc who care abt ppl LOL!
*/
pub struct Server 
{
	pub mut:
		clients 					[]net.TcpConn

		monitor 					Monitor
		pmonitor					Monitor

		enable 						bool
		ssh							net.TcpListener
		sshp						int
		ssh_pw 						string
}

pub struct Monitor {
	pub mut:
		enable 			bool
		listener		bool
		port 			int
		socket 		    net.TcpListener
}

pub fn start_new_server(p int) Monitor {
	mut sock := net.listen_tcp(.ip6, ":${p}") or {
		return Monitor{}
	}

	return Monitor {
		enable: true,
		port: p,
		socket: sock
	}
}

/*
*	[@DOC]
*	pub fn start_servers(m int, ownerp int, s int) Server
*
*	- Start up the network monitor
*/
pub fn start_servers(m int, mport int, s int) Server {
	mut svr := Server{
		enable: true,
		monitor: Monitor{port: mport},
		pmonitor: Monitor{port: m},
		sshp: s
	}

	svr.monitor = start_new_server(mport)
	svr.pmonitor = start_new_server(m)
	match false {
		svr.monitor.enable { println("[ X ] Error, Unable to start Private Server on ${mport}") }
		svr.pmonitor.enable { println("[ X ] Error, Unable to start Public Server on ${m}") }
		else {}
	}

	svr.ssh = net.listen_tcp(.ip6, ":${s}") or {
		println("[ X ] Error, Unable to start SSH server....!")
		return svr
	}

	return svr
}

/*
*	[@DOC]
*	pub fn (mut s Server) toggle_monitor_listener()
*
*	- Toggle monitor server
*/
pub fn (mut m Monitor) toggle_monitor() {
	if m.enable {
		m.enable = false
		m.listener = false
		m.socket.close() or { return }
		println("[ X ] Monitor listener is turning off.....")
		return
	}

	m.enable = true
	m.listener = true
	m.socket = net.listen_tcp(.ip6, ":${m.port}") or {
		println("[ X ] Error, Unable to start Monitor server.....!")
		return
	}
	println("[ + ] Monitor listener is starting up....")
}

/*
*	[@DOC]
*	pub fn (mut s Server) restart_public_monitor()
*
*	- Restart the public monitor
*/
pub fn (mut m Monitor) restart_public_monitor() {
	m.socket.close() or { return }
	m.socket = net.listen_tcp(.ip6, ":${m.port}") or { return }
	println("[ + ] Monitor has successfully restarted....!")
}

/*
*	[@DOC]
*	pub fn (mut s Server) change_port_n_restart() int
*
*	- Change the monitor port and restart the server
*/
pub fn (mut m Monitor) change_port_n_restart() int {
	m.socket.close() or { return -1 }
	num := rand.int_in_range(3, 65534) or { return -1 }
	m.port = num
	m.restart_public_monitor()
	println("[ + ] Monitor port was changed to ${num} and server has restarted.....!")
	return num
}