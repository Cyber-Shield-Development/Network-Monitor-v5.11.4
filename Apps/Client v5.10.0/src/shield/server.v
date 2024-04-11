module shield

import net

pub struct Server 
{
	pub mut:
		clients 					[]net.TcpConn
		monitor						net.TcpListener
		ssh							net.TcpListener

		ssh_pw 						string

		monitor_listener_toggle		bool
		ssh_listener_toggle			bool
}

pub fn start_servers(m int, s int) Server
{
	mut svr := Server{}

	svr.monitor = net.listen_tcp(.ip6, ":${m}") or {
		println("[ X ] Error, Unable to start Monitor server.....!")
		exit(0)
	}

	svr.ssh = net.listen_tcp(.ip6, ":${s}") or {
		println("[ X ] Error, Unable to start SSH server....!")
		exit(0)
	}

	return svr
}

pub fn (mut s Server) toggle_monitor_listener() {
	if s.monitor_listener_toggle {
		println("[ + ] Monitor listener is turning off.....")
		s.monitor_listener_toggle = false
	} else {
		println("[ + ] Monitor listener is starting up....")
		s.monitor_listener_toggle = true
		// start listener
	}
}