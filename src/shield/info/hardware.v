module info

import os
import time

import src.shield.utils

pub struct Hardware 
{
	pub mut:
		cpu_cores		int
		cpu_name		string
		cpu_usage		f32
		cpu_free        f64
		cpu_arch        string

		memory_type		string
		memory_capacity	int
		memory_used		int
		memory_free		int

		gpu_name		string
		gpu_cores		int
		gpu_freq		int
		gpu_usage		f64

		hdd_name		string
		hdd_capacity	int
		hdd_used		int
		hdd_free		int
		hdd_usage		int
}

pub fn run_cpu_usage(mut hdw Hardware) {

    mut last_idle, mut last_total := retrieve_cpu_stat()
    for {
        time.sleep(1*time.second)
        new_idle, new_total := retrieve_cpu_stat()

        idle_delta := new_idle - last_idle
        total_delta := new_total - last_total
        
        last_idle = new_idle
        last_total = new_total
        
        usage := 100.0 * (1.0 - f32(idle_delta) / total_delta)
        hdw.cpu_usage = fix_float_percentage(usage)
    }
}

pub fn fix_float_percentage(f f32) f32 {
	data := "${f}".split(".")
	if data.len != 2 { return "0.0".f32() }
	if data[1].len < 2 { return "0.0".f32() }
	return "${data[0]}.${data[1].substr(0, 2)}".trim_space().f32()
}

pub fn retrieve_cpu_stat() (int, int) {
    fields := get_cpu_content()
    mut total := 0
    for field in fields {
        total += field
    }

    return fields[3], total
}

pub fn get_cpu_content() []int {
    proc_stats := os.read_file("/proc/stat") or {
        println("[ X ] Error, Unable to read /proc/stat...!")
        exit(0)
    }

    lines := proc_stats.split("\n")
    fields := utils.rm_empty_elements(lines[0].trim_space().split(" ")[1..])

    mut content := []int{}
    for field in fields { content << field.int() }
    return content
}