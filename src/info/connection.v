module info

pub struct Connection
{
	pub mut:
		iface		string
		system_ip	string
		max_pps		int
		pps			int
		upload		string
		download	string
		ms			int
}

pub fn connection(iface string) Connection
{
	mut c := Connection{iface: iface}
	
	c.get_connection_speed()
	return c
}

pub fn (mut c Connection) get_connection_speed()
{
	
}