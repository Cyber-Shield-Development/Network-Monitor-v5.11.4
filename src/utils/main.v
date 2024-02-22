module utils 

pub fn remove_empty_elemets(arr []string) []string
{
	mut n := []string
	
	for element in arr 
	{ if element != "" { n << element } }

	return n
}