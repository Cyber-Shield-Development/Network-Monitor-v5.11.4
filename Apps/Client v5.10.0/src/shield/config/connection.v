module config

import src.utils 

pub struct ConnectionSettings
{
	pub mut:
		display 				bool
		value_c					[]string
		pps_limit             	[]string
        interfacee            	[]string
        system_ip            	[]string
        socket_port        		[]string
        ms                		[]string
        download_speed    		[]string
        upload_speed        	[]string
        personal_rules_count    []string
        protected_ip_count      []string
        protected_port_count    []string
        max_connections         []string


        pps                   	[]string
        online_status           []string
        logo_as_status          bool
        logo                  	[]string
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

pub fn parse_connection_settings(lines []string) ConnectionSettings
{
    mut connection := ConnectionSettings{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"               { connection.display              	= utils.match_starts_with(key, "display").bool() }
            "value_c"               { connection.value_c              	= utils.trim_many(utils.match_starts_with(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "pps_limit"           	{ connection.pps_limit          	= utils.trim_many(utils.match_starts_with(key, "pps_limit"), ["[", "]", "[", "]"]).split(",") }
            "interface"           	{ connection.interfacee          	= utils.trim_many(utils.match_starts_with(key, "interface"), ["[", "]", "[", "]"]).split(",") }
            "system_ip"           	{ connection.system_ip          	= utils.trim_many(utils.match_starts_with(key, "system_ip"), ["[", "]", "[", "]"]).split(",") }
            "socket_port"         	{ connection.socket_port        	= utils.trim_many(utils.match_starts_with(key, "socket_port"), ["[", "]", "[", "]"]).split(",") }
            "ms"                  	{ connection.ms                 	= utils.trim_many(utils.match_starts_with(key, "ms"), ["[", "]", "[", "]"]).split(",") }
            "download_speed"      	{ connection.download_speed     	= utils.trim_many(utils.match_starts_with(key, "download_speed"), ["[", "]", "[", "]"]).split(",") }
            "upload_speed"        	{ connection.upload_speed       	= utils.trim_many(utils.match_starts_with(key, "upload_speed"), ["[", "]", "[", "]"]).split(",") }
            "pps"                 	{ connection.pps                	= utils.trim_many(utils.match_starts_with(key, "pps"), ["[", "]", "[", "]"]).split(",") }
            "online_status"         { connection.online_status        	= utils.trim_many(utils.match_starts_with(key, "online_status"), ["[", "]", "[", "]"]).split(",") }
            "logo_as_status"        { connection.logo_as_status       	= utils.match_starts_with(key, "logo_as_status").bool() }
            "logo"                	{ connection.logo               	= utils.trim_many(utils.match_starts_with(key, "logo"), ["[", "]", "[", "]"]).split(",") }
            "connection_count"      { connection.connection_count     	= utils.trim_many(utils.match_starts_with(key, "connection_count"), ["[", "]", "[", "]"]).split(",") }
            "nload_curr"            { connection.nload_curr           	= utils.trim_many(utils.match_starts_with(key, "nload_curr"), ["[", "]", "[", "]"]).split(",") }
            "nload_avg"             { connection.nload_avg            	= utils.trim_many(utils.match_starts_with(key, "nload_avg"), ["[", "]", "[", "]"]).split(",") }
            "nload_min"             { connection.nload_min            	= utils.trim_many(utils.match_starts_with(key, "nload_min"), ["[", "]", "[", "]"]).split(",") }
            "nload_max"             { connection.nload_max            	= utils.trim_many(utils.match_starts_with(key, "nload_max"), ["[", "]", "[", "]"]).split(",") }
            "nload_ttl"             { connection.nload_ttl            	= utils.trim_many(utils.match_starts_with(key, "nload_ttl"), ["[", "]", "[", "]"]).split(",") }
            "under_attack"          { connection.under_attack         	= utils.trim_many(utils.match_starts_with(key, "under_attack"), ["[", "]", "[", "]"]).split(",") }
            "filter_mode"           { connection.filter_mode          	= utils.trim_many(utils.match_starts_with(key, "filter_mode"), ["[", "]", "[", "]"]).split(",") }
            "drop_mode"             { connection.drop_mode            	= utils.trim_many(utils.match_starts_with(key, "drop_mode"), ["[", "]", "[", "]"]).split(",") }
            "dump_mode"             { connection.dump_mode            	= utils.trim_many(utils.match_starts_with(key, "dump_mode"), ["[", "]", "[", "]"]).split(",") }
            "blocked_con_count"     { connection.blocked_con_count    	= utils.trim_many(utils.match_starts_with(key, "blocked_con_count"), ["[", "]", "[", "]"]).split(",") }
            "dropped_con_count"     { connection.dropped_con_count    	= utils.trim_many(utils.match_starts_with(key, "dropped_con_count"), ["[", "]", "[", "]"]).split(",") }
            "abused_ports_count"    { connection.abused_ports_count   	= utils.trim_many(utils.match_starts_with(key, "abused_ports_count"), ["[", "]", "[", "]"]).split(",") }
            "log_count"             { connection.log_count            	= utils.trim_many(utils.match_starts_with(key, "log_count"), ["[", "]", "[", "]"]).split(",") }
            "auto_reset"            { connection.auto_reset           	= utils.trim_many(utils.match_starts_with(key, "auto_reset"), ["[", "]", "[", "]"]).split(",") }
            "auto_add_rules"        { connection.auto_add_rules       	= utils.trim_many(utils.match_starts_with(key, "auto_add_rules"), ["[", "]", "[", "]"]).split(",") }
            "personal_rules_count"  { connection.personal_rules_count 	= utils.trim_many(utils.match_starts_with(key, "personal_rules_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_ip_count"    { connection.protected_ip_count   	= utils.trim_many(utils.match_starts_with(key, "protected_ip_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_port_count"  { connection.protected_port_count 	= utils.trim_many(utils.match_starts_with(key, "protected_port_count"), ["[", "]", "[", "]"]).split(",") }
            "max_connections"       { connection.max_connections      	= utils.trim_many(utils.match_starts_with(key, "max_connections"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return connection
}