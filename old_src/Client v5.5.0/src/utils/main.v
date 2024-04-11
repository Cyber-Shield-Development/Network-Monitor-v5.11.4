module utils

pub fn rm_empty_elements(arr []string) []string
{
	mut new := []string{}
	for element in arr
	{
		if element.trim_space() != "" { new << element }
	}

	return new
}

pub fn validate_ipv4_format(ip string) bool 
{
	args := ip.split(".")
	if args.len != 4 { return false }

	if args[0].int() < 1 && args[0].int() > 255 { return false }
	if args[1].int() < 0 && args[1].int() > 255 { return false }
	if args[2].int() < 0 && args[2].int() > 255 { return false }
	if args[3].int() < 0 && args[3].int() > 255 { return false }

	return true
}

pub fn count_char(data string, ch string) int
{
	mut c := 0
	for chr in data {
		if chr.ascii_str() == ch { c++ }
	}

	return c 
}