module utils

import net
import time

pub const (
	success_sym 	= "\x1b[32m[ + ]\x1b[39m"
	failed_sym		= "\x1b[31m[ X ]\x1b[39m"

	/*
	*	Colors
	*/
	c_default 		= "\x1b[39m"
	c_black 		= "\x1b[30m"
	c_red			= "\x1b[31m"
	c_green 		= "\x1b[32m"
	c_yellow		= "\x1b[33m"
	c_blue			= "\x1b[34m"
	c_magenta		= "\x1b[35m"
	c_cyan			= "\x1b[36m"
	c_lightgray		= "\x1b[37m"
	c_darkgray		= "\x1b[90m"
	c_lightred		= "\x1b[91m"
	c_lightgreen	= "\x1b[92m"
	c_lightyellow	= "\x1b[93m"
	c_lightblue		= "\x1b[94m"
	c_lightmagenta	= "\x1b[95m"
	c_lightcyan		= "\x1b[96m"
	c_white			= "\x1b[97m"

	/*
	*	Background Colors
	*/
	bg_default		= "\x1b[49m"
	bg_black		= "\x1b[40m"
	bg_red			= "\x1b[41m"
	bg_green		= "\x1b[42m"
	bg_yellow		= "\x1b[43m"
	bg_blue			= "\x1b[44m"
	bg_magenta		= "\x1b[45m"
	bg_cyan			= "\x1b[46m"
	bg_lightgray	= "\x1b[47m"
	bg_darkgray		= "\x1b[100m"
	bg_lightred		= "\x1b[101m"
	bg_lightgreen	= "\x1b[102m"
	bg_lightyellow	= "\x1b[103m"
	bg_lightblue	= "\x1b[104m"
	bg_lightmagenta = "\x1b[105m"
	bg_lightcyan	= "\x1b[106m"
	bg_white 		= "\x1b[107m"

	colors 			= {
		"{DEFAULT}": 			c_default,
		"{BLACK}": 				c_black,
		"{RED}": 				c_red,
		"{GREEN}": 				c_green,
		"{YELLOW}": 			c_yellow,
		"{BLUE}": 				c_blue,
		"{MAGENTA}": 			c_magenta,
		"{CYAN}": 				c_cyan,
		"{LIGHTGRAY}": 			c_lightgray,
		"{DARKGRAY}": 			c_darkgray,
		"{LIGHTRED}": 			c_lightred,
		"{LIGHTGREEN}": 		c_lightgreen,
		"{LIGHTYELLOW}": 		c_lightyellow,
		"{LIGHTBLUE}": 			c_lightblue,
		"{LIGHTMAGENTA}": 		c_lightmagenta,
		"{LIGHTCYAN}": 			c_lightcyan,
		"{WHITE}": 				c_white,
		"{BG_DEFAULT}":			bg_default,
		"{BG_BLACK}":			bg_black,
		"{BG_RED}":				bg_red,
		"{BG_GREEN}":			bg_green,
		"{BG_YELLOW}":			bg_yellow,
		"{BG_BLUE}":			bg_blue,
		"{BG_MAGENTA}":			bg_magenta,
		"{BG_CYAN}}":			bg_cyan,
		"{BG_LIGHTGRAY}":		bg_lightgray,
		"{BG_DARKGRAY}":		bg_darkgray,
		"{BG_LIGHTRED}":		bg_lightred,
		"{BG_LIGHTGREEN}":		bg_lightgreen,
		"{BG_LIGHTYELLOW}":		bg_lightyellow,
		"{BG_LIGHTBLUE}":		bg_lightblue,
		"{BG_LIGHTMAGENTA}":	bg_lightmagenta,
		"{BG_LIGHTCYAN}":		bg_lightcyan,
		"{BG_WHITE}":			bg_white
	}

	/* OTHER ASNI TERMINAL CONTROL */
	clear		 	= "\033[2J\033[1;1H"

)

pub fn replace_colors(data string) string
{
	mut new := data
	for color, val in colors
	{
		if data.contains(color)
		{
			new = new.replace(color, val)
		}
	}

	return new
}

pub fn list_text(mut c net.TcpConn, p []string, t string) {
	mut row := p[0].int()
	for line in t.split("\n") {
		c.write_string("\x1b[${row};${p[1]}f${line}") or { 0 }
		time.sleep(10*time.millisecond)
		row++
	}
}

pub fn set_title(mut client net.TcpConn, data string) 
{
	client.write_string("\033]0;${data}\007") or { 0 }
}

pub fn set_term_size(mut c net.TcpConn, row int, col int)
{
	c.write_string("\033[?25l") or { 0 }
	c.write_string("\033[8;${row};${col}t") or { 0 }
	time.sleep(80*time.millisecond)
}

pub fn place_text(mut client net.TcpConn, pos []string, data string)
{
	client.write_string("\033[${pos[0]};${pos[1]}f${data}") or { 0 }
	time.sleep(80*time.millisecond)
}

pub fn place_animated_text(mut client net.TcpConn, row int, col int, data string, delay int)
{
	client.write_string("\033[${row};${col}f") or { 0 }
	animate_text(mut client, data, delay)
}

pub fn animate_text(mut client net.TcpConn, data string, delay int, args ...string)
{
	if args.len > 0 {
		client.write_string("${args[0]}") or { 0 }
		client.write_string("${args[1]}") or { 0 }
	}

	for i in data {
		client.write_string("${i.ascii_str()}") or { 0 }
		time.sleep(delay*time.millisecond)
	}

	client.write_string("${c_default}") or { 0 }
	client.write_string("${bg_default}") or { 0 }

	if args.len > 2 {
		client.write_string("${args[2]}") or { 0 }
	}
}

pub fn loading_bar(mut client net.TcpConn)
{
	for _ in 0..2
	{
		for i in 0..78
		{
			client.write_string("${c_green}${fill_bar(i)}${c_default}") or { 0 }
			time.sleep(15*time.millisecond)
		}

		for g in 0..78
		{
			client.write_string("${c_green}${unfill_bar(g)}${c_default}") or { 0 }
			time.sleep(15*time.millisecond)
		}
	}
}

pub fn fill_bar(hashtags int) string
{
	mut empty_space := 78 - hashtags
	mut bar := ""

	for _ in 0..hashtags
	{
		bar += "#"
	}

	for _ in 0..empty_space
	{
		bar += " "
	}

	return "[${bar}]\r"
}

pub fn unfill_bar(hashtags int) string
{
	mut empty_space := 78 - hashtags
	mut bar := ""

	for _ in 0..empty_space
	{
		bar += "#"
	}

	for _ in 0..hashtags
	{
		bar += " "
	}

	return "[${bar}]\r"
}

pub fn animate_listed_text(mut client net.TcpConn, data string, delay int) 
{
	lines := data.split("\n")

	for line in lines 
	{
		client.write_string("${line}\r\n") or { 0 }
		time.sleep(delay*time.millisecond)
	}
}