module config

import src.shield.utils

pub struct TerminalSettings 
{
	pub mut:
		title 		string
		size 		[]string // [Row, Col]
		tick 		[]string
}

pub fn parse_terminal_settings(data []string) TerminalSettings
{
	mut t := TerminalSettings{}
	for line in data 
	{
		key := line.split(":")
        if key[0] == "title" { 
			t.title = utils.match_starts_with(key, "title") 
		} else if key[0] == "size" { 
			t.size = utils.trim_many(utils.match_starts_with(key, "size"), ["[", "]", "[", "]"]).split(",") 
		} else if key[0] == "tick" {
			t.tick = utils.trim_many(utils.match_starts_with(key, "tick"), ["[", "]", "[", "]"]).split(",") 
		}
	}

	return t
}