import os
import io
import net
import rand
import time
import vweb
import x.json2 as json

pub struct User 
{
	pub mut:
		license_id 			string
		ip_lock				string
		hwid				string
		last_online 		string

		/* User Plan Settings */
		notification_access string
		dump_acceess 		string
		filter_access 		string
		drop_access			string
}

pub struct Client 
{
	pub mut:
		lid 		string
		session_id 	string
		client_ip   string
		connected	bool
		reader 		io.BufferedReader

		user 		User
		socket 		net.TcpConn

}

pub struct License
{
	pub mut:
		users 		[]User

		cnc_port 	int
		clients		[]Client
		cnc_server	net.TcpListener

		web_port 	int
}

pub struct API 
{
	vweb.Context
	pub mut:
		users 	[]User
}


fn main()
{
	println("[ + ] Loading license database.....!")
	mut users 		:= []User
	mut db 			:= os.read_lines("ids.db") or { 
		println("[ X ] Error, Unable to read database.....!")
		exit(0)
	}

	for line in db
	{
		if line.len < 2 { continue }
		user_info := line.replace("(", "").replace(")", "").replace("'", "").split(",")
		if user_info.len > 0 {
			users << user(user_info)
		}
	}

	println("[ + ] License database loaded.....\r\n[ + ] Starting up License Server.....!")

	go start_websocket(users, 5472)
	vweb.run(&API{users: users}, 80)
}

pub fn start_websocket(users []User, cnc_p int)
{
	mut license := License{users: users, cnc_port: cnc_p}
	
	license.cnc_server = net.listen_tcp(.ip6, ":${cnc_p}") or {
		println("[ X ] Error, Unable to start CyberShield's License Server")
		exit(0)
	}

	license.listener()
}

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
		go license.authenticate(mut client)
	}
}

/*
*	[DOC]
*	pub fn (mut license License) authenticate(mut socket net.TcpConn)
*
*	- Authenticate the Client using the following authentication JSON format below
*
*	{
*		"cmd": "authentication",
*		"session_id": "",
*		"hwid": ""
*	}
*/
pub fn (mut license License) authenticate(mut socket net.TcpConn)
{
	mut client_ip 		:= socket.peer_ip() or { "" }
	client_ip 			= client_ip.replace("[::ffff:", "").split("]:")[0]
	mut reader 			:= io.new_buffered_reader(reader: socket)
	mut auth_info 		:= reader.read_line() or { return }
	auth_info 			= auth_info.replace("'", "\"")
	if !"${auth_info}".contains("\"}") {
		auth_info = auth_info + "\"}"
	}
	
	println(auth_info)
	if !auth_info.trim_space().starts_with("{") || !auth_info.trim_space().ends_with("}") {
		println("[ X ] Error, Invalid JSON authentication information provided....")
		return
	}

	json_data 		:= (json.raw_decode("${auth_info}") or { json.Any{} }).as_map()
	if "license_id" !in json_data && "cmd" !in json_data {
		socket.write_string("[ X ] (AUTH) Error, Invalid JSON data received....\r\n") or { 0 }
		println("[ X ] (AUTH) Error, Invalid JSON data received....")
		return
	}

	cmd 				:= (json_data['cmd'] 			or { "" }).str()
	lid 				:= (json_data['license_id']		or { "" }).str()
	hwid 				:= (json_data['hwid'] 			or { "" }).str()

	if cmd !in ["client_authentication", "access_authentication"] { 
		println("[ X ] Error, Invalid command provided....!\r\n\t=>${cmd}")
		return
	}

	mut c_client := Client{
		user: find_user(license.users, lid),
		socket: socket,
		client_ip: client_ip
	}
	println("[ + ] New user connected.....\r\n\t=> IP: ${client_ip}\r\n\t=>License ID: ${lid}\r\n\t=> HWID: ${hwid}")

	/* Response To access_authentication Command */
	if cmd == "access_authentication" {
		if client_ip != "127.0.0.1" {
			return
		}
		c_client.session_id = generate_id(25)
		license.clients << c_client
		socket.write_string("[ + ] Successfully authorized!//${c_client.user2api()}\r\n") or { 0 }
		socket.close() or { return }
		return
	}
	
	sid := (json_data['sid'] or { "" }).str()
	c_client = license.find_client(sid)

	if sid != c_client.session_id {
		socket.write_string("[ X ] Error, Invalid operation....!\r\n") or { 0 }
		return
	}

	// Add IPLOCK/HWID Validation
	license.handle(mut c_client, mut reader)
}

pub fn (mut license License) handle(mut client Client, mut reader io.BufferedReader)
{
	// mut reader := io.new_buffered_reader(reader: client.socket)
	for 
	{
		data 				:= reader.read_line() or { "" }
		// Added too client Struct
		// mut client_ip 		:= client.socket.peer_ip() or { "" }
		// client_ip 			= client_ip.replace("[::ffff:", "").split("]:")[0]

		json_data 			:= (json.raw_decode(data) or { json.Any{} }).as_map()

		// println("DATA: ${data}")
		// println("====================================")
		// println(json_data)
		// println("====================================")
		// println(client.client_ip)

		if !data.trim_space().starts_with("{") || !data.trim_space().ends_with("}") {
			println("[ X ] (HANDLER) Error, Invalid JSON authentication information provided....${data}")
			client.socket.close() or { return }
			return
		}

		if "cmd" !in json_data {
			println("[ X ] (HANDLER) Error, Invalid JSON data received....")
			return
		}

		cmd 		:= (json_data['cmd'] 			or { "" }).str()
		lid 		:= (json_data['license_id'] 	or { "" }).str()
		ping_data	:= (json_data['data'] 			or { "" }).str()
		// if !client.user.validate_iplock(client.client_ip) || client.client_ip != "0.0.0.0" {
		// 	println("[ X ] Error, Invalid connection mismatch. Possible attacker.....")
		// 	client.socket.close() or { return }
		// 	return
		// }

		match cmd
		{
			"PING" {
				println("[ NEW PING ] ${lid} ${ping_data}")
				client.user.last_online = ping_data
			} else {}
		}
	}
}

pub fn find_user(users []User, license_id string) User 
{
	for user in users 
	{
		if user.license_id == license_id { 
			return user 
		} 
	}

	return User{}
}

pub fn (mut license License) find_client(session_id string) Client 
{
	for client in license.clients 
	{ if client.session_id == session_id { return client } }

	return Client{}
}

/*
* 		[ Webserver ]
*
*	- A home and auth page only for the license system
*/
['/index']
pub fn (mut a API) index() vweb.Result
{
	return a.text("Welcome To Cyber Shield's License Authentication API...")
}

['/auth']
pub fn (mut a API) auth() vweb.Result 
{
	lid 			:= a.query['license_id'] or { "" }
	hwid			:= a.query['hwid'] or { "" }
	ip 				:= a.ip()
	mut acc 		:= User{}
	mut new_client 	:= Client{}

	println(lid)
	println(hwid)

	if lid == "" || hwid == "" {
		return a.text("[ X ] Error, Invalid data provided....!")
	}

	mut cs_server := net.dial_tcp("127.0.0.1:5472") or {
		return a.text("[ X ] Error, Unable to connect to CyberShield's Servers....!")
	}

	auth_info := {"cmd": "access_authentication", "license_id": lid, "hwid": hwid}
	cs_server.write_string("${auth_info}\n") or { 0 }
	
	mut reader := io.new_buffered_reader(reader: cs_server)
	data := reader.read_line() or { "" }
	cs_server.close() or {
		return a.text("[ X ] Error, an error occured trying to interact with CyberShield's Server....!")

	}

	a.text("${data}")
	return a.text("[ X ] Error, Invalid operation....!")
}

/*
*
* 	[ UNILITIES FUNCTIONS ]
*
*/
pub fn generate_id(num int) string
{
	chars := "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM"

	mut new := ""
	for i in 0..num 
	{
		randnum := rand.int_in_range(0, chars.len) or { 0 }
		new += "${chars.split("")[randnum]}"
	}

	return new
}

/*
*
*	[ USER FUNCTIONS ]
*/

pub fn user(arr []string) User 
{
	if arr.len != 7 { return User{} }
	return User{
		license_id: 			arr[0],
		ip_lock: 				arr[1],
		hwid: 					arr[2],

		notification_access: 	arr[3],
		dump_acceess: 			arr[4],
		filter_access: 			arr[5],
		drop_access: 			arr[6]
	}
}

pub fn (mut c Client) user2api() map[string]string
{
	return {
		"session_id": "${c.session_id}",
		"notification_access": c.user.notification_access,
		"dump_acceess": c.user.dump_acceess,
		"filter_access": c.user.filter_access,
		"drop_access": c.user.drop_access
	}
}

pub fn (mut u User) update_iplock(ip string)
{
	u.ip_lock = ip
}

pub fn (mut u User) is_user_valid() bool
{
	if u.license_id != "" { return true }
	return false
}

pub fn (mut u User) validate_license_id(input_lid string) bool
{
	if u.license_id == input_lid { return true }
	return false
}

pub fn (mut u User) validate_iplock(ip string) bool 
{
	if u.ip_lock == ip { return true }
	return false
}

pub fn (mut u User) validate_hwid(hwid string) bool
{
	if u.hwid == hwid { return true }
	return false
}