module config

import src.shield.utils

pub struct GraphSettings 
{
	pub mut:
	    display               	bool
        layout        	    	[]string
        data_width              int // Width Of Incoming Data On Graph
        data_heigth             int // Heigth Of Incoming Data On Graph
        data               		[]string // Position Of Graph Data Space
        online_data_c           []string // Server Online Status Data
        offline_data_c          []string // Server Offline Status Data
}

pub fn parse_graph_settings(data []string) GraphSettings
{
	mut graph := GraphSettings{}
    for line in data {
        key := line.split(":")
        match key[0] {
            "display"           { graph.display           = utils.match_starts_with(key, "display").bool() }
            "layout"          	{ graph.layout            = utils.trim_many(utils.match_starts_with(key, "layout"), ["[", "]", "[", "]"]).split(",") }
            "data_width"        { graph.data_width        = utils.match_starts_with(key, "data_width").int() }
            "data_heigth"       { graph.data_heigth       = utils.match_starts_with(key, "data_heigth").int() }
            "data"            	{ graph.data              = utils.trim_many(utils.match_starts_with(key, "data"), ["[", "]", "[", "]"]).split(",") }
            "online_data_c"     { graph.online_data_c     = utils.trim_many(utils.match_starts_with(key, "online_data_c"), ["[", "]", "[", "]"]).split(",") }
            "offline_data_c"    { graph.offline_data_c    = utils.trim_many(utils.match_starts_with(key, "offline_data_c"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return graph
}