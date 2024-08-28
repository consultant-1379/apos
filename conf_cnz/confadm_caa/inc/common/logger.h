//	********************************************************
//
//	COPYRIGHT Ericsson 2018
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
#ifndef HEADER_GUARD_CLASS__APG_component_logger
#define HEADER_GUARD_CLASS__apg_component_logger apg_component_logger

#include <stdarg.h>
#include <syslog.h>
#include "ACS_TRA_Logging.h"

/*
 * Logging macros
 */
#if !defined (APG_COMPONENT_LOGGER_CLASS)
#	define APG_COMPONENT_LOGGER_CLASS apg_component_logger

#	define APG_COMPONENT_LOGGER_METHOD logf
#	define APG_COMPONENT_LOGGER_ERRNO_METHOD logf_errno
#	define APG_COMPONENT_SYSLOGGER_METHOD syslogf
#	define APG_COMPONENT_SYSLOGGER_ERRNO_METHOD syslogf_errno

#	define APG_COMPONENT_LOGGER_METHOD_SOURCE logf_source
#	define APG_COMPONENT_LOGGER_ERRNO_METHOD_SOURCE logf_errno_source
#	define APG_COMPONENT_SYSLOGGER_METHOD_SOURCE syslogf_source
#	define APG_COMPONENT_SYSLOGGER_ERRNO_METHOD_SOURCE syslogf_errno_source

#	define APG_COMPONENT_DUMPER_METHOD dump
#	define APG_COMPONENT_DEFAULT_DUMP_LINE_LENGTH 16
#	define APG_COMPONENT_DEFAULT_DUMP_SIZE 128
#endif

#if !defined (APG_COMPONENT_LOG_IMPL)
#	define APG_COMPONENT_LOG_IMPL(level, ...) APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_LOGGER_METHOD(level, __VA_ARGS__)
#	define APG_COMPONENT_LOG_ERRNO_IMPL(sys_errno, level, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_LOGGER_ERRNO_METHOD(sys_errno, level, __VA_ARGS__)
#	define APG_COMPONENT_SYSLOG_IMPL(syslog_priority, level, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_SYSLOGGER_METHOD(syslog_priority, level, __VA_ARGS__)
#	define APG_COMPONENT_SYSLOG_ERRNO_IMPL(sys_errno, syslog_priority, level, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_SYSLOGGER_ERRNO_METHOD(sys_errno, syslog_priority, level, __VA_ARGS__)

#	define APG_COMPONENT_LOG_SOURCE_IMPL(level, source, line, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_LOGGER_METHOD_SOURCE(level, source, line, __VA_ARGS__)
#	define APG_COMPONENT_LOG_SOURCE_ERRNO_IMPL(sys_errno, level, source, line, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_LOGGER_ERRNO_METHOD_SOURCE(sys_errno, level, source, line, __VA_ARGS__)
#	define APG_COMPONENT_SYSLOG_SOURCE_IMPL(syslog_priority, level, source, line, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_SYSLOGGER_METHOD_SOURCE(syslog_priority, level, source, line, __VA_ARGS__)
#	define APG_COMPONENT_SYSLOG_SOURCE_ERRNO_IMPL(sys_errno, syslog_priority, level, source, line, ...) \
	APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_SYSLOGGER_ERRNO_METHOD_SOURCE(sys_errno, syslog_priority, level, source, line, __VA_ARGS__)
#endif

inline int APG_COMPONENT_LOG_NO_LOGGING () { return 0; }

#ifdef APG_COMPONENT_HAS_LOGGING
#	ifdef APG_COMPONENT_LOGGING_HAS_SOURCE_INFO
#		ifdef APG_COMPONENT_LOGGING_USE_PRETTY_FUNCTION
#			define APG_COMPONENT_LOG(level, ...) APG_COMPONENT_LOG_SOURCE_IMPL(level, __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_LOG_ERRNO(sys_errno, level, ...) APG_COMPONENT_LOG_SOURCE_ERRNO_IMPL(sys_errno, level, __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_SYSLOG(syslog_priority, level, ...) APG_COMPONENT_SYSLOG_SOURCE_IMPL(syslog_priority, level, __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_SYSLOG_ERRNO(sys_errno, syslog_priority, level, ...) APG_COMPONENT_SYSLOG_SOURCE_ERRNO_IMPL(sys_errno, syslog_priority, level, __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#		else
#			define APG_COMPONENT_LOG(level, ...) APG_COMPONENT_LOG_SOURCE_IMPL(level, __func__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_LOG_ERRNO(sys_errno, level, ...) APG_COMPONENT_LOG_SOURCE_ERRNO_IMPL(sys_errno, level, __func__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_SYSLOG(syslog_priority, level, ...) APG_COMPONENT_SYSLOG_SOURCE_IMPL(syslog_priority, level, __func__, __LINE__, __VA_ARGS__)
#			define APG_COMPONENT_SYSLOG_ERRNO(sys_errno, syslog_priority, level, ...) APG_COMPONENT_SYSLOG_SOURCE_ERRNO_IMPL(sys_errno, syslog_priority, level, __func__, __LINE__, __VA_ARGS__)
#		endif // APG_COMPONENT_LOGGING_USE_PRETTY_FUNCTION
#	else
#		define APG_COMPONENT_LOG(level, ...) APG_COMPONENT_LOG_IMPL(level, __VA_ARGS__)
#		define APG_COMPONENT_LOG_ERRNO(sys_errno, level, ...) APG_COMPONENT_LOG_ERRNO_IMPL(sys_errno, level, __VA_ARGS__)
#		define APG_COMPONENT_SYSLOG(syslog_priority, level, ...) APG_COMPONENT_SYSLOG_IMPL(syslog_priority, level, __VA_ARGS__)
#		define APG_COMPONENT_SYSLOG_ERRNO(sys_errno, syslog_priority, level, ...) APG_COMPONENT_SYSLOG_ERRNO_IMPL(sys_errno, syslog_priority, level, __VA_ARGS__)
#	endif //APG_COMPONENT_LOGGING_HAS_SOURCE_INFO
#else
#	define APG_COMPONENT_LOG(level, ...) APG_COMPONENT_LOG_NO_LOGGING()
#	define APG_COMPONENT_LOG_ERRNO(sys_errno, level, ...) APG_COMPONENT_LOG_NO_LOGGING()
#	define APG_COMPONENT_SYSLOG(syslog_priority, level, ...) APG_COMPONENT_LOG_NO_LOGGING()
#	define APG_COMPONENT_SYSLOG_ERRNO(sys_errno, syslog_priority, level, ...) APG_COMPONENT_LOG_NO_LOGGING()
#endif //APG_COMPONENT_HAS_LOGGING


#if defined (APG_COMPONENT_DEBUGGING_LOG_ENABLED)
#	define DEBUGGING_LOG_1(format) \
	WARNING("### TEST ### : %s::%s [OBJ_ID %p, LINE == %d, MS == %s, CP == %d, TID == %u]: " format, \
			g_class_name, __func__, this, __LINE__, ACS_MSD_Service::getAddress(indextoParam)->name, _cpSystemId, \
			_tid)

#	define DEBUGGING_LOG_N(format, ...) \
	WARNING("### TEST ### : %s::%s [OBJ_ID %p, LINE == %d, MS == %s, CP == %d, TID == %u]: " format, \
			g_class_name, __func__, this, __LINE__, ACS_MSD_Service::getAddress(indextoParam)->name, _cpSystemId, \
			_tid, __VA_ARGS__)
#else
#	define DEBUGGING_LOG_1(format)
#	define DEBUGGING_LOG_N(format, ...)
#endif

#if defined (APG_COMPONENT_HAS_DUMPING)
#	define APG_COMPONENT_LOG_DUMP(buffer, size, ...) APG_COMPONENT_LOGGER_CLASS::APG_COMPONENT_DUMPER_METHOD(buffer, size, __VA_ARGS__)
#else
#	define APG_COMPONENT_LOG_DUMP(buffer, size, ...) APG_COMPONENT_LOG_NO_LOGGING()
#endif

/// @cond Skip doxygen

#undef __CLASS_NAME__
#define __CLASS_NAME__ HEADER_GUARD_CLASS__apg_component_logger

class __CLASS_NAME__ {
	//===========//
	// Constants //
	//===========//
private:
	enum {
		SYSLOG_DISABLED_MASK	=	99999,
		ERRNO_DISABLED_MASK		=	-99999
	};


	//==============//
	// Constructors //
	//==============//
private:
	/** @brief apg_component_logger Default constructor
	 *
	 *	apg_component_logger Constructor detailed description
	 *
	 *	@param[in] logging_level Description
	 *	@remarks Remarks
	 */
	__CLASS_NAME__ ();

	/** @brief apg_component_logger Copy constructor
	 *
	 *	apg_component_logger Copy Constructor detailed description
	 *
	 *	@param[in] rhs Description
	 *	@remarks Remarks
	 */
	__CLASS_NAME__ (const __CLASS_NAME__ & rhs);


	//============//
	// Destructor //
	//============//
public:
	/** @brief apg_component_logger Destructor
	 *
	 *	apg_component_logger Destructor detailed description
	 *
	 *	@remarks Remarks
	 */
	inline ~__CLASS_NAME__ () {}


	//===========//
	// Functions //
	//===========//
public:
	static ACS_TRA_LogResult open (const char * appender_name);
	static void close ();

	static ACS_TRA_LogResult syslogf_errno (int sys_errno, int syslog_priority,	ACS_TRA_LogLevel level, const char * format, ...) __attribute__ ((format (printf, 4, 5)));
	static ACS_TRA_LogResult syslogf_errno (int sys_errno, int syslog_priority, const char * format, ...) __attribute__ ((format (printf, 3, 4)));
	static ACS_TRA_LogResult syslogf_errno_source (int sys_errno, int syslog_priority, ACS_TRA_LogLevel level, const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 6, 7)));
	static ACS_TRA_LogResult syslogf_errno_source (int sys_errno, int syslog_priority, const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 5, 6)));

	static ACS_TRA_LogResult syslogf (int syslog_priority, ACS_TRA_LogLevel level, const char * format, ...) __attribute__ ((format (printf, 3, 4)));
	static ACS_TRA_LogResult syslogf (int syslog_priority, const char * format, ...) __attribute__ ((format (printf, 2, 3)));
	static ACS_TRA_LogResult syslogf_source (int syslog_priority, ACS_TRA_LogLevel level,	const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 5, 6)));
	static ACS_TRA_LogResult syslogf_source (int syslog_priority, const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 4, 5)));

	static ACS_TRA_LogResult logf (ACS_TRA_LogLevel level, const char * format, ...) __attribute__ ((format (printf, 2, 3)));
	static ACS_TRA_LogResult logf (const char * format, ...) __attribute__ ((format (printf, 1, 2)));
	static ACS_TRA_LogResult logf_source (ACS_TRA_LogLevel level, const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 4, 5)));
	static ACS_TRA_LogResult logf_source (const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 3, 4)));

	static ACS_TRA_LogResult logf_errno_source (int sys_errno, ACS_TRA_LogLevel level, const char * source_func_name, int source_line, const char * format, ...) __attribute__ ((format (printf, 5, 6)));
	static ACS_TRA_LogResult logf_errno_source (int sys_errno, const char * source_func_name,	int source_line, const char * format, ...) __attribute__ ((format (printf, 4, 5)));
	static ACS_TRA_LogResult logf_errno (int sys_errno, ACS_TRA_LogLevel level, const char * format, ...) __attribute__ ((format (printf, 3, 4)));
	static ACS_TRA_LogResult logf_errno (int sys_errno, const char * format, ...) __attribute__ ((format (printf, 2, 3)));

	static inline ACS_TRA_LogResult log (const char * message) { return logf(_logging_level, message); }
	static inline ACS_TRA_LogResult log (ACS_TRA_LogLevel level, const char * message) { return logf(level, message); }
	static inline ACS_TRA_LogResult log (const char * source_func_name, int source_line, const char * message) {
		return logf_source(_logging_level, source_func_name, source_line, message);
	}
	static inline ACS_TRA_LogResult log (ACS_TRA_LogLevel level, const char * source_func_name,
			int source_line, const char * message) {
		return logf_source(level, source_func_name, source_line, message);
	}

	static inline ACS_TRA_LogResult log_errno (int sys_errno, const char * message) {
		return logf_errno(sys_errno, _logging_level, message);
	}
	static inline ACS_TRA_LogResult log_errno (int sys_errno, ACS_TRA_LogLevel level, const char * message) {
		return logf_errno(sys_errno, level, message);
	}
	static inline ACS_TRA_LogResult log_errno (int sys_errno, const char * source_func_name, int source_line,
			const char * message) {
		return logf_errno_source(sys_errno, _logging_level, source_func_name, source_line, message);
	}
	static inline ACS_TRA_LogResult log_errno (int sys_errno, ACS_TRA_LogLevel level,
			const char * source_func_name, int source_line, const char * message) {
		return logf_errno_source(sys_errno, level, source_func_name, source_line, message);
	}

	static inline ACS_TRA_LogResult syslog (int syslog_priority, const char * message) {
		return syslogf(syslog_priority, _logging_level, message);
	}
	static inline ACS_TRA_LogResult syslog (int syslog_priority, ACS_TRA_LogLevel level, const char * message) {
		return syslogf(syslog_priority, level, message);
	}
	static inline ACS_TRA_LogResult syslog (int syslog_priority, const char * source_func_name, int source_line,
			const char * message) {
		return syslogf_source(syslog_priority, _logging_level, source_func_name, source_line, message);
	}
	static inline ACS_TRA_LogResult syslog (int syslog_priority, ACS_TRA_LogLevel level,
			const char * source_func_name, int source_line, const char * message) {
		return syslogf_source(syslog_priority, level, source_func_name, source_line, message);
	}

	static inline ACS_TRA_LogResult syslog_errno (int sys_errno, int syslog_priority, const char * message) {
		return syslogf_errno(sys_errno, syslog_priority, _logging_level, message);
	}
	static inline ACS_TRA_LogResult syslog_errno (int sys_errno, int syslog_priority, ACS_TRA_LogLevel level,
			const char * message) {
		return syslogf_errno(sys_errno, syslog_priority, level, message);
	}
	static inline ACS_TRA_LogResult syslog_errno (int sys_errno, int syslog_priority,
			const char * source_func_name, int source_line, const char * message) {
		return syslogf_errno_source(sys_errno, syslog_priority, _logging_level, source_func_name, source_line, message);
	}
	static inline ACS_TRA_LogResult syslog_errno (int sys_errno, int syslog_priority, ACS_TRA_LogLevel level,
			const char * source_func_name, int source_line, const char * message) {
		return syslogf_errno_source(sys_errno, syslog_priority, level, source_func_name, source_line, message);
	}

	static inline ACS_TRA_LogLevel logging_level () { return _logging_level; }
	static inline void logging_level (ACS_TRA_LogLevel level) { _logging_level = level; }

	static void dump (uint8_t * buffer, size_t size, size_t dumping_size, size_t dumping_line_length = APG_COMPONENT_DEFAULT_DUMP_LINE_LENGTH);

private:
	static ACS_TRA_LogResult vlogf (int sys_errno, int syslog_priority, ACS_TRA_LogLevel level,
			const char * format, va_list ap);
	static ACS_TRA_LogResult vlogf_source (int sys_errno, int syslog_priority, ACS_TRA_LogLevel level,
			const char * source_func_name, int source_line, const char * format, va_list ap);


	//===========//
	// Operators //
	//===========//
private:
	__CLASS_NAME__ & operator= (const __CLASS_NAME__ & rhs);


	//========//
	// Fields //
	//========//
private:
	static ACS_TRA_LogLevel _logging_level;
};

/// @endcond

#endif // HEADER_GUARD_CLASS__apg_component_logger
