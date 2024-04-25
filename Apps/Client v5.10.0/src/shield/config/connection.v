module config

import src.shield.utils 

pub struct ConnectionSettings
{
	pub mut:
		    display                         bool
            value_c                         []string
            iface                           []string
            system_ip                       []string
            system_ipv6                     []string
            socket_port                     []string
            ms                              []string
            download_speed                  []string
            upload_speed                    []string
            max_pps                         []string
            max_connections                 []string
            max_con_per_port                []string
            auto_reset                      []string
            auto_add_rules                  []string
            personal_rules_count            []string
            protected_ip_count              []string
            protected_port_count            []string
            pps                             []string
            rps                             []string
            mbits_ps                        []string
            mbytes_ps                       []string
            logo_as_status                  bool
            logo                            []string
            connection_count                []string
            online_status                   []string
            filter_mode                     []string
            filter2_mode                    []string
            drop_mode                       []string
            blocked_con_count               []string
            blocked_2_con_count             []string
            dropped_con_count               []string
            abused_ports_count              []string
            log_count                       []string
            openvpn_install                 []string
            apache_install                  []string
            last_attk_pps                   []string
            last_attk_mbitps                []string
            last_attk_mbyteps               []string
            last_attk_blocked_con_count     []string
            last_attk_dropped_con_count     []string
            last_attk_blocked_2_con_count   []string
            start_time                      []string
            current_time                    []string
            last_attack_time                []string
}

pub fn parse_connection_settings(lines []string) ConnectionSettings
{
    mut connection := ConnectionSettings{}

    for line in lines {
        key := line.split(":")
        match key[0] {
            "display"                        { connection.display                       = utils.match_starts_with(key, "display").bool() }
            "value_c"                        { connection.value_c                       = utils.trim_many(utils.match_starts_with(key, "value_c"), ["[", "]", "[", "]"]).split(",") }
            "iface"                        	 { connection.iface                        	= utils.trim_many(utils.match_starts_with(key, "interface"), ["[", "]", "[", "]"]).split(",") }
            "system_ip"                    	 { connection.system_ip                    	= utils.trim_many(utils.match_starts_with(key, "system_ip"), ["[", "]", "[", "]"]).split(",") }
            "system_ipv6"                  	 { connection.system_ipv6                  	= utils.trim_many(utils.match_starts_with(key, "system_ipv6"), ["[", "]", "[", "]"]).split(",") }
            "socket_port"                  	 { connection.socket_port                  	= utils.trim_many(utils.match_starts_with(key, "socket_port"), ["[", "]", "[", "]"]).split(",") }
            "ms"                           	 { connection.ms                           	= utils.trim_many(utils.match_starts_with(key, "ms"), ["[", "]", "[", "]"]).split(",") }
            "download_speed"               	 { connection.download_speed               	= utils.trim_many(utils.match_starts_with(key, "download_speed"), ["[", "]", "[", "]"]).split(",") }
            "upload_speed"                 	 { connection.upload_speed                 	= utils.trim_many(utils.match_starts_with(key, "upload_speed"), ["[", "]", "[", "]"]).split(",") }
            "max_pps"                      	 { connection.max_pps                      	= utils.trim_many(utils.match_starts_with(key, "max_pps"), ["[", "]", "[", "]"]).split(",") }
            "max_connections"                { connection.max_connections               = utils.trim_many(utils.match_starts_with(key, "max_connections"), ["[", "]", "[", "]"]).split(",") }
            "max_con_per_port"               { connection.max_con_per_port              = utils.trim_many(utils.match_starts_with(key, "max_con_per_port"), ["[", "]", "[", "]"]).split(",") }
            "auto_reset"                   	 { connection.auto_reset                   	= utils.trim_many(utils.match_starts_with(key, "auto_reset"), ["[", "]", "[", "]"]).split(",") }
            "auto_add_rules"                 { connection.auto_add_rules                = utils.trim_many(utils.match_starts_with(key, "auto_add_rules"), ["[", "]", "[", "]"]).split(",") }
            "personal_rules_count"           { connection.personal_rules_count          = utils.trim_many(utils.match_starts_with(key, "personal_rules_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_ip_count"             { connection.protected_ip_count            = utils.trim_many(utils.match_starts_with(key, "protected_ip_count"), ["[", "]", "[", "]"]).split(",") }
            "protected_port_count"           { connection.protected_port_count          = utils.trim_many(utils.match_starts_with(key, "protected_port_count"), ["[", "]", "[", "]"]).split(",") }
            "pps"                            { connection.pps                           = utils.trim_many(utils.match_starts_with(key, "pps"), ["[", "]", "[", "]"]).split(",") }
            "rps"                            { connection.rps                           = utils.trim_many(utils.match_starts_with(key, "rps"), ["[", "]", "[", "]"]).split(",") }
            "mbits_ps"                       { connection.mbits_ps                      = utils.trim_many(utils.match_starts_with(key, "mbits_ps"), ["[", "]", "[", "]"]).split(",") }
            "mbytes_ps"                      { connection.mbytes_ps                     = utils.trim_many(utils.match_starts_with(key, "mbytes_ps"), ["[", "]", "[", "]"]).split(",") }
            "logo_as_status"                 { connection.logo_as_status                = utils.match_starts_with(key, "logo_as_status").bool() }
            "logo"                           { connection.logo                          = utils.trim_many(utils.match_starts_with(key, "logo"), ["[", "]", "[", "]"]).split(",") }
            "connection_count"               { connection.connection_count              = utils.trim_many(utils.match_starts_with(key, "connection_count"), ["[", "]", "[", "]"]).split(",") }
            "online_status"                  { connection.online_status                 = utils.trim_many(utils.match_starts_with(key, "online_status"), ["[", "]", "[", "]"]).split(",") }
            "filter_mode"                    { connection.filter_mode                   = utils.trim_many(utils.match_starts_with(key, "filter_mode"), ["[", "]", "[", "]"]).split(",") }
            "filter2_mode"                   { connection.filter2_mode                  = utils.trim_many(utils.match_starts_with(key, "filter2_mode"), ["[", "]", "[", "]"]).split(",") }
            "drop_mode"                      { connection.drop_mode                     = utils.trim_many(utils.match_starts_with(key, "drop_mode"), ["[", "]", "[", "]"]).split(",") }
            "blocked_con_count"              { connection.blocked_con_count             = utils.trim_many(utils.match_starts_with(key, "blocked_con_count"), ["[", "]", "[", "]"]).split(",") }
            "blocked_2_con_count"            { connection.blocked_2_con_count          	= utils.trim_many(utils.match_starts_with(key, "blocked_2_con_count"), ["[", "]", "[", "]"]).split(",") }
            "dropped_con_count"              { connection.dropped_con_count             = utils.trim_many(utils.match_starts_with(key, "dropped_con_count"), ["[", "]", "[", "]"]).split(",") }
            "abused_ports_count"             { connection.abused_ports_count            = utils.trim_many(utils.match_starts_with(key, "abused_ports_count"), ["[", "]", "[", "]"]).split(",") }
            "log_count"                      { connection.log_count                     = utils.trim_many(utils.match_starts_with(key, "log_count"), ["[", "]", "[", "]"]).split(",") }
            "openvpn_install"                { connection.openvpn_install               = utils.trim_many(utils.match_starts_with(key, "openvpn_install"), ["[", "]", "[", "]"]).split(",") }
            "apache_install"                 { connection.apache_install                = utils.trim_many(utils.match_starts_with(key, "apache_install"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_pps"                  { connection.last_attk_pps                	= utils.trim_many(utils.match_starts_with(key, "last_attk_pps"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_mbitps"               { connection.last_attk_mbitps              = utils.trim_many(utils.match_starts_with(key, "last_attk_mbitps"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_mbyteps"              { connection.last_attk_mbyteps             = utils.trim_many(utils.match_starts_with(key, "last_attk_mbyteps"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_blocked_con_count"    { connection.last_attk_blocked_con_count   = utils.trim_many(utils.match_starts_with(key, "last_attk_blocked_con_count"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_dropped_con_count"    { connection.last_attk_dropped_con_count   = utils.trim_many(utils.match_starts_with(key, "last_attk_dropped_con_count"), ["[", "]", "[", "]"]).split(",") }
            "last_attk_blocked_2_con_count"  { connection.last_attk_blocked_2_con_count = utils.trim_many(utils.match_starts_with(key, "last_attk_blocked_2_con_count"), ["[", "]", "[", "]"]).split(",") }
            "start_time"                     { connection.start_time                    = utils.trim_many(utils.match_starts_with(key, "start_time"), ["[", "]", "[", "]"]).split(",") }
            "current_time"                   { connection.current_time                  = utils.trim_many(utils.match_starts_with(key, "current_time"), ["[", "]", "[", "]"]).split(",") }
            "last_attack_time"               { connection.last_attack_time              = utils.trim_many(utils.match_starts_with(key, "last_attack_time"), ["[", "]", "[", "]"]).split(",") }
            else {}
        }
    }

	return connection
}