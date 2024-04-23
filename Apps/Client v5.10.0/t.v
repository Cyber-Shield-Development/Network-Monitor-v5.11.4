import os 
import rand 

import src.shield

fn main() {
	mut debugger := shield.start_debugging(false, true, false, "Lulz")
	test := ""

	debugger.append_debug_test("null_variable", "t.v", "main()", "", false, false, [], false, false)
}