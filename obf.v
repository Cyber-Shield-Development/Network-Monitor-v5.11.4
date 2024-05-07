import os

pub struct Obf {
	pub mut:
		
}

fn main()
{
	data := os.read_file("cs.v") or {
		println("[ X ] Error, Unable to read v file!")
		exit(0)
	}

	parse_file(data)
}

fn parse_file(data string)
{
	lines := data.split("\n")

	for line in lines {
		trimmed := line.trim_space()
		line_info := split(" ")
		if trimmed.contains("fn") || trimmed.starts_with("pub fn") {
			if trimmed.starts_with("fn") {
				println("Private Function Found: ${line_info[1]}")
			} else {
				println("Public Function Found: ${line_info[2]}")
			}
		} else if trimmed.contains(":=") {
			if trimmed.starts_with("mut") {
				println("Mutable Variable Found: ${line_info[1]}")
			} else {
				println("Immutable Variable Found: ${line_info[0]}")
			}
		} else if trimmed.contains("struct") {
			if trimmed.starts_with("struct") {
				println("Private Struct Found: ${line_info[1]}")
			} else {
				println("Public Struct Found: ${line_info[2]}")
			}
		}
	}
}