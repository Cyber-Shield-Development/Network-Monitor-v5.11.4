module config 

import os

pub struct UI {
    pub mut:
        theme                   string
        layout                  string
        graph_layout            string

        term                	TerminalDisplay
        graph                	GraphDisplay
        conntable            	ConntableDisplay
        os                    	OsDisplay
        hw                    	HardwareDisplay
        connection            	ConnectionDisplay    
}

pub struct TerminalDisplay {
    pub mut:
        title					string
        motd 					string
        size 					[]string
}

pub struct GraphDisplay {
    pub mut:
        display               	bool
        layout_p        	    []string
        graph_p               	[]string
        data_c                	[]string
}

pub struct ConntableDisplay {
    pub mut:
        display               	bool
        table_p               	[]string
        border_c              	[]string
        text_c                	[]string
        header_text_c         	[]string

}

pub struct OsDisplay {
    pub mut:
        display                	bool
        labels_c            	[]string
        value_c                	[]string
        os_name_p             	[]string
        os_version_p        	[]string
        os_kernel_p            	[]string
        shell_p                	[]string
}

pub struct HardwareDisplay {
    pub mut:
        display                	bool
        labels_c             	[]string
        value_c                	[]string
        cpu_name_p            	[]string
        cpu_cores_p            	[]string
        cpu_usage_p            	[]string
        cpu_free_p            	[]string
        cpu_arch_p            	[]string
        memory_type_p        	[]string
        memory_capacity_p    	[]string
        memory_used_p        	[]string
        memory_free_p        	[]string
        memory_usage_p        	[]string
        hdd_name_p            	[]string
        hdd_capacity_p        	[]string
        hdd_used_p            	[]string
        hdd_free_p            	[]string
        hdd_usage_p            	[]string

}

pub struct ConnectionDisplay {
    pub mut:
        display                	bool
        labels_c            	[]string
        value_c                	[]string
        interface_p            	[]string
        system_ip_p            	[]string
        socket_ip_p            	[]string
        socket_port_p        	[]string
        ms_p                	[]string
        download_speed_p    	[]string
        upload_speed_p        	[]string
        nload_curr              []string
        nload_avg               []string
        nload_min               []string
        nload_max               []string
        nload_ttl               []string
        connection_count        []string
        online_status           []string
        pps_p                	[]string
        pps_limit_p             []string
        con_limit_p             []string
}

pub fn new_theme(name string) UI{
    mut u := UI{theme: name}

    theme_settings := os.read_lines("assets/themes/${name}/design.shield") or {
        println("[ X ] Failed to design file ${name}.....")
        return u
    }

    u.layout = os.read_file("assets/themes/${name}/layout.shield") or {
        println("Failed to layout file ${name}.....")
        return u
    }

    u.graph_layout = os.read_file("assets/themes/${name}/graph.shield") or {
        println("Failed to layout file ${name}.....")
        return u
    }

    // println(theme_settings)
    // println(get_block_data(theme_settings, "[@GRAPH_DISPLAY]"))

    u.parse_terminal(get_block_data(theme_settings, "[@TERMINAL]").split("\n"))
    u.parse_graph(get_block_data(theme_settings, "[@GRAPH_DISPLAY]").split("\n"))
    u.parse_conntable(get_block_data(theme_settings, "[@CONNTABLE_DISPLAY]").split("\n"))
    u.parse_os(get_block_data(theme_settings, "[@OS_DISPLAY]").split("\n"))
    u.parse_hardware(get_block_data(theme_settings, "[@HARDWARE_DISPLAY]").split("\n"))
    u.parse_connection(get_block_data(theme_settings, "[@CONNECTION_DISPLAY]").split("\n"))

    return u
}

pub fn get_block_data(content []string, block string) string
{
	mut data := ""
	mut start := false
	for line in content
	{
		if line.trim_space() == block {
			start = true
			continue
		} else if line.trim_space() == "{" { continue }
		else if start && line.trim_space() == "}" { break }

		if start {
			data += "${line.trim_space()}\n"
		}
	}

	return data
}

pub fn (mut u UI) parse_terminal(lines []string) 
{
    u.term      = TerminalDisplay{}

    for line in lines
    {
        key := line.split(":")
        match key[0] {
            "title" { u.term.title = u.match_line_start(key, "title") }
            "motd" { u.term.motd = u.match_line_start(key, "motd") }
            "size" { u.term.size = u.trim_many(u.match_line_start(key, "size"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}

pub fn (mut u UI) parse_graph(lines []string)
{
    u.graph     = GraphDisplay{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"   { u.graph.display       = u.match_line_start(key, "display").bool() }
            "layout_p"  { u.graph.layout_p      = u.trim_many(u.match_line_start(key, "layout_p"), ["[", "]", "[", "]"]).split(",") }
            "graph_p"   { u.graph.graph_p       = u.trim_many(u.match_line_start(key, "graph_p"), ["[", "]", "[", "]"]).split(",") }
            "data_c"    { u.graph.data_c        = u.trim_many(u.match_line_start(key, "data_c"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}

pub fn (mut u UI) parse_conntable(lines []string)
{
    u.conntable     = ConntableDisplay{}
    
    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"           { u.conntable.display           = u.match_line_start(key, "display").bool() }
            "table_p"           { u.conntable.table_p           = u.trim_many(u.match_line_start(key, "table_p"), ["[", "]", "[", "]"]).split(",") }
            "border_c"          { u.conntable.border_c          = u.trim_many(u.match_line_start(key, "border_c"), ["[", "]", "[", "]"]).split(",") }
            "text_c"            { u.conntable.text_c            = u.trim_many(u.match_line_start(key, "text_c"), ["[", "]", "[", "]"]).split(",") }
            "header_text_c"     { u.conntable.header_text_c     = u.trim_many(u.match_line_start(key, "header_text_c"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}

pub fn (mut u UI) parse_os(lines []string) 
{
    u.os        = OsDisplay{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"       { u.os.display          = u.match_line_start(key, "display").bool() }
            "labels_c"      { u.os.labels_c         = u.trim_many(u.match_line_start(key, "labels_c"), ["[", "]", "[", "]"]).split(",") }
            "value_c"       { u.os.value_c          = u.trim_many(u.match_line_start(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "os_name_p"     { u.os.os_name_p        = u.trim_many(u.match_line_start(key, "os_name_p"), ["[", "]", "[", "]"]).split(",") }
            "os_version_p"  { u.os.os_version_p     = u.trim_many(u.match_line_start(key, "os_version_p"), ["[", "]", "[", "]"]).split(",") }
            "os_kernel_p"   { u.os.os_kernel_p      = u.trim_many(u.match_line_start(key, "os_kernel_p"), ["[", "]", "[", "]"]).split(",") }
            "shell_p"       { u.os.shell_p          = u.trim_many(u.match_line_start(key, "shell_p"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}

pub fn (mut u UI) parse_hardware(lines []string)
{
    u.hw = HardwareDisplay{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"               { u.hw.display              = u.match_line_start(key, "display").bool() }
            "labels_c"              { u.hw.labels_c             = u.trim_many(u.match_line_start(key, "labels_c"), ["[", "]", "[", "]"]).split(",") }
            "value_c"               { u.hw.value_c              = u.trim_many(u.match_line_start(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "cpu_name_p"            { u.hw.cpu_name_p           = u.trim_many(u.match_line_start(key, "cpu_name_p"), ["[", "]", "[", "]"]).split(",") }
            "cpu_cores_p"           { u.hw.cpu_cores_p          = u.trim_many(u.match_line_start(key, "cpu_cores_p"), ["[", "]", "[", "]"]).split(",") }
            "cpu_usage_p"           { u.hw.cpu_usage_p          = u.trim_many(u.match_line_start(key, "cpu_usage_p"), ["[", "]", "[", "]"]).split(",") }
            "cpu_free_p"            { u.hw.cpu_free_p           = u.trim_many(u.match_line_start(key, "cpu_free_p"), ["[", "]", "[", "]"]).split(",") }
            "cpu_arch_p"            { u.hw.cpu_arch_p           = u.trim_many(u.match_line_start(key, "cpu_arch_p"), ["[", "]", "[", "]"]).split(",") }
            "memory_type_p"         { u.hw.memory_type_p        = u.trim_many(u.match_line_start(key, "memory_type_p"), ["[", "]", "[", "]"]).split(",") }
            "memory_capacity_p"     { u.hw.memory_capacity_p    = u.trim_many(u.match_line_start(key, "memory_capacity_p"), ["[", "]", "[", "]"]).split(",") }
            "memory_used_p"         { u.hw.memory_used_p        = u.trim_many(u.match_line_start(key, "memory_used_p"), ["[", "]", "[", "]"]).split(",") }
            "memory_free_p"         { u.hw.memory_free_p        = u.trim_many(u.match_line_start(key, "memory_free_p"), ["[", "]", "[", "]"]).split(",") }
            "memory_usage_p"        { u.hw.memory_usage_p       = u.trim_many(u.match_line_start(key, "memory_usage_p"), ["[", "]", "[", "]"]).split(",") }
            "hdd_name_p"            { u.hw.hdd_name_p           = u.trim_many(u.match_line_start(key, "hdd_name_p"), ["[", "]", "[", "]"]).split(",") }
            "hdd_capacity_p"        { u.hw.hdd_capacity_p       = u.trim_many(u.match_line_start(key, "hdd_capacity_p"), ["[", "]", "[", "]"]).split(",") }
            "hdd_used_p"            { u.hw.hdd_used_p           = u.trim_many(u.match_line_start(key, "hdd_used_p"), ["[", "]", "[", "]"]).split(",") }
            "hdd_free_p"            { u.hw.hdd_free_p           = u.trim_many(u.match_line_start(key, "hdd_free_p"), ["[", "]", "[", "]"]).split(",") }
            "hdd_usage_p"           { u.hw.hdd_usage_p          = u.trim_many(u.match_line_start(key, "hdd_usage_p"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}


pub fn (mut u UI) parse_connection(lines []string)
{
    u.connection = ConnectionDisplay{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"               { u.connection.display              = u.match_line_start(key, "display").bool() }
            "labels_c"              { u.connection.labels_c             = u.trim_many(u.match_line_start(key, "labels_c"), ["[", "]", "[", "]"]).split(",") }
            "value_c"               { u.connection.value_c              = u.trim_many(u.match_line_start(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "interface_p"           { u.connection.interface_p          = u.trim_many(u.match_line_start(key, "interface_p"), ["[", "]", "[", "]"]).split(",") }
            "system_ip_p"           { u.connection.system_ip_p          = u.trim_many(u.match_line_start(key, "system_ip_p"), ["[", "]", "[", "]"]).split(",") }
            "socket_ip_p"           { u.connection.socket_ip_p          = u.trim_many(u.match_line_start(key, "socket_ip_p"), ["[", "]", "[", "]"]).split(",") }
            "socket_port_p"         { u.connection.socket_port_p        = u.trim_many(u.match_line_start(key, "socket_port_p"), ["[", "]", "[", "]"]).split(",") }
            "ms_p"                  { u.connection.ms_p                 = u.trim_many(u.match_line_start(key, "ms_p"), ["[", "]", "[", "]"]).split(",") }
            "download_speed_p"      { u.connection.download_speed_p     = u.trim_many(u.match_line_start(key, "download_speed_p"), ["[", "]", "[", "]"]).split(",") }
            "upload_speed_p"        { u.connection.upload_speed_p       = u.trim_many(u.match_line_start(key, "upload_speed_p"), ["[", "]", "[", "]"]).split(",") }
            "nload_curr"            { u.connection.nload_curr           = u.trim_many(u.match_line_start(key, "nload_curr"), ["[", "]", "[", "]"]).split(",") }
            "nload_avg"             { u.connection.nload_avg            = u.trim_many(u.match_line_start(key, "nload_avg"), ["[", "]", "[", "]"]).split(",") }
            "nload_min"             { u.connection.nload_min            = u.trim_many(u.match_line_start(key, "nload_min"), ["[", "]", "[", "]"]).split(",") }
            "nload_max"             { u.connection.nload_max            = u.trim_many(u.match_line_start(key, "nload_max"), ["[", "]", "[", "]"]).split(",") }
            "nload_ttl"             { u.connection.nload_ttl            = u.trim_many(u.match_line_start(key, "nload_ttl"), ["[", "]", "[", "]"]).split(",") }
            "online_status"         { u.connection.online_status        = u.trim_many(u.match_line_start(key, "online_status"), ["[", "]", "[", "]"]).split(",") }
            "connection_count"      { u.connection.connection_count     = u.trim_many(u.match_line_start(key, "connection_count"), ["[", "]", "[", "]"]).split(",") }
            "pps_p"                 { u.connection.pps_p                = u.trim_many(u.match_line_start(key, "pps_p"), ["[", "]", "[", "]"]).split(",") }
            "pps_limit_p"           { u.connection.pps_limit_p          = u.trim_many(u.match_line_start(key, "pps_limit_p"), ["[", "]", "[", "]"]).split(",") }
            "con_limit_p"           { u.connection.con_limit_p          = u.trim_many(u.match_line_start(key, "con_limit_p"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }
}

pub fn (mut u UI) trim_many(data string, rm_elements []string) string
{
    mut new := data
    for element in rm_elements
    {
        new = new.replace(element, "")
    }

    return new
}

pub fn (mut u UI) match_line_start(data []string, starts_with string) string
{
    if data.len != 2 { return "" } 
    if data[0] == starts_with { return data[1].trim_space() }
    return ""
}