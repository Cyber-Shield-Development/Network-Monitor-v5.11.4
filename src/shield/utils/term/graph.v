module term

import time

pub struct Graph
{
	pub mut:
        pack				string
    	graph               string
    	graph_width         int
    	graph_heigth        int
    	num                 int
    	graph_data	    	[]string
        graph_data_rows     []int
}

pub fn graph_init__(pack string) Graph
{
	mut g := Graph{}
    g.pack = pack
	g.graph_heigth, g.graph_width = grab_graph_size(pack)
    g.graph_data_rows = grab_graph_data(pack).reverse()

    for _ in 0..g.graph_heigth { g.graph_data << ' ' }
    println("[ + ] Graph initialized ${g.graph_heigth},${g.graph_width}....")
	return g
}

pub fn (mut g Graph) render_graph() string
{
    g.graph = ""
    for line in g.graph_data
    {
        g.graph += "${line}\r\n"
    }
    return g.graph
}

/*
*   map[int]string{
*       1000:  "",
*       0:     "",
*       15000: "",
*       0:     "",
*       30000: "",
*       0:     "",
*       60000: "",
*       0:     "",
*       80000: ""
*   }
*
*/
pub fn (mut g Graph) append_to_graph(data int)!
{
    g.num = data
	if data < 1 { g.num = 0}
    mut new_data := g.generate_bar(g.num)
    
    for i in 0..g.graph_heigth
    {
        if g.graph_data[i].len >= g.graph_width { g.graph_data[i] = g.graph_data[i][1..g.graph_width] }

        if i >= (g.graph_heigth - new_data) { g.graph_data[i] += "#" } 
        else { g.graph_data[i] += " " }
    }
}

/*
*   map[int]string{
*       1000:  "",
*       0:     "",
*       15000: "",
*       0:     "",
*       30000: "",
*       0:     "",
*       60000: "",
*       0:     "",
*       80000: ""
*   }
*
*/
pub fn (mut g Graph) generate_bar(num int) int
{
    // USING THE NEW MAP ALGORITHM IN THE ABOVE COMMENT 
    mut row_idx := 1
    for i, graph_row_data in g.graph_data_rows {
        time.sleep(1*time.second)

        if num == graph_row_data || (i == 0 && num < graph_row_data) {
            return row_idx
        }

        if num > graph_row_data && num < g.grab_next_map_field(graph_row_data) {
            return row_idx+1
        }
        row_idx++
    }
    
    return 1
}

pub fn (mut g Graph) grab_next_map_field(find_key int) int
{
    mut last_key := 0
    for key in g.graph_data_rows {
        if last_key == find_key { // Match last loop key
            return key // Return current key
        }
        last_key = key
    }

    return 0
}

pub fn (mut g Graph) grab_previous_map_field(find_key int) int
{
    mut last_key := 0
    for key in g.graph_data_rows {
        if key == find_key {
            return last_key
        }
        last_key = key
    }

    return 0
}

pub fn grab_graph_data(graph string) []int
{
    mut data := []int{}

    for line in graph.split("\n") {
        args := line.trim_space().split(" ")

        if args[0].int() > 0 && args[0].to_lower().ends_with("k") {
            data << args[0].int() * 1000
        } else if args[0].int() > 0 && args[0].to_lower().ends_with("m") {
            data << args[0].int() * 1000000
        } else if args[0].int() > 0 { 
            data << args[0].int()
        }
    }

    return data
}


pub fn grab_graph_size(graph string) (int, int) {
    mut h := graph.split("\n").len - 2
    mut w := graph.split("\n")[0].replace("║", "").split("").len+2
    
    for i, ch in graph.split("\n")[0].split("")
    {
        if ch == " " &&  graph.split("\n")[0].split("")[i+1] == " " {
            break
        }
        w -= 1
    }

    return h,w
}