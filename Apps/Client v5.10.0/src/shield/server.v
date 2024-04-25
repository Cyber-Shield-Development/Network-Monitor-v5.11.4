module shield

import net

/*
*	MONITOR SERVER
*	PUBLIC AND PRIVATE USER PORT(s) Incase public port gets maxed bc who care abt ppl LOL!
*/
pub struct Server 
{
	pub mut:
		clients 					[]net.TcpConn

		owner_server 				net.TcpListener
		owner_monitorp				int

		monitor						net.TcpListener
		monitorp					int

		ssh							net.TcpListener
		sshp						int

		ssh_pw 						string

		monitor_listener_toggle		bool
		ssh_listener_toggle			bool
}

pub fn start_servers(m int, ownerp int, s int) Server
{
	mut svr := Server{
		monitor_listener_toggle: true,
		monitorp: m,
		owner_monitorp: ownerp,
		sshp: s
	}

	svr.monitor = net.listen_tcp(.ip6, ":${m}") or {
		println("[ X ] Error, Unable to start Monitor server.....!")
		return svr
	}

	svr.owner_server = net.listen_tcp(.ip6, ":${ownerp}") or {
		println("[ X ] Error, Unable to start the owner's private monitor port....!")
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
		s.owner_server.close() or { return }
	} else {
		println("[ + ] Monitor listener is starting up....")
		s.monitor_listener_toggle = true
		s.monitor = net.listen_tcp(.ip6, ":${s.monitorp}") or {
			println("[ X ] Error, Unable to start Monitor server.....!")
			return
		}
		
		s.owner_server = net.listen_tcp(.ip6, ":${s.owner_monitorp}") or {
			println("[ X ] Error, Unable to start the owner's private monitor port....!")
			return
		}
	}
}