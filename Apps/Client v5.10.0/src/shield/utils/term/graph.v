module term

pub struct Graph
{
	pub mut:
        pack				string
    	graph               string
    	graph_width         int
    	graph_heigth        int
    	num                 int
    	graph_data	    	[]string
}

pub fn graph_init__(pack string, h int, w int) Graph
{
	mut g := Graph{}
    g.pack = pack
	g.graph_heigth = h 
    g.graph_width = w

    for _ in 0..h { g.graph_data << ' ' }
    println("Graph initialized ${h},${w}....")
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

pub fn (mut g Graph) generate_bar(num int) int
{
    mut bar := 0
    if g.num == 1000 { bar = 1 }
	else if g.num > 1000 && g.num < 5000 { bar = 2 }
    else if g.num == 5000 { bar = 3 }
	else if g.num > 5000 && g.num < 10000 { bar = 4 }
    else if g.num == 10000 { bar = 5 }
	else if g.num > 10000 && g.num < 20000 { bar = 6 }
    else if g.num == 20000 { bar = 7 }
	else if g.num > 20000 && g.num < 30000 { bar = 8 }
    else if g.num == 30000 { bar = 9 }
    else if g.num > 30000 && g.num < 40000 { bar = 10 }
    else if g.num == 40000 { bar = 11 }
    else if g.num > 40000 && g.num < 50000 { bar = 12 }
    else if g.num == 50000 { bar = 13 }
    else if g.num > 50000 && g.num < 60000 { bar = 14 }
    else if g.num == 60000 { bar = 15 }
	else if g.num > 60000 && g.num < 70000 { bar = 16 }
	else if g.num == 70000 { bar = 17 }
	else if g.num > 70000 && g.num < 80000 { bar = 18 }
	else if g.num == 80000 { bar = 19 }
	else if g.num > 80000 && g.num < 90000 { bar = 20 }
	else if g.num == 90000 { bar = 21 }
    return bar
}