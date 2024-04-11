import os
import time
import vweb

import src

pub struct API 
{
	vweb.Context
	pub mut:
		app_users 	[]src.AppUser
		vpn_users	[]src.VPNUser
}


fn main()
{
	println("[ + ] Loading license database.....!")
	mut db 			:= os.read_lines("assets/db/ids.db") or { 
		println("[ X ] Error, Unable to read database.....!")
		exit(0)
	}

	mut v_db 		:= os.read_lines("assets/db/users.db") or { 
		println("[ X ] Error, Unable to read database.....!")
		exit(0)
	}

	mut vpn_db 		:= os.read_file("assets/db/vpns.json") or {
		println("[ X ] Error, Unable to read VPN DB.....!")
		exit(0)
	}


	mut a_users := src.fetch_app_users(db)
	mut v_users := src.fetch_vpn_users(v_db)
	mut vpns 	:= src.fetch_all_vpns(vpn_db)
	println("[ + ] License database loaded.....\r\n[ + ] Starting up License Server.....!")

	go src.start_websocket(a_users, v_users, vpns, 5472)
	vweb.run(&API{app_users: a_users, vpn_users: v_users}, 80)
}

/*
* 		[ Webserver ]
*
*	- A home and auth page only for the license system
*/
@['/index']
pub fn (mut a API) index() vweb.Result
{
	return a.text("Welcome To Cyber Shield's License Authentication API...")
}

@['/monitor/auth']
pub fn (mut a API) auth() vweb.Result 
{
	lid 			:= a.query['lid'] or { "" }
	hwid			:= a.query['hwid'] or { "" }
	ip 				:= a.ip()

	if lid == "" || hwid == "" {
		return a.text("[ X ] Error, Invalid data provided....!")
	}

	auth_info := {
		"cmd": "access_authentication",
		"lid": lid,
		"hwid": hwid
	}

	data := src.send_cmd(auth_info)
	return a.text("${data}")
}

@['/monitor/ping']
pub fn (mut a API) app_ping() vweb.Result 
{
	sid 			:= a.query['sid'] or { "" }
	hwid			:= a.query['hwid'] or { "" }
	ip 				:= a.ip()

	if sid == "" || hwid == "" {
		return a.text("[ X ] Error, Invalid data provided....!")
	}

	current_time := "${time.now()}".replace("-", "/").replace(" ", "-")
	auth_info := {
		"cmd": "app_ping",
		"sid": sid,
		"hwid": hwid,
		"data": "${current_time}"
	}

	data := src.send_cmd(auth_info)
	return a.text("${data}")
}

@['/vpn/auth']
pub fn (mut a API) vpn_auth() vweb.Result
{
	username 		:= a.query['user'] or { "" }
	password		:= a.query['pass'] or { "" }
	hwid			:= a.query['hwid'] or { "" }
	ip 				:= a.ip()

	if username == "" || password == "" || hwid == "" { 
		return a.text("[ X ] Error, Invalid data provided....!")
	}
	
	auth_info := {
		"cmd": "vpn_authentication",
		"username": username,
		"password": password,
		"hwid": hwid
	}

	data := src.send_cmd(auth_info)
	return a.text(data)
}

@['/vpn/connect']
pub fn (mut a API) vpn_connect() vweb.Result
{
	vpn				:= a.query['vpn'] or { "" }
	sid 			:= a.query['sid'] or { "" }
	user 			:= a.query['user'] or { "" }
	hwid 			:= a.query['hwid'] or { "" }
	ip 				:= a.ip()

	if vpn == "" || sid == "" || hwid == "" {
		return a.text("[ X ] Error, Invalid data provided....!")
	}

	connect_info 	:= {
		"cmd": "vpn_connect",
		"username": "${user}",
		"sid": "${sid}",
		"hwid": "${hwid}",
		"vpn": "${vpn}"
	}

	data := src.send_cmd(connect_info)
	return a.text(data)
}

@['/vpn/ping']
pub fn (mut a API) vpn_ping() vweb.Result
{
	username 	:= a.query['user'] or { "" }
	hwid 		:= a.query['hwid'] or { "" }
	sid 		:= a.query['sid'] or { "" }

	current_time := "${time.now()}".replace("-", "/").replace(" ", "-")
	ping_info := {
		"cmd": "vpn_ping",
		"sid": "${sid}",
		"hwid": "${hwid}",
		"data": "${current_time}"
	}

	data := src.send_cmd(ping_info)
	return a.text(data)
}