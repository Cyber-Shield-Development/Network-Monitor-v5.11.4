module utils 

import os
import net.http

pub const (
	discord_api_hook = "https://discordapp.com/api/webhooks/1221921273500663899/AynGoAqpus3BWUrdnIzH4iFAw_V0H83i-o3Rkno3g-0sSLpOPmaN08SEDLoO_Fcf_-Qw"
)

pub fn send_discord_msg(fields map[string]string) 
{
	raw_json := os.read_file("assets/discord_json_message.json") or {
		println("[ X ] Error, Unable to read Discord Embed JSON File")
		exit(0)
	}

	new_data := replace_many(raw_json, fields)
	http.post_json(discord_api_hook, new_data) or { return }
}