module term

import net
import time

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

pub fn set_title(mut client net.TcpConn, data string) 
{
	client.write_string("\033]0;${data}\007") or { 0 }
}

pub fn set_term_size(mut c net.TcpConn, row int, col int)
{
	c.write_string("\033[?25l") or { 0 }
	c.write_string("\033[8;${row};${col}t") or { 0 }
}