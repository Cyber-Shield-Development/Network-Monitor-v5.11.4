module shield

import net

pub struct Server 
{
	pub mut:
		clients 					[]net.TcpConn
		monitor						net.TcpListener
		monitorp					string
		ssh							net.TcpListener
		sshp						string

		ssh_pw 						string

		monitor_listener_toggle		bool
		ssh_listener_toggle			bool
}

pub fn start_servers(m int, s int) Server
{
	mut svr := Server{}

	svr.monitor = net.listen_tcp(.ip6, ":${m}") or {
		println("[ X ] Error, Unable to start Monitor server.....!")
		return svr
	}

	svr.ssh = net.listen_tcp(.ip6, ":${s}") or {
		println("[ X ] Error, Unable to start SSH server....!")
		return svr
	}

	return svr
}

pub fn (mut s Server) toggle_monitor_listener() {
	if s.monitor_listener_toggle {
		println("[ + ] Monitor listener is turning off.....")
		s.monitor_listener_toggle = false
		s.monitor.close() or { return }
	} else {
		println("[ + ] Monitor listener is starting up....")
		s.monitor_listener_toggle = true
		s.monitor = net.listen_tcp(.ip6, ":${s.monitorp}") or {
			println("[ X ] Error, Unable to start Monitor server.....!")
			return
		}
	}
}