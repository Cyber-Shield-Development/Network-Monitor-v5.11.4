module config

import src.shield.utils

pub struct OsSettings 
{
	pub mut:
        display                	bool
        value_c                	[]string
        os_name             	[]string
        os_version       		[]string
        os_kernel            	[]string
        shell                	[]string
}

pub fn parse_os_settings(lines []string) OsSettings
{
    mut os := OsSettings{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"       { os.display          	= utils.match_starts_with(key, "display").bool() }
            "value_c"       { os.value_c          	= utils.trim_many(utils.match_starts_with(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "os_name"     	{ os.os_name        	= utils.trim_many(utils.match_starts_with(key, "os_name"), ["[", "]", "[", "]"]).split(",") }
            "os_version"  	{ os.os_version     	= utils.trim_many(utils.match_starts_with(key, "os_version"), ["[", "]", "[", "]"]).split(",") }
            "os_kernel"   	{ os.os_kernel      	= utils.trim_many(utils.match_starts_with(key, "os_kernel"), ["[", "]", "[", "]"]).split(",") }
            "shell"       	{ os.shell          	= utils.trim_many(utils.match_starts_with(key, "shell"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return os
}