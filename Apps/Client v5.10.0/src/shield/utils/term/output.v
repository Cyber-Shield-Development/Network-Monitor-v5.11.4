module term

import net
import time
/*
*	- Place text at a curtain position. optional color
*/
pub fn place_text(mut client net.TcpConn, pos []string, color []string, data string)
{
	if pos == [] || pos == ["0","0"] { return }

	mut create_output := "\033[${pos[0]};${pos[1]}f"
	
	// Check if a color was set or skip 
	if color != ["0","0","0"] && color.len == 3 { create_output += "\x1b[38;2;${color[0]};${color[1]};${color[2]}m" }

	// Add output data and set color to default 
	create_output += "${create_output}${data}${c_default}"

	client.write_string(create_output) or { 0 }
	time.sleep(10*time.millisecond)
}

pub fn list_text(mut c net.TcpConn, p []string, t string) {
	if p == [] || p == ["0","0"] { return }

	mut row := p[0].int()
	for line in t.split("\n") {
		c.write_string("\x1b[${row};${p[1]}f${line}") or { 0 }
		time.sleep(10*time.millisecond)
		row++
	}
}