module config

import src.shield.utils 
pub struct HardwareSettings 
{
	pub mut:
        display                	bool
        value_c                	[]string
        cpu_name            	[]string
        cpu_cores            	[]string
        cpu_usage            	[]string
        cpu_usage_bar           []string
        spaces_in_bar           int
        cpu_free            	[]string
        cpu_arch            	[]string
        memory_type        		[]string
        memory_capacity    		[]string
        memory_used        		[]string
        memory_free        		[]string
        memory_usage        	[]string
        hdd_name            	[]string
        hdd_capacity        	[]string
        hdd_used            	[]string
        hdd_free            	[]string
        hdd_usage            	[]string
}

pub fn parse_hdw_settings(lines []string) HardwareSettings
{
    mut hdw := HardwareSettings{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"               { hdw.display              = utils.match_starts_with(key, "display").bool() }
            "value_c"               { hdw.value_c              = utils.trim_many(utils.match_starts_with(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "cpu_name"            	{ hdw.cpu_name           	= utils.trim_many(utils.match_starts_with(key, "cpu_name"), ["[", "]", "[", "]"]).split(",") }
            "cpu_cores"           	{ hdw.cpu_cores          	= utils.trim_many(utils.match_starts_with(key, "cpu_cores"), ["[", "]", "[", "]"]).split(",") }
            "cpu_usage"           	{ hdw.cpu_usage          	= utils.trim_many(utils.match_starts_with(key, "cpu_usage"), ["[", "]", "[", "]"]).split(",") }
            "cpu_usage_bar"         { hdw.cpu_usage_bar         = utils.trim_many(utils.match_starts_with(key, "cpu_usage_bar"), ["[", "]", "[", "]"]).split(",") }
            "spaces_in_bar"         { hdw.spaces_in_bar         = utils.match_starts_with(key, "spaces_in_bar").int() }
            "cpu_free"            	{ hdw.cpu_free           	= utils.trim_many(utils.match_starts_with(key, "cpu_free"), ["[", "]", "[", "]"]).split(",") }
            "cpu_arch"            	{ hdw.cpu_arch           	= utils.trim_many(utils.match_starts_with(key, "cpu_arch"), ["[", "]", "[", "]"]).split(",") }
            "memory_type"         	{ hdw.memory_type        	= utils.trim_many(utils.match_starts_with(key, "memory_type"), ["[", "]", "[", "]"]).split(",") }
            "memory_capacity"     	{ hdw.memory_capacity    	= utils.trim_many(utils.match_starts_with(key, "memory_capacity"), ["[", "]", "[", "]"]).split(",") }
            "memory_used"         	{ hdw.memory_used        	= utils.trim_many(utils.match_starts_with(key, "memory_used"), ["[", "]", "[", "]"]).split(",") }
            "memory_free"         	{ hdw.memory_free        	= utils.trim_many(utils.match_starts_with(key, "memory_free"), ["[", "]", "[", "]"]).split(",") }
            "memory_usage"        	{ hdw.memory_usage       	= utils.trim_many(utils.match_starts_with(key, "memory_usage"), ["[", "]", "[", "]"]).split(",") }
            "hdd_name"            	{ hdw.hdd_name           	= utils.trim_many(utils.match_starts_with(key, "hdd_name"), ["[", "]", "[", "]"]).split(",") }
            "hdd_capacity"        	{ hdw.hdd_capacity       	= utils.trim_many(utils.match_starts_with(key, "hdd_capacity"), ["[", "]", "[", "]"]).split(",") }
            "hdd_used"            	{ hdw.hdd_used           	= utils.trim_many(utils.match_starts_with(key, "hdd_used"), ["[", "]", "[", "]"]).split(",") }
            "hdd_free"            	{ hdw.hdd_free           	= utils.trim_many(utils.match_starts_with(key, "hdd_free"), ["[", "]", "[", "]"]).split(",") }
            "hdd_usage"           	{ hdw.hdd_usage          	= utils.trim_many(utils.match_starts_with(key, "hdd_usage"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return hdw
}