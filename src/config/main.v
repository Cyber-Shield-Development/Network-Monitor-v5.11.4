module config 

import x.json2 as json
import os

pub struct UI {
    pub mut:
        theme                   string
        layout                  string

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
        nload_stats_p        	[]string
        pps_p                	[]string
}

pub fn new_theme(name string) UI{
    mut u := UI{}

    theme_settings := os.read_lines("assets/themes/${name}/design.shield") or {
        println("[ X ] Failed to design file ${name}.....")
        return u
    }

    u.layout = os.read_file("assets/themes/${name}/layout.shield") or {
        println("Failed to layout file ${name}.....")
        return u
    }

    u.parse_terminal(get_block_data(theme_settings, "[@TERMINAL]").split("\n"))
    u.parse_graph(get_block_data(theme_settings, "[@GRAPH_DISPLAY]").split("\n"))
    u.parse_conntable(get_block_data(theme_settings, "[@CONNTABLE_DISPLAY]").split("\n"))
    u.parse_os(get_block_data(theme_settings, "[@OS_DISPLAY]").split("\n"))
    u.parse_hardware(get_block_data(theme_settings, "[@HARDWARE_DISPLAY]").split("\n"))
    u.parse_connection(get_block_data(theme_settings, "[@CONNECTION_DISPLAY]").split("\n"))

    return u
}

fn get_block_data(content []string, block string) string
{
	mut data := ""
	mut start := false

    for line in content
    {
        if line.trim_space() == "" {
            //parse here
            continue
        } else if line.trim_space() == "{" { continue }
        else if start && line.trim_space() == "}" { break }

        if start {
            data += "${line.trim_space()}"
        }
    }

    return data
}

pub fn (mut u UI) parse_terminal(lines []string) 
{
    u.term      = TerminalDisplay{}
    mut c       := 0

    for line in lines
    {
        key := line.split("\n")
        u.term.title = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"])
        
        u.term.motd = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"])
        
        u.term.size = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        
        c++
    }
}

pub fn (mut u UI) parse_graph(lines []string)
{
    u.graph     = GraphDisplay{}
    mut c       := 0

    for line in lines {
        key := line.split("\n")
        u.graph.display = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).bool()

        u.graph.layout_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.graph.graph_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.graph.data_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        c++
    }
}

pub fn (mut u UI) parse_conntable(lines []string)
{
    u.conntable     = ConntableDisplay{}
    mut c           := 0
    
    for line in lines {
        key := line.split("\n")
        u.conntable.display = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).bool()
            
        u.conntable.table_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.conntable.border_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        
        u.conntable.text_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.conntable.header_text_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        c++
    }
}

pub fn (mut u UI) parse_os(lines []string) 
{
    u.os        = OsDisplay{}
    mut c       := 0

    for line in lines {
        key := line.split("\n")
        u.os.display = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).bool()

        u.os.labels_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.os.value_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        
        u.os.os_name_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.os.os_version_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.os.os_kernel_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.os.shell_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        c++
    }
}

pub fn (mut u UI) parse_hardware(lines []string)
{
    u.hw = HardwareDisplay{}
    mut c := 0

    for line in lines {
        key := line.split("\n")
        u.hw.display = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).bool()

        u.hw.labels_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.value_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        
        u.hw.cpu_name_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.cpu_cores_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.cpu_usage_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.cpu_free_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.cpu_arch_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.memory_type_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.memory_capacity_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.memory_used_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.cpu_free_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.memory_free_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.memory_usage_p= u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.hdd_name_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.hdd_capacity_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.hdd_used_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.hdd_free_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.hw.hdd_usage_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        c++
    }
}


pub fn (mut u UI) parse_connection(lines []string)
{
    u.connection = ConnectionDisplay{}
    mut c := 0

    for line in lines {
        key := line.split("\n")
        u.connection.display = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).bool()

        u.connection.labels_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.value_c = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.interface_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.system_ip_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.socket_ip_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.socket_port_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.ms_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.download_speed_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.upload_speed_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.nload_stats_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")

        u.connection.pps_p = u.trim_many(
            u.match_line_start(lines[c], key[0].trim_space()),
            ["['", "[\"", "']", "\"]"]).split("', '")
        c++
    }
}

pub fn (mut u UI) trim_many(data string, rm_elements []string) string
{
    mut new := data
    for element in rm_elements
    {
        new = new.replace(element, "")
    }

    return data
}

pub fn (mut u UI) match_line_start(data string, starts_with string) string
{
    if data.trim_space().starts_with(starts_with) { return data.trim_space().replace("${starts_with}:", "").trim_space() }
    return ""
}