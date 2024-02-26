import x.json2 as json
import os

pub struct UI {
    pub mut:
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
        graph_layout_p        	[]string
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

pub fn parse_json() UI{
    mut ui_info := UI{}

    file := os.read_lines("test.json") or {
        println("Failed to open file.")
        ""
    }

    if file == "" { return UI{} }

    

    return ui_info
}

fn get_block_data(content []string, block string) string
{
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

pub fn (mut u UI) parse_terminal(content string) 
{
    terminal_key := [u.title, u.motd, u.size]

    match content
    {

    }
}