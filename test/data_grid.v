import src.shield.utils.term

fn main() 
{
	mut t := term.create_grid([25, 25])
	mut grid := t.create_header(["Name", "Age"])

	for _ in 0..10 {
		grid += t.append_new_row(["John", "24"])
	}

	grid += t.create_footer()
	println(grid)
}