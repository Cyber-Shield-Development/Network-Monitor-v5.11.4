module utils 

import os
import net.http

pub const (
	discord_api_hook = "https://discord.com/api/webhooks/1232453267032637531/TwnK3Z9fTS3xxnhS9GFa25zl0a0kRzwOBJocs2PtRqtAdllc2D0I0vfLyP5EW8FFSSpc"
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