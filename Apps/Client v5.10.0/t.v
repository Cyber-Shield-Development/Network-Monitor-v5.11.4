import os 
import rand 

import src.shield.utils.term

fn main() {
	graph_layout := os.read_file("assets/themes/v5_10_3/special_assets/pps_graph.shield") or { return }
	tf := term.grab_graph_data(graph_layout)
	println("${tf}")

	h,w := term.grab_graph_size(graph_layout)

	
	mut graph := term.graph_init__(graph_layout, h, w)
	for i in 0..20 {
		num := rand.int_in_range(1, 80000) or { 0 }
		append_to_graph()
		println(term.clear + graph.render_graph())
	}
}