import net.http
import net
import time
import os
import x.json2 as json

struct AuthResponse {
	pub mut:
		session_id            string
		notification_access   string
		dump_access           string
		filter_access         string
		drop_access           string
		hwid				  string
		license_id			  string
}

fn (mut auth AuthResponse) load(fjson map[string]json.Any) {
	auth.session_id          = fjson['session_id']           or { "" }.str()
	auth.notification_access = fjson['notification_access']  or { "" }.str()
	auth.dump_access         = fjson['dump_access']          or { "" }.str()
	auth.filter_access       = fjson['filter_access']        or { "" }.str()
	auth.drop_access         = fjson['drop_access']          or { "" }.str()
}

fn authenticate(license_id string, hwid string) !AuthResponse {
	mut resp 	 := AuthResponse{}
    mut response := http.get_text("http://127.0.0.1/auth?license_id=abP7wcJRluTlDGt5twPZpDODAFYCSxm4&hwid=8e02071b824244a88c32304645037ced")
	if response.contains('[ + ] Successfully authorized!') {
		response = response.replace('[ + ] Successfully authorized!//', '').replace("'", '"')
		auth := json.raw_decode(response) or {
			return error('Failed to parse the response: ${err}')
		}
		resp.load(auth.as_map())
		return resp
	}
	return error('Failed to authenticate: ${response}')
}

fn (mut auth AuthResponse) clientloop(server_ip string, server_port int) ! {
	mut fd := net.dial_tcp("${server_ip}:${server_port}") or {
		return error("Failed to connect to the server") 
	}

	fd.write_string('{"cmd":"client_authentication", "license_id":"${auth.license_id}", "hwid": "${auth.hwid}", "sid":"${auth.session_id}"}\n') or {
		return error("Failed to send the message")
	}
	
	// Example of message structure: '{"cmd":"PING", "license_id":"$license_id", "data":"$ping_data"}'
	for {
		fd.write_string('{"cmd":"PING", "license_id":"${auth.license_id}", "data":"TEST"}\n') or {
			return error("Failed to send the message")
		}
		time.sleep(5 * time.second)
	}
}

fn get_hwid() string {
	return os.read_file('/var/lib/dbus/machine-id') or { return 'NOT_FOUND' }
}

fn main() {
	mut hwid := get_hwid()
	println('HWID: $hwid')
	if hwid == 'NOT_FOUND' {
		println('Failed to get the HWID')
		return
	}
	mut auth := authenticate('abP7wcJRluTlDGt5twPZpDODAFYCSxm4', hwid) or {
		println('${err}')
		return
	}
	println('Authenticated: $auth')
	auth.clientloop('127.0.0.1', 5472) or {
		println('Failed to start the client loop: ${err}')
		return
	}
	println('Authenticated: $auth')
}