module src

pub struct VPNUser
{
	pub mut:
		name 	string
		ip 		string
		pw		string
		plan 	int
		expiry 	string
		rank 	int
}

pub fn fetch_vpn_users(db []string) []VPNUser
{
	mut users 		:= []VPNUser{}
	for line in db
	{
		if line.len < 2 { continue }
		user_info := line.replace("(", "").replace(")", "").replace("'", "").split(",")
		// ('USERNAME','IP','PW','PLAN','EXPIRY','RANK')
		if user_info.len > 0 {
			users << new_user(user_info)
		}
	}

	return users
}

pub fn new_user(arr []string) VPNUser
{
	return VPNUser{
		name: arr[0],
		ip: arr[1],
		pw: arr[2],
		plan: arr[3].int(),
		expiry: arr[4],
		rank: arr[5].int()
	}
}

pub fn (mut u VPNUser) is_premium() bool
{
	if u.plan > 0 { return true }
	return false
}

pub fn (mut u VPNUser) is_admin() bool
{
	if u.rank > 0 { return true }
	return false
}