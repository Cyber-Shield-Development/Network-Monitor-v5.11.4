module info
// import os

// #include "@VROOT/src/info/c_files/cpu_usage.c"
// #include <sys/statvfs.h>
// #include <sys/utsname.h>
// #include <string.h>

// fn C.statvfs(const_path &char, buf &C.statvfs) int
// fn C.get_cpu_use() int
// fn C.uname(&C.utsname) int
// fn C.strdup(const &char) &char

// struct C.statvfs {
//     f_frsize    u64
//     f_blocks    u64
//     f_bfree     u64
//     f_bavail    u64
// }

// struct C.utsname {
// 	sysname     &char
// 	nodename    &char
// 	release     &char
// 	version     &char
// 	machine     &char
// }

pub struct Hardware
{
	pub mut:
		cpu_cores		int
		cpu_name		string
		cpu_usage		f64
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

pub fn retrieve_hardware() Hardware 
{
	mut h := Hardware{}
	// h.update_hdw()
	return h
}

// pub fn (mut h Hardware) update_hdw() Hardware
// {
// 	h.parse_cpu()
// 	h.parse_mem()
// 	h.cpu_arch()
// 	h.retrieve_hdd()
// 	return h
// }

// pub fn (mut h Hardware) parse_cpu() 
// {
// 	cpu_info := os.read_file("/proc/cpuinfo") or { "" }
// 	for line in cpu_info.split("\n")
// 	{
// 		if line.starts_with("cpu cores") { h.cpu_cores = line.replace("cpu cores", "").replace(":", "").trim_space().int() } 
// 		if line.starts_with("model name") { h.cpu_name = line.replace("model name", "").replace(":", "").trim_space() }
// 	}

// 	h.cpu_usage = h.cpu_usage()
// 	h.cpu_free = 100 - h.cpu_usage
// }

// pub fn (mut h Hardware) cpu_usage() int {
// 	return C.get_cpu_use()
// }

// pub fn (mut h Hardware) cpu_arch() {
// 	uts := C.utsname{}
// 	C.uname(&uts)
// 	h.cpu_arch_p = C.strdup(uts.machine)
// }

// pub fn (mut h Hardware) parse_mem()
// {
// 	mem_info := os.read_file("/proc/meminfo") or { "" }
// 	for line in mem_info.split("\n")
// 	{
// 		if line.starts_with("MemTotal:") {
// 			h.memory_capacity = line.replace("MemTotal:", "").replace("kB", "").trim_space().int() / 1000000
// 		}
// 		if line.starts_with("MemFree:") {
// 			h.memory_free = line.replace("MemFree:", "").replace("kB", "").trim_space().int() / 1000000
// 		}
// 	}
// 	h.memory_used = h.memory_capacity - h.memory_free
// }

// pub fn (mut h Hardware) retrieve_hdd()
// {
//     buf := C.statvfs{}
//     C.statvfs(c'/', &buf)
//     h.hdd_capacity = "${buf.f_frsize * buf.f_blocks}".int() / 1024
//     h.hdd_free = "${buf.f_frsize * buf.f_bfree}".int() / 1024
// 	h.hdd_used = "${h.hdd_capacity - h.hdd_free}".int() / 1024
// }