module src

import io
import net
import time
import rand
import x.json2 as json

pub const (
	/* 
	*	Accepted incoming commands
	*/
	commands 	= [
		"access_authentication",
		"app_ping",
		
		"vpn_authentication",
		"vpn_connect",
		"vpn_disconnect",
		"vpn_ping",
	]

	/*
	*	Keys must be in the JSON field!
	*/
	forced_keys		= [ "cmd", "hwid" ]
)

pub struct License
{
	pub mut:
		vpns		[]VPN // VPN(s) Database
		app_users 	[]AppUser // Monitor/Protection User Database
		vpn_users	[]VPNUser // VPN User Database

		cnc_port 	int
		clients 	[]Client // Clients currently logged in
		cnc_server	net.TcpListener

		web_port 	int
}

pub fn (mut c Client) app2api() map[string]string
{
	return {
		"session_id": "${c.session_id}",
		"notification_access": c.app_info.notification_access,
		"dump_acceess": c.app_info.dump_acceess,
		"filter_access": c.app_info.filter_access,
		"drop_access": c.app_info.drop_access
	}
}

pub fn (mut c Client) vpn2api() map[string]string
{
	return {
		"session_id": "${c.session_id}",
		"plan": "${c.vpn_info.plan}",
		"expiry": c.vpn_info.expiry,
		"rank": "${c.vpn_info.rank}"
	}
}

pub fn start_websocket(users []AppUser, v_users []VPNUser, vpns []VPN, cnc_p int)
{
	mut license := License{
		app_users: users,
		vpn_users: v_users,
		cnc_port: cnc_p,
		vpns: vpns
	}

	println("${license.vpns}")
	
	license.cnc_server = net.listen_tcp(.ip6, ":${cnc_p}") or {
		println("[ X ] Error, Unable to start CyberShield's License Server")
		exit(0)
	}

	license.listener()
}

/*
*	- Socket listener
*/
pub fn (mut license License) listener()
{
	for
	{
		println("[ + ] Listening for connections....!")
		mut client := license.cnc_server.accept() or {
			println("[ X ] Error, Unable to accept connection") 
			continue 
		}

		client.set_read_timeout(time.infinite)
		go license.handle(mut client)
	}
}

/*
*	[DOC]
*	pub fn (mut license License) handle(mut socket net.TcpConn)
*
*	- Authenticate the Client using the following authentication JSON format below
*/
pub fn (mut license License) handle(mut socket net.TcpConn)
{
	/* Retrieve the proper data */
	mut reader 			:= io.new_buffered_reader(reader: socket)
	mut auth_info 		:= reader.read_line() or { return }
	mut client_ip 		:= socket.peer_ip() or { "" }
	client_ip 			= client_ip.replace("[::ffff:", "").split("]:")[0]

	/*
	*	- Replace single quotes with double quotes becuase
	*	  x.json2 module doesn't accept single quotes
	*	- Temporary fix for broken JSONs
	*/
	auth_info = auth_info.replace("'", "\"")
	if !"${auth_info}".contains("\"}") {
		auth_info = auth_info + "\"}"
	}

	/* Only allow localhost */
	if client_ip != "127.0.0.1" { return }

	/* Ensuring the data recieved is JSON data */
	if !auth_info.trim_space().starts_with("{") || !auth_info.trim_space().ends_with("}") {
		println("[ X ] Error, Invalid JSON authentication information provided....")
		return
	} 
	
	/* Check for keys in JSON response */
	json_data := (json.raw_decode("${auth_info}") or { json.Any{} }).as_map()
	for key in forced_keys {
		if key !in forced_keys { 
			socket.write_string("[ X ] (AUTH) Error, Invalid JSON data received....\r\n") or { 0 }
			println("[ X ] (AUTH) Error, Invalid JSON data received....")
			return
		}
	}

	/* Accept the proper JSON data */
	lid 		:= (json_data['lid']		or { "" }).str() // VPN | CS PROTECTION
	username 	:= (json_data['username']	or { "" }).str() // VPN
	password 	:= (json_data['password']	or { "" }).str() // VPN
	cmd 		:= (json_data['cmd'] 		or { "" }).str() // VPN | CS PROTECTION
	hwid 		:= (json_data['hwid'] 		or { "" }).str() // VPN | CS PROTECTION
	sid 		:= (json_data['sid'] 		or { "" }).str() // VPN | CS PROTECTION
	data 		:= (json_data['data'] 		or { "" }).str() // VPN | CS PROTECTION
	vpn_name 	:= (json_data['vpn'] 		or { "" }).str() // VPN
	
	/* Validate Command */
	if cmd !in commands { 
		println("[ X ] Error, Invalid command provided....!\r\n\t=>${cmd}")
		return
	}

	println("[ + ] Incoming command from ${hwid}....!")

	/* Sign In Validation */
	license.authenticate(mut socket, json_data)

	/* 
	* Command Handler 
	*/
	match cmd {
		"app_ping" {
			// TDOD: validate HWID and sid

			mut client := license.find_client(sid)
			if client.app_info.hwid != hwid && client.session_id != sid {
				socket.write_string("[ X ] Error, Invalid operation!\n") or { 0 }
				socket.close() or { return }
				return 
			}

			client.last_online = data
			println("[ + ] New ping from ${client.hwid} @ ${data}")
			socket.write_string("[ + ]") or { return }
			socket.close() or { return }
			return
		}
		"vpn_connect" {
			// TODO: Check for client then validate the session ID and HWID
			// read config file and return it to endpoint via socket

			config := get_vpn_file("${vpn_name}").replace("\n", "\\\\").trim_space()
			if config != "" {
				socket.write_string("[ + ]${config}\n") or { 0 }
				socket.close() or { return }
				return
			}

			socket.write_string("[ X ]") or { 0 }
			socket.close() or { return }
			return
		}
		"vpn_ping" {

			mut client := license.find_client(sid)
			if client.app_info.hwid != hwid && client.session_id != sid {
				socket.write_string("[ X ] Error, Invalid operation!\n") or { 0 }
				socket.close() or { return }
				return 
			}

			client.last_online = data
			println("[ + ] New ping from ${client.hwid} @ ${data}")
			socket.write_string("[ + ]") or { return }
			socket.close() or { return }
			return
		} else {}
	}
}

/*
*	[ Request authenticator ]
*	- Every request must contains the SessionID to 
*     a loggedin session or a License to open a new session
*   - All loggedin session must recieves a request or disconnect the user
*	  upon next request. 
*	- Check for an existing loggedin session and verify the last ping.
*	  a user must re-sign or automating it in clients which is optional
*     to the developer
*/
pub fn (mut license License) authenticate(mut socket net.TcpConn, json_data map[string]json.Any) Client
{
	lid 		:= (json_data['lid']		or { "" }).str() // VPN | CS PROTECTION
	username 	:= (json_data['username']	or { "" }).str() // VPN
	password 	:= (json_data['password']	or { "" }).str() // VPN
	cmd 		:= (json_data['cmd'] 		or { "" }).str() // VPN | CS PROTECTION
	hwid 		:= (json_data['hwid'] 		or { "" }).str() // VPN | CS PROTECTION
	sid 		:= (json_data['sid'] 		or { "" }).str() // VPN | CS PROTECTION

	/* Sign In Validation */
	mut login_chk := Client{}

	/* New Client Struct */
	/* Replaced with loggedin struct if user is logged in */
	mut client := Client{
		app_info: license.find_app_user(lid), // Returns empty struct if license is not found
		vpn_info: license.find_vpn_user(username), // Returns empty struct if user is not found
		session_id: generate_id(25) // Generate a new session_id
	}

	match cmd 
	{
		"access_authentication" {
			login_chk = license.is_user_loggedin(sid, "")
			/* 
			* 	- Verify if user is already signed in 
			* 	- Grab HWID / IP_LOCK upon first request
			*/
			if !login_chk.loggedin_app && !login_chk.loggedin_vpn {
				if client.app_info.license_id == "" {
					socket.write_string("[ X ] Error, Invalid access\n") or { 0 }
					socket.close() or { return Client{} }
					return Client{}
				}

				if client.app_info.hwid == "" {
					// set new hwid
				}

				if client.app_info.ip_lock == "" {
					// set new iplock
				}
				license.clients << client
				license.send_response(mut socket, "[ + ] Successfully authorized!//${client.app2api()}\r\n")
				println("[ + ] User successfully logged in....!\r\n\t=> License: ${lid}")
			}

			license.send_response(mut socket, "[ + ] Successfully authorized!//${client.app2api()}\r\n")
			println("[ + ] User successfully logged in....!\r\n\t=> License: ${lid}")
			return Client{}
		}
		
		"vpn_authentication" {
			login_chk = license.is_user_loggedin("", username)
			// TDOD: Check for user and validate HWID
			// TODO: CHECK IF USER IS ALREADY SIGNIN IN THE MONITOR APP BEFORE USING NEW CLIENT STRUCT 
 
			if !login_chk.loggedin_app || !login_chk.loggedin_vpn {
				if client.vpn_info.name == "" {
					socket.write_string("[ X ] Error, Invalid access\n") or { 0 }
					socket.close() or { return Client{} }
					return Client{}
				}
				/* Append the struct to the array of clients and send response */
				license.clients << client
			}

			
			vpns := license.vpns2str(client.vpn_info.plan).replace("\n", "-")
			license.send_response(mut socket, "[ + ] Successfully authorized!//${client.vpn2api()}\\\\${vpns}")
			println("[ + ] User successfully logged in....!\r\n\t=> Username: ${client} | HWID: ${hwid}")
			return Client{}
		} else {}
	}

	return Client{}
}

pub fn (mut license License) send_response(mut socket net.TcpConn, data string) {
	socket.write_string("${data}\n") or { 0 }
	socket.close() or { return }
}

pub fn (mut license License) is_user_loggedin(sid string, username string) Client
{
	for mut client in license.clients {
		if (sid != "" && sid == client.session_id) || (username != "" && username == client.vpn_info.name) {
			return client
		}
	}
	return Client{}
}

/* 
*	[@DOC]
* 	pub fn fetch_all_vpns(db_data string) []VPN
*
*	- Fetch all vpns from file!
*/
pub fn fetch_all_vpns(db_data string) []VPN
{
	mut all_vpns := []VPN{}
	json_obj := (json.raw_decode(db_data) or { json.Any{} }).as_map()
	for name, info in json_obj
	{
		api_info := (json.raw_decode("${info}") or { json.Any{} }).as_map()
		all_vpns << VPN{
			name: 			name,
			ip_address: 	(api_info['ip_address'] or { "" }).str(),
			location: 		(api_info['location'] or { "" }).str(),
			plan: 			(api_info['plan'] or { "" }).int()
		}
	}

	return all_vpns
}

/* 
*	[@DOC]
* 	pub fn (mut license License) fetch_user_allowed_vpns(plan int) []VPN
*
*	- Find VPNs allowed to user
*/
pub fn (mut license License) fetch_user_allowed_vpns(plan int) []VPN
{
	mut vpns := []VPN{}
	for vpn in license.vpns
	{
		if vpn.plan <= plan { vpns << vpn }
	}

	return vpns
}

/* 
*	[@DOC]
* 	pub fn (mut license License) is_vpn_validate(name string) VPN
*
*	- Check if a VPN is validate
*/
pub fn (mut license License) is_vpn_validate(name string) bool
{
	for mut vpn in license.vpns
	{
		if vpn.name == name { return true }
	}

	return false
}

pub fn (mut license License) vpns2str(plan int) string
{
	mut vpns := license.fetch_user_allowed_vpns(plan)
	mut new := ""
	for mut vpn in vpns
	{
		if plan >= vpn.plan {
			new += "${vpn.vpn2str()}\n"
		}
	}

	return new
}

/*
* 	[ UNILITIES FUNCTIONS ]
*/
pub fn generate_id(num int) string
{
	chars := "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM"

	mut new := ""
	for _ in 0..num 
	{
		randnum := rand.int_in_range(0, chars.len) or { 0 }
		new += "${chars.split("")[randnum]}"
	}

	return new
}