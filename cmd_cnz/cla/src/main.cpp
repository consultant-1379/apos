#include <stdio.h>
#include <string.h>
#include <getopt.h>

#include "common.h"
#include "configuration_reader.h"
#include "ldap_connector.h"

void print_usage (const char * name) {
	const char * program_name = ::basename(name);
	::fprintf(stderr, "Incorrect usage:\n%s -r <retries> -t <timeout> [-d]\n%s --retries=<retries> --timeout=<timeout> [--debug]\n\n", program_name, program_name);
}

int parse_command_line (int argc, char * argv[], int * retries, int * timeout, bool * debug) {
	const char * short_options = "dr:t:";
	struct option long_options [] = {
		{"debug", no_argument, 0, 'd'},
		{"retries", required_argument, 0, 'r'},
		{"timeout", required_argument, 0, 't'},
		{0, 0, 0, 0}
	};

	// Don't print any error message on stderr
	::opterr = 0;

	// Parse the command line arguments, setting the related flags
	int opt = -1;
	while ((opt = ::getopt_long(argc, argv, short_options, long_options, 0)) != -1) {
		switch (opt) {
		case 'd':
			*debug = true;
			break;
		case 'r':
			*retries = ::atoi(::optarg);
			break;
		case 't':
			*timeout = ::atoi(::optarg);
			break;
		case '?':
		default:
			print_usage(argv[0]);
			return 2;
		}
	}

	// Check that all the mandatory options have a value and that the value is valid
	if ((*retries <= 0) || (*timeout <= 0)) {
		print_usage(argv[0]);
		return 2;
	}
	return 0;
}

int main (int argc, char * argv[]) {
	// Parse the command line arguments
	int retries = -1, timeout = -1;
	bool debug_enabled = false;
	if (parse_command_line(argc, argv, &retries, &timeout, &debug_enabled)) {
		return 2;
	}

	// Setup the global flag for debug logs
	DEBUG_ENABLED = debug_enabled;
	DEBUG_LOG("Using the following arguments: retries == %d, timeout == %d, debug == %d.", retries, timeout, debug_enabled);

	// Load all the needed configuration data
	DEBUG_LOG("Retrieving the LDAP configuration from file system.");
	ConfigurationReader conf_reader;
	if (const int call_result = conf_reader.load_configuration()) {
		ERROR_LOG("Failure while retrieving configuration from file system, error_code == %d", call_result);
		return 1;
	}

	// Try to connect to the remote LDAP server for the provided number of times
	bool ldap_up = false;
	for (int n_try = 0; n_try < retries; ++n_try) {
		// Connect to remote LDAP server in order to understand its availability
		DEBUG_LOG("Connecting to remote LDAP server (try %d of %d).", (n_try + 1), retries);
		LdapConnector connector(timeout);
		if (const int call_result = connector.check_ldap_server_availability(conf_reader)) {
			ERROR_LOG("Failure while trying to retrieve LDAP status, error_code == %d", call_result);
			continue;
		}
		else {
			DEBUG_LOG("The remote LDAP server is UP & running!");
			ldap_up = true;
			break;
		}
	}
	return (ldap_up) ? 0 : 1;
}
