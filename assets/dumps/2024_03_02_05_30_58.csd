[@ATTACK_LOG]
{
	PPS: 92 | Current Setting: 5000
	Port Most Abused: [22, 22, 22, 1024, 1024, 1024, 22, 1024, 1024, 1024, 1024, 1024]
	IPs Block Count: 7
[@IPS_BLOCKED]
{
	156.244.64.158
	172.93.16.156
	206.162.134.21
	165.140.24.21
	199.4.190.18
	104.28.157.203
	156.244.64.98
}
[@IP_LOGS]
{
	[@2024/03/02-05:30:57]
{
		('tcp','0','1','192.99.70.163','22','156.244.64.158','47313','fin_wait1')
		('tcp','0','1','192.99.70.163','22','156.244.64.158','36567','fin_wait1')
		('tcp','0','1','192.99.70.163','22','156.244.64.158','52063','fin_wait1')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','42905','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','57813','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','54967','syn_recv')
		('tcp','0','42','192.99.70.163','22','156.244.64.158','51725','last_ack')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','32963','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','32827','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','51977','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','42413','syn_recv')
		('tcp','0','0','192.99.70.163','1024','156.244.64.158','43435','syn_recv')
}
