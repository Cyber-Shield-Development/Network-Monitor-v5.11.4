module utils


pub fn rm_empty_elements(arr []string) []string
{
	mut new := []string{}
	for element in arr
	{
		if element.trim_space() != "" { new << element }
	}

	return new
}