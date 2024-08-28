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
#include "../../inc/common/tracer.h"

#include <sys/syscall.h>
#include <string.h>
#include <stdio.h>


enum {
	SYSLOG_DISABLED_MASK	=	99999,
	ERRNO_DISABLED_MASK		=	-99999
};


#ifdef APG_COMPONENT_API_HAS_TRACE

#undef __CLASS_NAME__
#define __CLASS_NAME__ apg_component_tracer

int __CLASS_NAME__::vtrace (const char * file, int line, const char * function, const char * format, va_list ap) {
	if (_tra_tracer.ACS_TRA_ON()) {
		char trace_msg[APG_COMPONENT_TRACE_MESSAGE_SIZE_MAX];
		int char_wrote = 0;

		if (file || function || (line > 0)) {
			char_wrote = ::snprintf(trace_msg, APG_COMPONENT_ARRAY_SIZE(trace_msg), "(%06d) {", (pid_t) syscall (SYS_gettid));

			if (function) {
				char_wrote += ::snprintf(trace_msg + char_wrote, APG_COMPONENT_ARRAY_SIZE(trace_msg) - char_wrote, "%s, ", function);
			}
			if (file) {
				char * filename = ::strrchr(const_cast<char*>(file), '/');
				char_wrote += ::snprintf(trace_msg + char_wrote, APG_COMPONENT_ARRAY_SIZE(trace_msg) - char_wrote, "%s", filename ? (filename + 1) : "NO_FILE");
			}

			(line > 0) && (char_wrote += ::snprintf(trace_msg + char_wrote, APG_COMPONENT_ARRAY_SIZE(trace_msg) - char_wrote, "::%d", line));
			char_wrote += ::snprintf(trace_msg + char_wrote, APG_COMPONENT_ARRAY_SIZE(trace_msg) - char_wrote, "} ");
		}

		::vsnprintf(trace_msg + char_wrote, APG_COMPONENT_ARRAY_SIZE(trace_msg) - char_wrote, format, ap);
		trace_msg[APG_COMPONENT_ARRAY_SIZE(trace_msg) - 1] = 0;

		_tra_tracer.ACS_TRA_event(1, trace_msg);
	}

	return 0;
}

void __CLASS_NAME__::dump (uint8_t * buffer, size_t size, size_t dumping_size, size_t dumping_line_length) {
	size_t output_buffer_size = 2 + 8 + 2 + 3*dumping_line_length + 16;
	char output_buffer[output_buffer_size];

	for (size_t i = 0; (i < size) && (i < dumping_size); ) {
		int chars = ::snprintf(output_buffer, output_buffer_size, "  %08zX:", i);
		for (size_t col = 0; (col < dumping_line_length) && (i < size) && (i < dumping_size); ++i, ++col)
			chars += ::snprintf(output_buffer + chars, output_buffer_size - chars, " %02X", buffer[i]);
		trace(output_buffer);
	}
}


#undef __CLASS_NAME__
#define __CLASS_NAME__ apg_component_function_tracer

__CLASS_NAME__::__CLASS_NAME__ (apg_component_tracer & tracer, const char * function_name)
: _tracer(tracer), _function_name(function_name), _has_source_info(false), _file_name(0) {
	_tracer.trace("Entering function '%s'", _function_name ?: "NO_FUNCTION");
}

__CLASS_NAME__::__CLASS_NAME__ (apg_component_tracer & tracer, const char * function_name, const char * file_name, int line)
: _tracer(tracer), _function_name(function_name), _has_source_info(true), _file_name(file_name) {
	_tracer.trace_source(_file_name, line, _function_name, "Entering function '%s'", _function_name ?: "NO_FUNCTION");
}

__CLASS_NAME__::~__CLASS_NAME__ () {
	if (!_has_source_info) _tracer.trace("Leaving function '%s'", _function_name ?: "NO_FUNCTION");
	else	_tracer.trace_source(_file_name, 0, _function_name, "Leaving function '%s'", _function_name ?: "NO_FUNCTION");
}

#endif // APG_COMPONENT_API_HAS_TRACE
