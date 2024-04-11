module utils

import time 

pub fn current_time() string 
{ return "${time.now()}".replace("-", "/").replace(" ", "-") }

pub fn arr_starts_with(data []string, starts_with string) string
{
    if data.len != 2 { return "" } 
    if data[0] == starts_with { return data[0] }
    return starts_with
}

pub fn match_starts_with(data []string, starts string) string 
{
	if data.len != 2 { return "" } 
    if data[0] == starts { return data[1].trim_space() }
    return ""
}

pub fn get_block_data(content []string, block string) []string
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

	return data.split("\n")
}

pub fn trim_many(data string, rm_elements []string) string
{
    mut new := data
    for element in rm_elements
    {
        new = new.replace(element, "")
    }

    return new
}

pub fn rm_empty_elements(arr []string) []string
{
	mut new := []string{}
	for element in arr
	{
		if element != "" { new << element }
	}

	return new
}

pub fn count_char(data string, ch string) int
{
	mut c := 0
	for chr in data {
		if chr.ascii_str() == ch { c++ }
	}

	return c 
}

pub fn replace_many(data string, fields map[string]string) string
{
	mut n := data
	for key, val in fields 
	{
		n = n.replace(key, val)
	}

	return n
}

pub fn get_key_value_from_json(json_data string, key string) string
{
	data := trim_many(json_data, ['{', '}', '\'', '"']).replace("\n", "").split(",")

	for key_line in data 
	{
		key_info := key_line.split(":")
		if key_info.len != 2 { continue }
		if key_info[0] == key {
			return key_info[1].trim_space()
		}
	}

	return ""
}