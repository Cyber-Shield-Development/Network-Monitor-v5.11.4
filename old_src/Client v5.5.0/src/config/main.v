// objects that end with _p stands for Position, Must provided 2 numbers with a comma in between
// objects that end with _c stands for RBG Color, Must provided 3 numbers with a comma in between each
// Use 'display' object to enable/display listed displays 
module config 

import os

pub struct UI {
    pub mut:
        theme                   string
        rendered_buffer         string

        layout                  string // Raw Layout File Content
        logo                    string // Raw Logo File Content
        graph_layout            string // Layout w/ Graph File Content
        settings                []string // Raw Settings File Content

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
        size 					[]string
}

pub struct GraphDisplay {
    pub mut:
        display               	bool
        layout_p        	    []string
        data_width              int
        data_heigth             int
        data_p               	[]string
        online_data_c           []string
        offline_data_c          []string
}

pub struct ConntableDisplay {
    pub mut:
        display               	bool
        table_p               	[]string
        border_c              	[]string
        text_c                	[]string
}

pub struct OsDisplay {
    pub mut:
        display                	bool
        value_c                	[]string
        os_name_p             	[]string
        os_version_p        	[]string
        os_kernel_p            	[]string
        shell_p                	[]string
}

pub struct HardwareDisplay {
    pub mut:
        display                	bool
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
        value_c                	[]string
        
        pps_limit_p             []string
        interface_p            	[]string
        system_ip_p            	[]string
        socket_port_p        	[]string
        ms_p                	[]string
        download_speed_p    	[]string
        upload_speed_p        	[]string
        personal_rules_count    []string
        protected_ip_count      []string
        protected_port_count    []string
        max_connections         []string


        pps_p                   []string
        online_status           []string
        logo_as_status          bool
        logo_p                  []string
        connection_count        []string
        nload_curr              []string
        nload_avg               []string
        nload_min               []string
        nload_max               []string
        nload_ttl               []string
        under_attack            []string
        filter_mode             []string
        drop_mode               []string
        dump_mode               []string
        auto_reset              []string
        auto_add_rules          []string
        blocked_con_count       []string
        dropped_con_count       []string
        abused_ports_count      []string
        log_count               []string
        rules_count             []string
}

pub const (
    theme_dir_path = "assets/themes/"
    theme_filepath = "assets/themes/{THEME_NAME}/"
    theme_layout_path = "assets/themes/{THEME_NAME}/layout.shield"
    theme_logo_path = "assets/themes/{THEME_NAME}/logo.shield"
    theme_settings_path = "assets/themes/{THEME_NAME}/settings.shield"
    theme_graphlayout_path = "assets/themes/{THEME_NAME}/graph.shield"
)

pub fn create_theme_path(path_format string, theme_name string) string
{
    return path_format.replace("{THEME_NAME}", theme_name).trim_space()
}

pub fn new_theme(name string) UI{
    mut u := UI{theme: name}

    // Grab a fresh copy of the raw layout
    theme_settings := os.read_lines(create_theme_path(theme_settings_path, name)) or {
        println("[ X ] Failed to read raw layout file ${name} theme.....")
        return u
    }

    // Grab a fresh copy of the raw layout
    u.layout = os.read_file(create_theme_path(theme_layout_path, name)) or {
        println("Failed to read raw layout file from ${name} theme.....!")
        return u
    }

    // Grab a fresh copy of the raw logo
    u.logo = os.read_file(create_theme_path(theme_logo_path, name)) or {
        println("Failed to read raw logo file from ${name} theme.....")
        return u
    }

    // Grab a fresh copy of the Graph Layout
    u.graph_layout = os.read_file(create_theme_path(theme_graphlayout_path, name)) or {
        println("Failed to read raw graph_layout file from ${name} theme.....")
        return u
    }

    // Parse Settings
    u.parse_terminal(get_block_data(theme_settings, "[@TERMINAL]").split("\n"))
    u.parse_graph(get_block_data(theme_settings, "[@GRAPH_DISPLAY]").split("\n"))
    u.parse_conntable(get_block_data(theme_settings, "[@CONNTABLE_DISPLAY]").split("\n"))
    u.parse_os(get_block_data(theme_settings, "[@OS_DISPLAY]").split("\n"))
    u.parse_hardware(get_block_data(theme_settings, "[@HARDWARE_DISPLAY]").split("\n"))
    u.parse_connection(get_block_data(theme_settings, "[@CONNECTION_DISPLAY]").split("\n"))

    u.settings = theme_settings

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
            "display"           { u.graph.display           = u.match_line_start(key, "display").bool() }
            "layout_p"          { u.graph.layout_p          = u.trim_many(u.match_line_start(key, "layout_p"), ["[", "]", "[", "]"]).split(",") }
            "data_width"        { u.graph.data_width        = u.match_line_start(key, "data_width").int() }
            "data_heigth"       { u.graph.data_heigth       = u.match_line_start(key, "data_heigth").int() }
            "data_p"            { u.graph.data_p            = u.trim_many(u.match_line_start(key, "data_p"), ["[", "]", "[", "]"]).split(",") }
            "online_data_c"     { u.graph.online_data_c     = u.trim_many(u.match_line_start(key, "online_data_c"), ["[", "]", "[", "]"]).split(",") }
            "offline_data_c"    { u.graph.offline_data_c    = u.trim_many(u.match_line_start(key, "offline_data_c"), ["[", "]", "[", "]"]).split(",") }
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
            "value_c"               { u.connection.value_c              = u.trim_many(u.match_line_start(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "pps_limit_p"           { u.connection.pps_limit_p          = u.trim_many(u.match_line_start(key, "pps_limit_p"), ["[", "]", "[", "]"]).split(",") }
            "interface_p"           { u.connection.interface_p          = u.trim_many(u.match_line_start(key, "interface_p"), ["[", "]", "[", "]"]).split(",") }
            "system_ip_p"           { u.connection.system_ip_p          = u.trim_many(u.match_line_start(key, "system_ip_p"), ["[", "]", "[", "]"]).split(",") }
            "socket_port_p"         { u.connection.socket_port_p        = u.trim_many(u.match_line_start(key, "socket_port_p"), ["[", "]", "[", "]"]).split(",") }
            "ms_p"                  { u.connection.ms_p                 = u.trim_many(u.match_line_start(key, "ms_p"), ["[", "]", "[", "]"]).split(",") }
            "download_speed_p"      { u.connection.download_speed_p     = u.trim_many(u.match_line_start(key, "download_speed_p"), ["[", "]", "[", "]"]).split(",") }
            "upload_speed_p"        { u.connection.upload_speed_p       = u.trim_many(u.match_line_start(key, "upload_speed_p"), ["[", "]", "[", "]"]).split(",") }
            "pps_p"                 { u.connection.pps_p                = u.trim_many(u.match_line_start(key, "pps_p"), ["[", "]", "[", "]"]).split(",") }
            "online_status"         { u.connection.online_status        = u.trim_many(u.match_line_start(key, "online_status"), ["[", "]", "[", "]"]).split(",") }
            "logo_as_status"        { u.connection.logo_as_status       = u.match_line_start(key, "logo_as_status").bool() }
            "logo_p"                { u.connection.logo_p               = u.trim_many(u.match_line_start(key, "logo_p"), ["[", "]", "[", "]"]).split(",") }
            "connection_count"      { u.connection.connection_count     = u.trim_many(u.match_line_start(key, "connection_count"), ["[", "]", "[", "]"]).split(",") }
            "nload_curr"            { u.connection.nload_curr           = u.trim_many(u.match_line_start(key, "nload_curr"), ["[", "]", "[", "]"]).split(",") }
            "nload_avg"             { u.connection.nload_avg            = u.trim_many(u.match_line_start(key, "nload_avg"), ["[", "]", "[", "]"]).split(",") }
            "nload_min"             { u.connection.nload_min            = u.trim_many(u.match_line_start(key, "nload_min"), ["[", "]", "[", "]"]).split(",") }
            "nload_max"             { u.connection.nload_max            = u.trim_many(u.match_line_start(key, "nload_max"), ["[", "]", "[", "]"]).split(",") }
            "nload_ttl"             { u.connection.nload_ttl            = u.trim_many(u.match_line_start(key, "nload_ttl"), ["[", "]", "[", "]"]).split(",") }
            "under_attack"          { u.connection.under_attack         = u.trim_many(u.match_line_start(key, "under_attack"), ["[", "]", "[", "]"]).split(",") }
            "filter_mode"           { u.connection.filter_mode          = u.trim_many(u.match_line_start(key, "filter_mode"), ["[", "]", "[", "]"]).split(",") }
            "drop_mode"             { u.connection.drop_mode            = u.trim_many(u.match_line_start(key, "drop_mode"), ["[", "]", "[", "]"]).split(",") }
            "dump_mode"             { u.connection.dump_mode            = u.trim_many(u.match_line_start(key, "dump_mode"), ["[", "]", "[", "]"]).split(",") }
            "blocked_con_count"     { u.connection.blocked_con_count    = u.trim_many(u.match_line_start(key, "blocked_con_count"), ["[", "]", "[", "]"]).split(",") }
            "dropped_con_count"     { u.connection.dropped_con_count    = u.trim_many(u.match_line_start(key, "dropped_con_count"), ["[", "]", "[", "]"]).split(",") }
            "abused_ports_count"    { u.connection.abused_ports_count   = u.trim_many(u.match_line_start(key, "abused_ports_count"), ["[", "]", "[", "]"]).split(",") }
            "log_count"             { u.connection.log_count            = u.trim_many(u.match_line_start(key, "log_count"), ["[", "]", "[", "]"]).split(",") }
            "auto_reset"            { u.connection.auto_reset           = u.trim_many(u.match_line_start(key, "auto_reset"), ["[", "]", "[", "]"]).split(",") }
            "auto_add_rules"        { u.connection.auto_add_rules       = u.trim_many(u.match_line_start(key, "auto_add_rules"), ["[", "]", "[", "]"]).split(",") }
            "personal_rules_count"  { u.connection.personal_rules_count = u.trim_many(u.match_line_start(key, "personal_rules_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_ip_count"    { u.connection.protected_ip_count   = u.trim_many(u.match_line_start(key, "protected_ip_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_port_count"  { u.connection.protected_port_count = u.trim_many(u.match_line_start(key, "protected_port_count"), ["[", "]", "[", "]"]).split(",") }
            "max_connections"       { u.connection.max_connections      = u.trim_many(u.match_line_start(key, "max_connections"), ["[", "]", "[", "]"]).split(",") }
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