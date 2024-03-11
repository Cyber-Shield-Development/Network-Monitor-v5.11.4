import net.http
import net
import x.json2 as json

struct AuthResponse {
	mut:
		session_id            string
		notification_access   string
		dump_access           string
		filter_access         string
		drop_access           string
}

fn (mut auth AuthResponse) load(fjson map[string]json.Any) {
	auth.session_id          = fjson['session_id']           or { "" }.str()
	auth.notification_access = fjson['notification_access']  or { "" }.str()
	auth.dump_access         = fjson['dump_access']          or { "" }.str()
	auth.filter_access       = fjson['filter_access']        or { "" }.str()
	auth.drop_access         = fjson['drop_access']          or { "" }.str()
}

fn authenticate(license_id string, hwid string) !AuthResponse {
	mut resp := AuthResponse{}
    mut response := http.get('http://localhost:80/auth?license_id=$license_id&hwid=$hwid') or {
        return error('Failed to send the request: ${err}')
    }
    if response.status_code != 200 {
        return error('Server returned an error: ${response.status_code}')
    }
	if response.body.str().contains('[ + ] Successfully authorized!') {
		response.body = response.body.str().replace('[ + ] Successfully authorized!//', '').replace("'", '"')
		auth := json.raw_decode(response.body.str()) or {
			return error('Failed to parse the response: ${err}')
		}
		resp.load(auth.as_map())
		return resp
	}
	return error('Failed to authenticate: ${response.body.str()}')
}

fn (mut auth AuthResponse) clientloop(server_ip string, server_port int, license_id string, ping_data string) {
	mut fd := net.dial_tcp("${server_ip}:${server_port}") or {
		return error("Failed to connect to the server: ${fd.error()}") 
	}
	
	// Example of message structure: '{"cmd":"PING", "license_id":"$license_id", "data":"$ping_data"}'
	for {
		fd.write_string('{"cmd":"PING", "license_id":"$license_id", "data":"$ping_data"}\n') or {
			return error("Failed to send the message: ${fd.error()}")
		}
	}
}