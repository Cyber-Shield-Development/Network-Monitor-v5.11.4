import os
import time

import src
import src.config 

fn main() 
{
	mut shield := src.monitor("eth0", 0, 0, false)
	shield.set_theme("builtin")
	time.sleep(10*time.second)
}