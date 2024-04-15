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