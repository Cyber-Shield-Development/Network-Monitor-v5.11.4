module term

pub const (

    left_top_corner = "╔"
    right_top_corner = "╗"
    horizontal_line = "═"
    vertical_line = "║"

    cross = "╬"

    t_line = "╦"
    down_t_line = "╩"
    left_t_line = "╠"
    right_t_line = "╣"

    left_bottom_corner = "╚"
    right_bottom_corner = "╝"
)

pub struct DataGridView 
{
	columns 	[]int
}

pub fn create_grid(c []int) DataGridView
{
	return DataGridView{columns: c}
}

pub fn (mut dgv DataGridView) create_header(column_values []string) string
{
	if dgv.columns.len != column_values.len { return "" }
	mut top_line := left_top_corner
	mut last_line := left_t_line

	for col in dgv.columns {
		if dgv.columns.len != col {
			top_line += create_line(col) + t_line
			last_line += create_line(col) + cross
		}
	}

	top_line += right_top_corner
	last_line += right_t_line

	mut middle_line := vertical_line
	for i, col_v in column_values {
		middle_line += replace_text(create_empty_str(dgv.columns[i]-1), col_v) + vertical_line
	}

	return top_line.replace("╦╗", right_top_corner) + "\r\n" + middle_line + "\r\n" + last_line.replace("╬╣", right_t_line) + "\r\n"
}

pub fn (mut dgv DataGridView) append_new_row(row_columns []string) string
{
	mut row := vertical_line

	for i, col in row_columns {
		row += replace_text(create_empty_str(dgv.columns[i]-1), col) + vertical_line
	}

	return row.replace("║╣", "╣") + "\r\n"
}

pub fn (mut dgv DataGridView) create_footer() string
{
	mut last_line := left_bottom_corner
	for col_sz in dgv.columns {
		last_line += create_line(col_sz) + down_t_line
	}
	last_line += right_bottom_corner

	return last_line.replace("╩╝", right_bottom_corner) + "\r\n"
}

pub fn create_empty_str(spaces int) string {
	mut new := ""
	for _ in 0..spaces {
		new += " "
	}

	return new 
}

pub fn replace_text(empty_str string, data string) string {
	spaces_left := empty_str.len - data.len

	mut new := " ${data}"
	for _ in 0..spaces_left {
		new += " "
	}

	return new
}

pub fn create_line(line_length int) string {
	mut new := ""
	for _ in 0..line_length {
		new += "═"
	}

	return new
}