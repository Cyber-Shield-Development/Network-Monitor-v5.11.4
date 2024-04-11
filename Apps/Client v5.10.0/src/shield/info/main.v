module info 

pub struct SystemInformation 
{
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