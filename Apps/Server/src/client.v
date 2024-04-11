module src

import io
import net

pub struct Client 
{
	pub mut:
		hwid 			string
		session_id 		string

		loggedin_app 	bool
		loggedin_vpn	bool
		vpn_connected 	bool

		last_online 	string

		app_info		AppUser
		vpn_info 		VPNUser
}

/*
* - Send the server a command from API endpoints
*/
pub fn send_cmd(data map[string]string) string
{
	mut cs_server := net.dial_tcp("127.0.0.1:5472") or { return "" }
	cs_server.write_string("${data}\n") or { return "" }
	mut reader := io.new_buffered_reader(reader: cs_server)
	new := reader.read_line() or { return "" }
	cs_server.close() or { return "" }

	return new
}

/*
*	- Find a CyberShield Monitor User via License ID
*/
pub fn (mut license License) find_app_user(license_id string) AppUser 
{
	for user in license.app_users 
	{ if user.license_id == license_id { return user } }

	return AppUser{}
}

/*
*	- Find a CyberShield VPN user using username
*/
pub fn (mut license License) find_vpn_user(username string) VPNUser 
{
	for user in license.vpn_users 
	{ if user.name == username { return user }  }

	return VPNUser{}
}

/* 
*	- Find a CyberShield Monitor signed in user!
*/
pub fn (mut license License) find_client(session_id string) Client 
{
	for client in license.clients 
	{ if client.session_id == session_id { return client } }

	return Client{}
}