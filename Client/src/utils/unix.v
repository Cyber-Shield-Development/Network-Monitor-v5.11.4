module utils 

import os
import net.http
import x.json2 as json

pub const auth_api 	    = "https://yomarket.info/auth"
pub const ping_endpoint = "https://yomarket.info/ping"

pub struct AuthResponse {
	pub mut:
		session_id            string
		notification_access   int
		dump_access           int
		filter_access         int
		drop_access           int
}

pub fn (mut auth AuthResponse) load(fjson map[string]json.Any) {
	auth.session_id          = fjson['session_id']           or { "" }.str()
	auth.notification_access = fjson['notification_access']  or { "" }.str().int()
	auth.dump_access         = fjson['dump_access']          or { "" }.str().int()
	auth.filter_access       = fjson['filter_access']        or { "" }.str().int()
	auth.drop_access         = fjson['drop_access']          or { "" }.str().int()
}

// pub fn validate(lid string) map[string]string
// {
// 	device_hwid := get_hardware_id()
// 	mut resp := http.get_text(create_get_parameters(
// 			auth_api,
// 			{
// 				"license_id": "${lid}",
// 				"hwid": "${device_hwid}"
// 			}
// 		)
// 	)
	
// 	if resp == "" || resp.contains("[ X ]") {
// 		println("[ X ] Error, No access to CyberShield....!")
// 		exit(0)
// 	}

// 	if resp != "" {
// 		resp = resp.split("//")[1].replace("'", "\"")
// 	}

// 	return json2map(
// 		(json.raw_decode("${resp}") or { json.Any{} }).as_map()
// 	)
// }

pub fn authenticate(license_id string) !AuthResponse {
	device_hwid  := get_hardware_id()
	mut resp 	 := AuthResponse{}
    // mut response := http.get_text("http://127.0.0.1/auth?license_id=abP7wcJRluTlDGt5twPZpDODAFYCSxm4&hwid=8e02071b824244a88c32304645037ced")
	mut response := http.get_text(
		create_get_parameters
		(
			auth_api,
			{
				"license_id": "${license_id}",
				"hwid": "${device_hwid}"
			}
		)
	)

	if response == "" {
		println("[ X ] Error, CyberSheild Api....!")
		exit(0)
	}

	if response.contains('[ + ] Successfully authorized!') {
		response = response.replace('[ + ] Successfully authorized!//', '').replace("'", '"')
		auth := json.raw_decode(response) or {
			println("[ X ] Error, CyberSheild Api....!")
			exit(0)
		}
		resp.load(auth.as_map())
		return resp
	}
	println("[ X ] Error, No access to CyberShield....!")
	exit(0)
}

/*
*	[@DOC]
*	fn get_hardware_id() string
*
*	- Get Device Hardware ID
*/
pub fn get_hardware_id() string
{ return os.execute("cat /var/lib/dbus/machine-id").output }

/*
*	[@DOC]
*	fn create_get_parameters(api string, field map[string]string) string
*
*	- Attaching GET parameters to an API bc V http functions are gey
*
*/
fn create_get_parameters(api string, field map[string]string) string
{
	mut new := "${api}?"

	mut c := 0
	for key, val in field 
	{
		if c == field.len-1 { new += "${key}=${val}" } 
		else { new += "${key}=${val}&" }
		c++
	}

	return new.trim_space()
}

/*
*	[@DOC]
*	fn json2map(j map[string]json.Any) map[string]string
*
* - Convert map[string]json.Any to map[string]string 
*	because V types are gey
*
*/
fn json2map(j map[string]json.Any) map[string]string
{
	mut new := map[string]string{}
	
	for key, val in j 
	{ new[key] = "${val}" }

	return new
}