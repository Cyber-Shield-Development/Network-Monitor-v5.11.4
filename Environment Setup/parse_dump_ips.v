/*
*
*
*/
import os

pub struct DumpScraper
{
	pub mut:
		ips 	[]string
		count 	int
}

fn main()
{
	mut dump_dir := os.ls('new_dumps') or {
		println("[ X ] Error, Unable to read dump directory....!\r\n\t=> 'assets/dumps'")
		exit(0)
	}

	println("[ + ] Parsing ${dumps.len} dumps to gather all IPs....")
	
	for dump in dump_dir
	{
		dump_data := os.read_file("new_dumps/${dump}") or {
			println("[ X ] Error, Unable to read dump\r\n\t=> Filepath Attempt: 'assets/dumps/${dump}'")
			continue
		}

		go d.fetch_all_ips(dump_data)
	}
}

pub fn (mut d DumpScraper) fetch_all_ips(dump_content string)
{
	mut start := false
	d.ips = []string{}
	for line in dump_content.split("\n")
	{
		if line.trim_space() == "[@BLOCKED_IPS]" {
			start = true
			continue
		} else line.trim_space() == "{" { continue }
		else if line.trim_space() == "}" { break }

		if start { ips << line.trim_space() }
	}
}