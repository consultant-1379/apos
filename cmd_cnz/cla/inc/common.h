#ifndef _COMMON_H
#define _COMMON_H

#include <syslog.h>

// Global flag variable used to enable/disable
// in a simple way the debugging logs
extern bool DEBUG_ENABLED;

// The macro to be used to send debugging logs to the system log
#define DEBUG_LOG(...) \
	if (DEBUG_ENABLED) { \
		::syslog(LOG_DEBUG, __VA_ARGS__); \
	}

// The macro to be used to send error messages to the system log
#define ERROR_LOG(...) ::syslog(LOG_ERR, __VA_ARGS__);

#endif // _COMMON_H
