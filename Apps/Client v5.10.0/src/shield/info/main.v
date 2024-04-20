module info 

pub struct SystemInformation 
{
	pub mut:
		location 	string
		isp 		string
		os 			OS
		hdw 		Hardware
}

pub fn system__init(iface string) SystemInformation
{
	return SystemInformation {
		os: grab_os_info()
	}
}