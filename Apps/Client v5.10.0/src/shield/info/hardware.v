module info

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