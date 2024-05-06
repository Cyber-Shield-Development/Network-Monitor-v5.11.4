module analyzer

import src.shield.info.net.tcpdump as td

pub struct Analyzer {
	pub mut:
		blocked_pkts				[]string
		whitelisted_pkts_substr		[]string
}

pub fn inspect_packets(mut con td.TCPDump)  {
	
}