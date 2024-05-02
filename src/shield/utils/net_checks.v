module utils

pub fn is_hostname_valid(hostname string) bool 
{
	if validate_ipv4_format(hostname) || validate_ipv6_format(hostname) {
		return true
	}

	return false
}

/* Validate IPv4 format */
pub fn validate_ipv4_format(ip string) bool 
{
	if does_str_contains_chars(ip) { return false }
	if ip.contains(":") { return false }
	args := ip.split(".")
	if args.len != 4 { return false }

	if args[0].int() < 1 || args[0].int() > 255 { return false }
	if args[1].int() < 0 || args[1].int() > 255 { return false }
	if args[2].int() < 0 || args[2].int() > 255 { return false }
	if args[3].int() < 0 || args[3].int() > 255 { return false }

	return true
}

/* Validate IPv6 format */
pub fn validate_ipv6_format(ipv6 string) bool
{
	mut buffer := ipv6
	/* Retrieve arguments in string within colons (:) */
	args := buffer.split(":")

	/* Ensure we have 8 IPv6 blocks between colon (:) */
	if args.len < 1 && args.len > 8 { return false }

	for arg in args {
		/* Ensure 1 - 4 character/numbers within each IPv6 arguments */
		if arg.len < 1 && arg.len > 4 { return false }

		/* Ensure hexidecimal characters only */
		for ch in arg 
		{ if ch.ascii_str().int() == 0 && ch.ascii_str().to_lower() !in "abcdef".split("") { return false } } 
	}

	return false
}

/* 
* 	- Validate URL format 
*/
pub fn validate_url_format(hostname string) bool 
{
	mut buffer := hostname

	// check for HTTP/HTTPS (HTTP used for both in this if statement)
	if buffer.contains("http") {
		// replace() functions used exact in-order so https handled first incase 's' for HTTP is there
		buffer = buffer.replace("https", "").replace("http", "").replace("://", "")
	}

	// counting domain name && domain extension or more
	if buffer.split(".").len < 2 { return false }

	// Check for IPv4 within full hostname
	if buffer.contains("-") {
		// Full hostname containing IPv4 with dashes (-)
		if buffer.split("-").len < 4 { return false }
	}

	return true
}

pub fn retrieve_ipv4(hostname string) string {
	if check_1(hostname) != "" {
		return check_1(hostname)
	} else if check_2(hostname) != "" {
		return check_2(hostname)
	} else {
		return check_for_ipv4(hostname)
	}

	return ""
}

pub fn check_1(url string) string {
	mut args := url.split(".")
	if args.len < 4 { return "" }
	
	for i, _ in args {
		args[i] = args[i].split("-")[0]
	}

	for i, arg in args {
		if arg.int() > 0 && arg.int() < 255 {
			if args.len-4 < i { break }
			if validate_ipv4_format(arr2ip(args[i..(i+4)])) {
				return arr2ip(args[i..(i+4)])
			}
		}
	}

	return ""
}

pub fn check_2(url string) string {
	mut args := url.split("-")
	if args.len < 4 { return "" }

	for i, _ in args {
		args[i] = args[i].split(".")[0]
	}

	for i, arg in args {
		if arg.int() > 0 && arg.int() < 255 {
			if args.len-4 < i { break }
			if validate_ipv4_format(arr2ip(args[i..(i+4)])) {
				return arr2ip(args[i..(i+4)])
			}
		}
	}

	return ""
}

pub fn check_for_ipv4(ip string) string
{
    copy := ip
	args := copy.split("-")
	if args.len < 4 { return "" }

	/* Ensure there is numbers in the URL */
	if !does_str_contains_nums(ip) {
		println("[ - ] WARNING, Unable to get IPV4 from the URL Formatted Hostname: ${ip}")
		return ""
	}

	/* Check 1 :: Parsing 5.5.5.5.lulzsec.ovh */
	if ip.split(".").len > 3 {
		if validate_ipv4_format(arr2ip(ip.split(".").clone()[0..4].clone())) {
			return arr2ip(ip.split(".")[0..4])
		}
	}

	/* Check 2 :: Parsing 5-33-154-211.wdw.net */
	mut check := rm_ending_chrs(arr2ip(args[0..4].clone()))
	if check.split(".").len == 5 { 
		check = check.split(".")[0] 
	}
	
	if validate_ipv4_format(check) { 
		return check 
	}

	/* 
	*	Check 3 :: Parsing c-32.14.62.152.monitor.net 
	*					   ec2-13-58-48-116.us-east-2.compute.amazonaws.com
	*/
	mut first_ip_arg := -1
	for i, arg in args {
		if arg.int() > 0 && !does_str_contains_chars(arg) {
			if args[i+1].int() == 0 { continue }
			first_ip_arg = i 
			break
		}
	}

	if first_ip_arg == -1 { return "" }
	if args.len >= first_ip_arg+4 { 
		check = rm_ending_chrs(arr2ip(args[first_ip_arg..(first_ip_arg+4)]))
		if validate_ipv4_format(check) {
			return check
		}
	}
	
	/* Check 3 */
	if args.len < 5 { return "" }
	if args[1].int() > 0 && !does_str_contains_chars(args[1]) {
		check = rm_ending_chrs(arr2ip(args[1..5].clone()))

		if validate_ipv4_format(check) {
			return check
		}
	}
	return ""
}
