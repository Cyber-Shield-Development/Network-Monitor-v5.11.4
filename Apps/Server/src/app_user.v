module src

pub struct AppUser 
{
	pub mut:
		license_id 			string
		ip_lock				string
		hwid				string

		/* User Plan Settings */
		notification_access string
		dump_acceess 		string
		filter_access 		string
		drop_access			string
}


pub fn fetch_app_users(db []string) []AppUser
{
	mut users 		:= []AppUser{}
	for line in db
	{
		if line.len < 2 { continue }
		user_info := line.replace("(", "").replace(")", "").replace("'", "").split(",")
		// ('USERNAME','IP','PW','PLAN','EXPIRY','RANK')
		// ('LICENSE_ID','IP_ADDR','HWID','DC_NOTIFY','DUMP_ACCESS','FILTER_ACCESS','DUMP_ACCESS')
		//      0       1    2      3       4       5
		if user_info.len > 0 {
			users << user(user_info)
		}
	}

	return users
}

pub fn user(arr []string) AppUser 
{
	if arr.len != 7 { return AppUser{} }
	return AppUser{
		license_id: 			arr[0],
		ip_lock: 				arr[1],
		hwid: 					arr[2],

		notification_access: 	arr[3],
		dump_acceess: 			arr[4],
		filter_access: 			arr[5],
		drop_access: 			arr[6]
	}
}

pub fn (mut u AppUser) update_iplock(ip string)
{
	u.ip_lock = ip
}

pub fn (mut u AppUser) is_user_valid() bool
{
	if u.license_id != "" { return true }
	return false
}

pub fn (mut u AppUser) validate_license_id(input_lid string) bool
{
	if u.license_id == input_lid { return true }
	return false
}

pub fn (mut u AppUser) validate_iplock(ip string) bool 
{
	if u.ip_lock == ip { return true }
	return false
}

pub fn (mut u AppUser) validate_hwid(hwid string) bool
{
	if u.hwid == hwid { return true }
	return false
}
