//	********************************************************
//
//	 COPYRIGHT Ericsson 2018
//	All rights reserved.
//
//	The Copyright to the computer program(s) herein
//	is the property of Ericsson 2018.
//	The program(s) may be used and/or copied only with
//	the written permission from Ericsson 2018 or in
//	accordance with the terms and conditions stipulated in
//	the agreement/contract under which the program(s) have
//	been supplied.
//
//	********************************************************

#include "daemon.h"
#include "common/programconstants.h"
#include "common/tracer.h"
#include "common/logger.h"

#include <getopt.h>

APG_COMPONENT_TRACE_DEFINE(Main)

namespace cli
{
	const char * DEBUG_SHORT_OPTION		= "d";
	const char * DEBUG_LONG_OPTION		= "debug";
	const char * DEBUG_HELP_DESCRIPTION	= "Optional. Start as no-HA server. For debug purpose only.";

	const char * HELP_SHORT_OPTION	= "h";
	const char * HELP_LONG_OPTION	= "help";
	const char * HELP_DESCRIPTION	= "Optional. Display this help and exit.";

	const char * NAME_SHORT_OPTION		= "n";
	const char * NAME_LONG_OPTION		= "name";
	const char * NAME_HELP				= "PROCESS_NAME";
	const char * NAME_HELP_DESCRIPTION	= "Name of the deputy process that is passivated.";

	const char * LOGGER_SHORT_OPTION	= "l";
	const char * LOGGER_LONG_OPTION		= "logger";
	const char * LOGGER_HELP			= "LOGGER";
	const char * LOGGER_HELP_DESCRIPTION= "Logger name used by log4cplus.";

	const char * FILE_LCK_SHORT_OPTION	= "f";
	const char * FILE_LCK_LONG_OPTION	= "filelock";
	const char * FILE_LCK_HELP			= "LOCK";
	const char * FILE_LCK_HELP_DESCRIPTION = "Optional. Lock file for avoiding multiple instances of same daemon.";

	static int debug_mode_flag				= 0;
	static int help_flag					= 0;
	static int ha_daemon_name_flag			= 0;
	static int logger_appender_name_flag 	= 0;
	static int server_lock_file_path_flag 	= 0;

	static std::string ha_daemon_name_value			= "apos_cfgd";
	static std::string logger_appender_name_value 	= "APOS_CFGD";
	static std::string server_lock_file_path_value 	= "/var/run/ap/";

	const char* const short_options = "dn:l:f:";

	const struct option long_options [] =
	{
			{DEBUG_LONG_OPTION, no_argument, &debug_mode_flag, 1},
			{HELP_LONG_OPTION, no_argument, &help_flag, 1},
			{NAME_LONG_OPTION, required_argument, &ha_daemon_name_flag, 1},
			{LOGGER_LONG_OPTION, required_argument, &logger_appender_name_flag, 1},
			{FILE_LCK_LONG_OPTION, required_argument, &server_lock_file_path_flag, 1},
			{0, 0, 0, 0}
	};

	void print_command_usage (const char * program_name)
	{
		//-----------------------------------------
		//Prepare Usage Output
		char usage_output[1024] = {0};

		char name_option_usage[256] = {0};
		::snprintf(name_option_usage, sizeof(name_option_usage) - 1, "  -%s, --%s=%s", NAME_SHORT_OPTION, NAME_LONG_OPTION, NAME_HELP);

		char logger_option_usage[256] = {0};
		::snprintf(logger_option_usage, sizeof(logger_option_usage) - 1, "  -%s, --%s=%s", LOGGER_SHORT_OPTION, LOGGER_LONG_OPTION, LOGGER_HELP);

		char file_lck_option_usage[256] = {0};
		::snprintf(file_lck_option_usage, sizeof(file_lck_option_usage) - 1, "  -%s, --%s=%s", FILE_LCK_SHORT_OPTION, FILE_LCK_LONG_OPTION, FILE_LCK_HELP);

		char debug_option_usage[256] = {0};
		::snprintf(debug_option_usage, sizeof(debug_option_usage) - 1, "  -%s, --%s", DEBUG_SHORT_OPTION, DEBUG_LONG_OPTION);

		char help_option_usage[256] = {0};
		::snprintf(help_option_usage, sizeof(help_option_usage) - 1, "  -%s, --%s", HELP_SHORT_OPTION, HELP_LONG_OPTION);

		::snprintf(usage_output, sizeof(usage_output) - 1, "Usage: %s OPTION... \n%s\n%s\n\n%-40s%s\n%-40s%s\n%-40s%s\n%-40s%s\n%-40s%s\n", program_name,
				"Start a simple AMF Daemon with basic implementation of HA callbakcs. Must be integrated into the clc file of the process that must be passivated.",
				"Mandatory arguments to long options are mandatory for short options too:",
				name_option_usage, NAME_HELP_DESCRIPTION,
				logger_option_usage, LOGGER_HELP_DESCRIPTION,
				file_lck_option_usage, FILE_LCK_HELP_DESCRIPTION,
				debug_option_usage, DEBUG_HELP_DESCRIPTION,
				help_option_usage, HELP_DESCRIPTION);

		//-----------------------------------------
		//Prepare description of Exit Status
		char exit_status_description[256] = {0};
        ::snprintf(exit_status_description, sizeof(exit_status_description) - 1, "Exit status:\n%-5d%s\n%-5d%s\n%-5d%s\n",
				   common::PROGRAM_EXIT_OK, "if OK",
				   common::PROGRAM_EXIT_ANOTHER_SERVER_RUNNING, "if another server instance is running",
				   common::PROGRAM_EXIT_BAD_INVOCATION, "if some of the arguments is not valid");

        //-----------------------------------------
        //Prepare description of an example
        char example_usage[256] = {0};
        ::snprintf(example_usage, sizeof(example_usage) - 1, "Example:\n  %s -n <name> -l <logger> -f <lock_file>\n", program_name);

        //-------------------------------------------
        //Print Usage now...
		fprintf(stderr, "%s\n%s\n%s\n", usage_output, example_usage, exit_status_description);
	}

	// Parse command line arguments and set process data
	int parse (int _argc, char**_argv)
	{
		int result = 0; //0 ok, -1 error
		int debug_opt_count = 0;
		int name_opt_count = 0;
		int logger_opt_count = 0;
		int lock_opt_count = 0;
		int long_index = 0;
		int opt_code = 0;

		//Decode options from argv
		while ((opt_code = ::getopt_long(_argc, _argv, short_options, long_options, &long_index)) != -1)
		{
			//--------------------------------------------------------------
			// Check Long Options
			if (opt_code == 0) //A long option detected
			{
				if(::strcmp(long_options[long_index].name, DEBUG_LONG_OPTION) == 0)
				{
					//--debug option found
					if(debug_opt_count++)
					{
						//option provided more than one time
						APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 1]);
						result = -1;
						break;
					}
				}
				else if(::strcmp(long_options[long_index].name, HELP_LONG_OPTION) == 0)
				{
					//Return -1 to print the usage
					result = -1;
					break;
				}
				else if(::strcmp(long_options[long_index].name, NAME_LONG_OPTION) == 0)
				{
					//--name option found
					if(name_opt_count++)
					{
						//option provided more than one time
						APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);
						result = -1;
						break;
					}
					ha_daemon_name_value = std::string(optarg);
				}
				else if(::strcmp(long_options[long_index].name, LOGGER_LONG_OPTION) == 0)
				{
					//--logger option found
					if(logger_opt_count++)
					{
						//option provided more than one time
						APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);
						result = -1;
						break;
					}
					logger_appender_name_value = std::string(optarg);
				}
				else if(::strcmp(long_options[long_index].name, FILE_LCK_LONG_OPTION) == 0)
				{
					//--file lock option found
					if(lock_opt_count++)
					{
						//option provided more than one time
						APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);

						result = -1;
						break;
					}
					server_lock_file_path_value.append(std::string(optarg));
				}
				else
				{
					APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: Unrecognized option '%s'\n", _argv[0], _argv[::optind - 1]);

					result = -1;
					break;
				}
			}

			//--------------------------------------------------------------
			// Check Short Options
			else if (opt_code == 'd')
			{
				//-d option found
				if (debug_opt_count++)
				{
					//-d option provided more than one time
					APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 1]);

					result = -1;
					break;
				}
				debug_mode_flag = 1; //for short option this flag is not automatically set by getopt_long
			}
			else if (opt_code == 'h')
			{
				help_flag = 1;

				//Return -1 to print the usage
				result = -1;
				break;
			}
			else if (opt_code == 'n')
			{
				if (name_opt_count++)
				{
					//-n option provided more than one time
					APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);

					result = -1;
					break;
				}
				ha_daemon_name_value = std::string(optarg);
				ha_daemon_name_flag = 1; //for short option this flag is not automatically set by getopt_long
			}
			else if (opt_code == 'l')
			{
				if (logger_opt_count++)
				{
					//-l option provided more than one time
					APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);

					result = -1;
					break;
				}
				logger_appender_name_value = std::string(optarg);
				logger_appender_name_flag = 1; //for short option this flag is not automatically set by getopt_long
			}
			else if (opt_code == 'f')
			{
				if (lock_opt_count++)
				{
					//-f option provided more than one time
					APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: multiple instances of option '%s' \n", _argv[0], _argv[::optind - 2]);

					result = -1;
					break;
				}
				server_lock_file_path_value.append(std::string(optarg));
				server_lock_file_path_flag = 1; //for short option this flag is not automatically set by getopt_long
			}

			//--------------------------------------------------------------
			// Check Errors
			else if (opt_code == '?')
			{
				//The user provided an option not supported here
				APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: Unsupported option '%s'\n", _argv[0], _argv[::optind - 1]);

				result = -1;
				break;
			}
			else if (opt_code == ':')
			{
				//The user missed the option argument. Here we have no such option, but if any in the future, please
				//start the optstring argument in getopt_long call with the ':' character.
				APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: Argument missed for the option '%s'\n", _argv[0], _argv[::optind - 1]);

				result = -1;
				break;
			}
			else
			{
				//Other option found but not supported
				APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "%s: Generic error parsing command line options\n", _argv[0]);

				result = -1;
				break;
			}
		}

		if(0 == result)
		{
			//Validate: Check if all needed input parameters have been set
			if(!ha_daemon_name_flag || !logger_appender_name_flag)
			{
				result = -1;
			}
			else if(0 == server_lock_file_path_flag)
			{
				server_lock_file_path_value.append(ha_daemon_name_value);
				server_lock_file_path_value.append(std::string(".lck"));
			}
		}

		return result;
	}

}

int main (int argc, char**argv)
{
	// Parse command line
	if (cli::parse(argc, argv) < 0)
	{
		cli::print_command_usage(argv[0]);
		return common::PROGRAM_EXIT_BAD_INVOCATION;
	}

	// Start server work
	Daemon daemon(cli::ha_daemon_name_value, cli::logger_appender_name_value, cli::server_lock_file_path_value);
	const int return_code = daemon.work(cli::debug_mode_flag);

	return return_code;
}


