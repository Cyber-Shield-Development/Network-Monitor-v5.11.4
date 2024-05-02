module config

import src.shield.utils

pub struct ConnTableSettings 
{
	pub mut:
	    display               	bool
        table               	[]string
        border_c              	[]string
        text_c                	[]string
}

pub fn parse_conntable_settings(lines []string) ConnTableSettings
{
    mut conntable := ConnTableSettings{}
    
    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"           { conntable.display           = utils.match_starts_with(key, "display").bool() }
            "table"           	{ conntable.table             = utils.trim_many(utils.match_starts_with(key, "table"), ["[", "]", "[", "]"]).split(",") }
            "border_c"          { conntable.border_c          = utils.trim_many(utils.match_starts_with(key, "border_c"), ["[", "]", "[", "]"]).split(",") }
            "text_c"            { conntable.text_c            = utils.trim_many(utils.match_starts_with(key, "text_c"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return conntable
}
