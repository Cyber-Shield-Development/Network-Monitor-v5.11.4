module config

import os
import src.shield.utils

pub struct Theme 
{
	pub mut:
		name 			        string

		layout 			        string // Main Screen | Terminal Layout
		graph_layout 	        string // Optional Graph
        bits_graph_layout       string
        bytes_graph_layout      string
		logo 			        string // Logo for flashing colors
		display_t	 	        string // layout, graph, connection data table view
		raw_settings 	        []string

		terminal  		        TerminalSettings
		graph			        GraphSettings
        bits_graph              BitsGraphSettings
        bytes_graph             BytesGraphSettings
		conntable 		        ConnTableSettings
		os 				        OsSettings
		hardware 		        HardwareSettings
		connection 		        ConnectionSettings
}

pub const (
    theme_dir_path          = "assets/themes/"
    theme_filepath          = "assets/themes/{THEME_NAME}/"
    theme_layout_path       = "assets/themes/{THEME_NAME}/layout.shield"
    theme_logo_path         = "assets/themes/{THEME_NAME}/special_assets/logo.shield"
    theme_settings_path     = "assets/themes/{THEME_NAME}/positions.shield"
    theme_graphlayout_path  = "assets/themes/{THEME_NAME}/special_assets/pps_graph.shield"
    theme_bits_graph_path   = "assets/themes/{THEME_NAME}/special_assets/bits_graph.shield"
    theme_bytes_graph_path  = "assets/themes/{THEME_NAME}/special_assets/bytes_graph.shield"
)

pub fn create_theme_path(path_format string, theme_name string) string
{
    return path_format.replace("{THEME_NAME}", theme_name).trim_space()
}

pub fn retrieve_theme(theme_name string) Theme 
{
	mut t := Theme{name: theme_name}

    t.raw_settings = os.read_lines(create_theme_path(theme_settings_path, theme_name)) or {
        println("[ X ] Failed to read raw layout file in ${theme_name} theme.....")
        return t
    }

    t.layout = os.read_file(create_theme_path(theme_layout_path, theme_name)) or {
        println("Failed to read raw layout file in ${theme_name} theme.....!")
        return t
    }

    t.logo = os.read_file(create_theme_path(theme_logo_path, theme_name)) or {
        println("Failed to read raw logo file in ${theme_name} theme.....")
        return t
    }

    t.graph_layout = os.read_file(create_theme_path(theme_graphlayout_path, theme_name)) or {
        println("Failed to read raw graph_layout file in ${theme_name} theme.....")
        return t
    }

    t.bits_graph_layout = os.read_file(create_theme_path(theme_bits_graph_path, theme_name)) or {
        println("Failed to read raw mbit/s graph layout file in ${theme_name} theme....")
        return t
    }

    t.bytes_graph_layout = os.read_file(create_theme_path(theme_bytes_graph_path, theme_name)) or {
        println("Failed to read raw mbyte/s graph layout file in ${theme_name} theme....")
        return t
    }

	t.terminal 		= parse_terminal_settings( utils.get_block_data( t.raw_settings, "[@TERMINAL]" ))
	t.graph 		= parse_graph_settings( utils.get_block_data(t.raw_settings, "[@GRAPH_DISPLAY]" ))
	t.bits_graph	= parse_bits_graph_settings( utils.get_block_data(t.raw_settings, "[@MBITS_GRAPH_DISPLAY]" ))
	t.bytes_graph	= parse_bytes_graph_settings( utils.get_block_data(t.raw_settings, "[@MBYTES_GRAPH_DISPLAY]" ))
	t.conntable 	= parse_conntable_settings( utils.get_block_data(t.raw_settings, "[@CONNTABLE_DISPLAY]" ))
	t.os 			= parse_os_settings( utils.get_block_data(t.raw_settings, "[@OS_DISPLAY]" ))
	t.hardware 		= parse_hdw_settings( utils.get_block_data(t.raw_settings, "[@HARDWARE_DISPLAY]" ))
	t.connection 	= parse_connection_settings( utils.get_block_data(t.raw_settings, "[@CONNECTION_DISPLAY]" ))

	return t
}