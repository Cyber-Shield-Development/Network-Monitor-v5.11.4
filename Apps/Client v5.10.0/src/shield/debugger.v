/*
*
*	[ CYBER SHIELD DEBUGGER ]
*
*	- This custom built-in debugger is to enable certain output protection that
*	  the application does behind the scenes and enable TEST(s)
*
*	[ USE EXAMPLE ]
*
*	fn main() {
*		mut debugger := shield.start_debugging(false, true, false, "Lulz")
*		test := ""
*	
*		debugger.append_debug_test("null_variable", "t.v", "main()", "", false, false, [], false, false)
*	}
*/
module shield

import src.shield.info.net.tcpdump as td
import src.shield.info.net.netstat as ns

/* Built-in && Cyber Shield TYPES */
pub type TypeCheck = string 				| 
					 []string 				| 

					 int 					|
					 []int					|

					 map[string]string 		| 
					 map[string]int			|
					 map[string][]int		|
					 map[string][]string 	| 

					 map[int]int			|
					 map[int]string			|
					 map[int][]int			|
					 map[int][]string		|

					 td.TCPDump 			|
					 []td.TCPDump 			|

					 Dump 					|
					 []Dump					|

					 ns.NetstatCon 			|
					 []ns.NetstatCon		|
					 Obj_T					|
					 ErrLevel_T

pub enum Obj_T {
	_null 						= 0x000000
	_arr 						= 0x000001
	_str  						= 0x000002
	_arr_str 					= 0x000003
	_int 						= 0x000004
	_arr_int 					= 0x000005

	_map_string_string 			= 0x000006
	_map_string_int				= 0x000007
	_map_string_arr_int 		= 0x000008
	_map_string_arr_string		= 0x000009

	_map_int_int				= 0x000010
	_map_int_string				= 0x000011
	_map_int_arr_int 			= 0x000012
	_map_int_arr_string			= 0x000013

	_tcpdump 					= 0x000014
	_arr_tcpdump 				= 0x000015

	_netstat    				= 0x000016
	_arr_netstat				= 0x000017

	_dump 						= 0x000018
	_arr_dump					= 0x000019
}

pub enum ErrLevel_T {
	null 		= 0x300 // NO ERR == TEST PASSED
	warning 	= 0x302 // MINOR ERR == something happened that doesn't really matter!
	err_exit 	= 0x303 // EXIT ERR == means investigate the error! (APP MIGHT NOT BE DOING WHAT IT SOULD BE)
}

/* Information about a on-going test */
pub struct ShieldErr {
	pub mut:
		/*	Code Test Information */
		action 							string 				// ERROR NAME OF ACTION (Ex: '[DETECTION]')
		file_path 						string 				// FILE PATH TO ERROR
		last_exec_fn_name				string 				// LAST EXECUTED FUNCTION NAME (Ex: main())

		/* Error Info */
		exit_upon_err 					bool 				// EXIT APP UPON ERR (NULL OR CONTAINS 0 SUBSTR)
		msg								string 				// ERROR MESSAGE
		level 							ErrLevel_T 			// LEVEL OF ERROR FOR ERROR EXIT

		/* 
		*	Variable Check && Output Check Settings For Console/Terminal Output 
		*/
		obj_t 							Obj_T 				// Object type
		is_obj_arr						Obj_T 				// Arr Check
		output_data						TypeCheck 			// Provide any type listed in 'TypeCheck'

		/* Check Settings */
		check_for_null					bool 				// Exit if no data is in the buffer
		check_for_substr				bool 				// Enforce substr checking for strings
		output_substrs 					[]string			// Substring the buffer contains.

		/* Check Values */
		output_has_data_chk				bool 				// True if buffer has data
		output_has_substrs_chk 			bool				// True if buffer contain substr(s)
}

pub struct ShieldDebugger {
	pub mut:
		err_exit 				bool						// Exit upon high level error
		errs 					[]ShieldErr 				// List of Errors

		runtime_debug 			bool 						// Output Error Message On Runtime
		runtime_debug_output 	bool 						// Output Invalid Response On Runtime

		start_time  			string
		end_time 				string
		uptime 					string
}

/*
*
*	[ Struct: ShieldDebugger FUNCTIONS ]
*
*/

/*
*	[@DOC]
*	pub fn start_error_log(err_e bool, debug bool, data_output bool, time_now string) ShieldDebugger {
*
*	- Start log system.
*/
pub fn start_debugging(err_e bool, debug bool, data_output bool, time_now string) ShieldDebugger {
	return ShieldDebugger{
		err_exit: err_e,

		runtime_debug: debug,
		runtime_debug_output: data_output,
		
		start_time: time_now
	}
}

/*
*	[@DOC]
*	pub fn (mut debug ShieldDebugger) append_debug_test(fn_name string, output_data string, should_always_output_data bool) bool
*	
*	- Test & Check output
*
*   'exit_on_err' is for DEBUGGING MODE 
*	'debug.err_exit' is for PRODUCTION MODE (WHEN NEEDING TO EXIT ON ERR)
*/
pub fn (mut debug ShieldDebugger) append_debug_test(act 						string,
													filep 						string,
													fn_n 						string, 
													data 						TypeCheck,
													enforce_null_err 			bool,
													enforce_substrs 			bool, 
													output_substrs 				[]string,
													exit_on_err 				bool,
													stdout 						bool) {
	mut err := ShieldErr{
		action:				act,
		file_path:			filep,
		last_exec_fn_name: 	fn_n,
		output_data:		data,
		check_for_null:		enforce_null_err,
		check_for_substr:	enforce_substrs,
		output_substrs:		output_substrs,

		exit_upon_err: 		exit_on_err
	}

	err.is_obj_arr, err.obj_t 		= obj2type(data)
	err.output_has_data_chk 		= is_output_null(err.obj_t, "${err.output_data}")
	err.output_has_substrs_chk 		= err.contains_substr()

	/* 
	* 	ERR EXIT APP: Something went wrong checking object type 
	*	(DEVELOPER ISSUE: INVESTIGATE RUN-TIME DEBUGGER) 
	*/ 
	if err.obj_t == Obj_T._null {
		println("[ X ] Error, Something went wrong trying to get object type....!")
		exit(0)
	}

	/* 
	* 	Buffer Type Checking & Null/Substr(s) Checking
	*/
	match err.obj_t {
		._str {
			if enforce_null_err && err.output_has_data_chk { 
				err.level = ErrLevel_T.err_exit 
			} else if err.output_has_data_chk { 
				err.level = ErrLevel_T.warning 
			}

			if enforce_substrs && err.output_has_substrs_chk { 
				err.level = ErrLevel_T.err_exit 
			} else if err.output_has_substrs_chk { 
				err.level = ErrLevel_T.warning 
			}
		} else {}
	}

	/* Exit function if no errors */
	if err.level == ErrLevel_T.null { return }
	
	/* Gather error info in a nice string & output to console/terminal checks */
	err.gather_err()
	if stdout || debug.runtime_debug_output { 
		println(err.msg) 
	}

	/* Append to list of errors && Exit application if enabled with error(s) was found */
	debug.errs << err
	if (exit_on_err || debug.err_exit) && debug.errs.len > 0 { 
		debug.output_errors()
		exit(0)
	}
}

/* 
*	[@DOC]
*	pub fn (mut debug ShieldDebugger) output_errors()
*
*	- EXIT APPLICATION & OUTPUT ALL ERRORS UPON A HIGH LEVEL ERROR.
*/ 
pub fn (mut debug ShieldDebugger) output_errors() 
{ for mut err in debug.errs { println(err.msg) } }

/*
*	[@DOC]
*	pub fn (mut debugger ShieldDebugger) no_substr() TypeCheck
*
*	- Empty map[string]string{} as no substr
*/
pub fn (mut debugger ShieldDebugger) no_substr() TypeCheck { return []string{} }

/*
*			### [ Struct: ShieldErr FUNCTIONS ] ###
*/

/*
*	[@DOC]
*	pub fn (mut err ShieldErr) gather_err() string
*
*	- Gather error information into a nice looking string
*/
pub fn (mut err ShieldErr) gather_err() {
	mut err_output := "\x1b[31mERROR\x1b[39m! [${err.file_path}:${err.action}] ${err.last_exec_fn_name} crashed.....!\r\n\t=> [ERR_INFO] Error Message: ${err.msg} | Level: ${err.level} \r\n\t=> [OBJECT_INFO] ${err.obj_t} | ${err.output_data}\r\n"
	
	if err.check_for_null {
		err_output += "\t=> [CHECK_FOR_NULL]: ${err.check_for_null} | [BUFFER_HAS_DATA]: ${err.output_has_data_chk}\r\n"
	}

	if err.check_for_substr {
		err_output += "\t=> [CHECK_FOR_SUBSTR]: ${err.check_for_substr} | [BUFFER_CONTAINS_SUBSTR]: ${err.output_has_substrs_chk} | ${err.output_substrs}\r\n"
	}

	err.msg = err_output
}

/*
*	[@DOC]
*	pub fn (mut err ShieldErr) is_output_null() bool
*
*	- Check if buffer is null
*/
pub fn is_output_null(obj_typ Obj_T, output_data string) bool {
	
	match obj_typ {
		._str 					{ if "${output_data}" == "" 										{ return true } }
		._int 					{ if "${output_data}".int() == 0 || "${output_data}" != "0" 		{ return true } }
		._map_string_string 	{ if "${output_data}" == "{}"										{ return true } }
		._map_string_int 		{ if "${output_data}" == "{}"										{ return true } }
		._map_string_arr_int 	{ if "${output_data}" == "{}"										{ return true } }
		._map_string_arr_string { if "${output_data}" == "{}"										{ return true } }
		._map_int_int 			{ if "${output_data}" == "{}"										{ return true } }
		._map_int_string 		{ if "${output_data}" == "{}"										{ return true } }
		._map_int_arr_int 		{ if "${output_data}" == "{}"										{ return true } }
		._map_int_arr_string 	{ if "${output_data}" == "{}"										{ return true } }
		._tcpdump 				{ if "${output_data}" == "{}" 										{ return true } }
		._arr_tcpdump 			{ if "${output_data}" == "${[]td.TCPDump{}}" 						{ return true } }
		._netstat 				{ if "${output_data}" == "${ns.NetstatCon{}}" 						{ return true } }
		._arr_netstat 			{ if "${output_data}" == "${[]ns.NetstatCon{}}" 					{ return true } }
		._dump 					{ if "${output_data}" == "${Dump{}}" 								{ return true } }
		._arr_dump 				{ if "${output_data}" == "${[]Dump{}}" 								{ return true } } 
		else { return false }
	}

	return false
}

/*
*	[@DOC]
*	pub fn (mut err ShieldErr) contains_substr()
*
*	- Check if string has the substr(s) provided
*/
pub fn (mut err ShieldErr) contains_substr() bool {
	for element in err.output_substrs {
		if !"${err.output_data}".contains(element) { return false }
	}

	return true
}

/* 
*			### [ ENUM: Obj_T FUNCTIONS ] ###
*/

/*
*	[@DOC]
*	pub fn obj2type(obj TypeCheck) Obj_T
*	
*	- Detect the type of an object	
*/
pub fn obj2type(obj TypeCheck) (Obj_T, Obj_T) {
	if "${obj}" == "" { return Obj_T._null, Obj_T._null }
	
	is_arr := is_obj_arr("${obj}")
	match typeof(obj) {
		typeof(" ") 									{ return is_arr, Obj_T._str }
		typeof(1) 										{ return is_arr, Obj_T._int }

		// map[string]-------
		typeof({ "1":"1" }) 							{ return is_arr, Obj_T._map_string_string }
		typeof({ "1": 1 }) 								{ return is_arr, Obj_T._map_string_int }
		typeof({ "1": [1,1] }) 							{ return is_arr, Obj_T._map_string_arr_int }
		typeof({ "1": ["1", "1"] }) 					{ return is_arr, Obj_T._map_string_arr_string }

		// map[int]--------
		typeof({ 0: 0 }) 								{ return is_arr, Obj_T._map_int_int }
		typeof({ 0: "1" }) 								{ return is_arr, Obj_T._map_int_string }
		typeof({ 0: [1, 1] }) 							{ return is_arr, Obj_T._map_int_arr_int }
		typeof({ 0: ["1", "1"] }) 						{ return is_arr, Obj_T._map_int_arr_string }

		typeof(td.TCPDump{}) 							{ return is_arr, Obj_T._tcpdump }
		typeof(Dump{}) 									{ return is_arr, Obj_T._dump }
		typeof(ns.NetstatCon{}) 						{ return is_arr, Obj_T._netstat }

		else 											{ return Obj_T._null, Obj_T._null }
	}

	return Obj_T._null, Obj_T._null
}

/*
*	[@DOC]
*	pub fn is_obj_arr(chk string) Obj_T
*
*	- Check if an object is a string
*/
pub fn is_obj_arr(chk string) Obj_T {
	nchk := chk.replace("'", "")

	if nchk.starts_with("[") && nchk.ends_with("]") && nchk.contains(", ") && nchk.split(", ").len > 0 {
		return Obj_T._arr
	}

	return Obj_T._null
}