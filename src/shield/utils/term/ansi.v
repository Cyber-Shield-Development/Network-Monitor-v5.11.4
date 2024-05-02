module term

pub const (
	success_sym 	= "\x1b[32m[ + ]\x1b[39m"
	failed_sym		= "\x1b[31m[ X ]\x1b[39m"

	/*
	*	Colors
	*/
	c_default 		= "\x1b[39m"
	c_black 		= "\x1b[30m"
	c_red			= "\x1b[31m"
	c_green 		= "\x1b[32m"
	c_yellow		= "\x1b[33m"
	c_blue			= "\x1b[34m"
	c_magenta		= "\x1b[35m"
	c_cyan			= "\x1b[36m"
	c_lightgray		= "\x1b[37m"
	c_darkgray		= "\x1b[90m"
	c_lightred		= "\x1b[91m"
	c_lightgreen	= "\x1b[92m"
	c_lightyellow	= "\x1b[93m"
	c_lightblue		= "\x1b[94m"
	c_lightmagenta	= "\x1b[95m"
	c_lightcyan		= "\x1b[96m"
	c_white			= "\x1b[97m"

	/*
	*	Background Colors
	*/
	bg_default		= "\x1b[49m"
	bg_black		= "\x1b[40m"
	bg_red			= "\x1b[41m"
	bg_green		= "\x1b[42m"
	bg_yellow		= "\x1b[43m"
	bg_blue			= "\x1b[44m"
	bg_magenta		= "\x1b[45m"
	bg_cyan			= "\x1b[46m"
	bg_lightgray	= "\x1b[47m"
	bg_darkgray		= "\x1b[100m"
	bg_lightred		= "\x1b[101m"
	bg_lightgreen	= "\x1b[102m"
	bg_lightyellow	= "\x1b[103m"
	bg_lightblue	= "\x1b[104m"
	bg_lightmagenta = "\x1b[105m"
	bg_lightcyan	= "\x1b[106m"
	bg_white 		= "\x1b[107m"

	colors 			= {
		"{DEFAULT}": 			c_default,
		"{BLACK}": 				c_black,
		"{RED}": 				c_red,
		"{GREEN}": 				c_green,
		"{YELLOW}": 			c_yellow,
		"{BLUE}": 				c_blue,
		"{MAGENTA}": 			c_magenta,
		"{CYAN}": 				c_cyan,
		"{LIGHTGRAY}": 			c_lightgray,
		"{DARKGRAY}": 			c_darkgray,
		"{LIGHTRED}": 			c_lightred,
		"{LIGHTGREEN}": 		c_lightgreen,
		"{LIGHTYELLOW}": 		c_lightyellow,
		"{LIGHTBLUE}": 			c_lightblue,
		"{LIGHTMAGENTA}": 		c_lightmagenta,
		"{LIGHTCYAN}": 			c_lightcyan,
		"{WHITE}": 				c_white,
		"{BG_DEFAULT}":			bg_default,
		"{BG_BLACK}":			bg_black,
		"{BG_RED}":				bg_red,
		"{BG_GREEN}":			bg_green,
		"{BG_YELLOW}":			bg_yellow,
		"{BG_BLUE}":			bg_blue,
		"{BG_MAGENTA}":			bg_magenta,
		"{BG_CYAN}":			bg_cyan,
		"{BG_LIGHTGRAY}":		bg_lightgray,
		"{BG_DARKGRAY}":		bg_darkgray,
		"{BG_LIGHTRED}":		bg_lightred,
		"{BG_LIGHTGREEN}":		bg_lightgreen,
		"{BG_LIGHTYELLOW}":		bg_lightyellow,
		"{BG_LIGHTBLUE}":		bg_lightblue,
		"{BG_LIGHTMAGENTA}":	bg_lightmagenta,
		"{BG_LIGHTCYAN}":		bg_lightcyan,
		"{BG_WHITE}":			bg_white
	}

	/* OTHER ASNI TERMINAL CONTROL */
	clear		 	= "\033[2J\033[1;1H"

)