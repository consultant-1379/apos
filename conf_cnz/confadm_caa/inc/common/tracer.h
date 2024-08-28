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
#ifndef HEADER_GUARD_FILE__apg_component_tracer
#define HEADER_GUARD_FILE__apg_component_tracer apg_component_tracer.h

#include <unistd.h>
#include <inttypes.h>
#include <stdarg.h>

#include "ACS_TRA_trace.h"


#ifndef APG_COMPONENT_ARRAY_SIZE
#	define APG_COMPONENT_ARRAY_SIZE(array) (sizeof(array)/sizeof(*(array)))
#endif

#ifndef APG_COMPONENT_STRINGIZER
#	define APG_COMPONENT_STRINGIZER(s) #s
#	define APG_COMPONENT_STRINGIZE(s) APG_COMPONENT_STRINGIZER(s)
#endif


#ifdef APG_COMPONENT_API_HAS_TRACE

#	ifndef APG_COMPONENT_TRACE_MESSAGE_SIZE_MAX
#		define APG_COMPONENT_TRACE_MESSAGE_SIZE_MAX 8192
#	endif

#	ifndef APG_COMPONENT_TRACE_DEFAULT_DUMP_LINE_LENGTH
#		define APG_COMPONENT_TRACE_DEFAULT_DUMP_LINE_LENGTH 16
#		define APG_COMPONENT_TRACE_DEFAULT_DUMP_SIZE 128
#	endif

#	define APG_COMPONENT_TRACE_DEFINE(tag) namespace { apg_component_tracer __apg_component_tracer_object__(APG_COMPONENT_STRINGIZE(tag)); }

#	define APG_COMPONENT_TRACE_MESSAGE_IMPL(...) __apg_component_tracer_object__.trace(__VA_ARGS__)
#	define APG_COMPONENT_TRACE_MESSAGE_SOURCE_IMPL(file, line, function, ...) __apg_component_tracer_object__.trace_source(file, line, function, __VA_ARGS__)

#	ifdef APG_COMPONENT_TRACE_USE_SOURCE_INFO
#		define APG_COMPONENT_TRACE_MESSAGE(...) APG_COMPONENT_TRACE_MESSAGE_SOURCE_IMPL(__FILE__, __LINE__,__func__, __VA_ARGS__)
#	else
#		define APG_COMPONENT_TRACE_MESSAGE(...) APG_COMPONENT_TRACE_MESSAGE_IMPL(__VA_ARGS__)
#	endif

#	define APG_COMPONENT_TRACE_DUMP(buffer, size, ...) __apg_component_tracer_object__.dump(buffer, size, __VA_ARGS__)

#	ifdef APG_COMPONENT_TRACE_HAS_FUNCTION_TRACE
#		define APG_COMPONENT_TRACE_FUNCTION_IMPL(...) apg_component_function_tracer __apg_component_enter_function__(__apg_component_tracer_object__, __VA_ARGS__)
#		define APG_COMPONENT_TRACE_FUNCTION_SOURCE_IMPL(...) apg_component_function_tracer __apg_component_enter_function__(__apg_component_tracer_object__, __VA_ARGS__)
#	else
#		define APG_COMPONENT_TRACE_FUNCTION_IMPL(...)
#		define APG_COMPONENT_TRACE_FUNCTION_SOURCE_IMPL(...)
#	endif

#	ifdef APG_COMPONENT_TRACE_USE_PRETTY_FUNCTION
#		ifdef APG_COMPONENT_TRACE_USE_SOURCE_INFO
#			define APG_COMPONENT_TRACE_FUNCTION APG_COMPONENT_TRACE_FUNCTION_SOURCE_IMPL(__PRETTY_FUNCTION__, __FILE__, __LINE__)
#		else
#			define APG_COMPONENT_TRACE_FUNCTION APG_COMPONENT_TRACE_FUNCTION_IMPL(__PRETTY_FUNCTION__)
#		endif
#	else
#		ifdef APG_COMPONENT_TRACE_USE_SOURCE_INFO
#			define APG_COMPONENT_TRACE_FUNCTION APG_COMPONENT_TRACE_FUNCTION_SOURCE_IMPL(__func__, __FILE__, __LINE__)
#		else
#			define APG_COMPONENT_TRACE_FUNCTION APG_COMPONENT_TRACE_FUNCTION_IMPL(__func__)
#		endif
#	endif


#undef __CLASS_NAME__
#define __CLASS_NAME__ apg_component_tracer

class __CLASS_NAME__ {
	//==============//
	// Constructors //
	//==============//
public:
	inline __CLASS_NAME__ (const char * tag) : _tra_tracer(tag, "C") {}

private:
	__CLASS_NAME__ (const __CLASS_NAME__ &);


	//============//
	// Destructor //
	//============//
public:
	inline ~__CLASS_NAME__ () {}


	//===========//
	// Functions //
	//===========//
public:
	inline int trace_source (const char * file, int line, const char * function, const char * format, ...) __attribute__ ((format (printf, 5, 6))) {
		va_list argp;
		::va_start(argp, format);
		int call_result = vtrace(file, line, function, format, argp);
		::va_end(argp);
		return call_result;
	}

	int trace (const char * format, ...) __attribute__ ((format (printf, 2, 3))) {
		va_list argp;
		::va_start(argp, format);
		int call_result = vtrace(0, -1, 0, format, argp);
		::va_end(argp);
		return call_result;
	}

	void dump (uint8_t * buffer, size_t size, size_t dumping_size, size_t dumping_line_length = APG_COMPONENT_TRACE_DEFAULT_DUMP_LINE_LENGTH);

private:
	int vtrace (const char * file, int line, const char * function, const char * format, va_list ap);


	//===========//
	// Operators //
	//===========//
private:
	__CLASS_NAME__ & operator= (const __CLASS_NAME__ &);


	//========//
	// Fields //
	//========//
private:
	ACS_TRA_trace _tra_tracer;
};


#undef __CLASS_NAME__
#define __CLASS_NAME__ apg_component_function_tracer

class __CLASS_NAME__ {
	//==============//
	// Constructors //
	//==============//
public:
	__CLASS_NAME__ (apg_component_tracer & tracer, const char * function_name);
	__CLASS_NAME__ (apg_component_tracer & tracer, const char * function_name, const char * file_name, int line = -1);

private:
	__CLASS_NAME__ (const __CLASS_NAME__ &);


	//============//
	// Destructor //
	//============//
public:
	~__CLASS_NAME__ ();


	//===========//
	// Operators //
	//===========//
private:
	__CLASS_NAME__ & operator= (const __CLASS_NAME__ &);


	//========//
	// Fields //
	//========//
private:
	apg_component_tracer & _tracer;
	const char * _function_name;
	bool _has_source_info;
	const char * _file_name;
};

#else // !APG_COMPONENT_API_HAS_TRACE

#	define APG_COMPONENT_TRACE_DEFINE(tag)
#	define APG_COMPONENT_TRACE_MESSAGE(...)
#	define APG_COMPONENT_TRACE_DUMP(buffer, size, ...)
#	define APG_COMPONENT_TRACE_FUNCTION

#endif // APG_COMPONENT_API_HAS_TRACE

#endif // HEADER_GUARD_FILE__apg_component_tracer
