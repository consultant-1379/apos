
/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_logtrace.h
 *
 * @brief
 * 
 * This file defines APIs for logging and tracing.
 * Logging is enabled by default and level based. 
 * 
 * Tracing is disabled by default and category based. Categories are or-ed into
 * the current mask setting and and-ed with the mask during filtering. Current
 * backend for tracing is file.
 * 
 * 
 * @author Malangsha Shaik (xmalsha)
 * 
 -------------------------------------------------------------------------*/
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>
#include <syslog.h>
#include <pthread.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <limits.h>
#include <string>


#ifndef LOGTRACE_H
#define LOGTRACE_H

#include <syslog.h>

#ifdef  __cplusplus
extern "C" {
#endif

/* Categories */
	enum logtrace_categories {
		CAT_LOG = 0,
		CAT_TRACE,
		CAT_TRACE1,
		CAT_TRACE2,
		CAT_TRACE3,
		CAT_TRACE4,
		CAT_TRACE5,
		CAT_TRACE6,
		CAT_TRACE7,
		CAT_TRACE8,
		CAT_TRACE_ENTER,
		CAT_TRACE_LEAVE,
		CAT_MAX
	};

#define CATEGORY_ALL    0xffffffff

/**
 * logtrace_init - Initialize the logtrace system.
 * 
 * @param ident An identity string to be prepended to every message. Typically
 * set to the program name.
 * @param pathname The pathname parameter should contain a valid
 * path name for a file if tracing is to be enabled. The user must have write
 * access to that file. If the file already exist, it is appended. If the file
 * name is not valid, no tracing is performed.
 * @param mask The initial trace mask. Should be set set to zero by
 *             default (trace disabled)
 * 
 * @return int - 0 if OK, -1 otherwise
 */
extern int apos_ha_logtrace_init(const char *ident, const char *pathname, unsigned int mask);

/**
 * logtrace_init_daemon - Initialize the logtrace system for daemons
 * 
 * @param ident An identity string to be prepended to every message. Typically
 * set to the program name.
 * @param pathname The pathname parameter should contain a valid
 * path name for a file if tracing is to be enabled. The user must have write
 * access to that file. If the file already exist, it is appended. If the file
 * name is not valid, no tracing is performed.
 * @param tracemask The initial trace mask. Should be set set to zero by
 *             default (trace disabled)
 * @param logmask The initial log level to be set for log filtering.
 * 
 * @return int - 0 if OK, -1 otherwise
 */
extern int apos_ha_logtrace_init_daemon(const char *ident, const char *pathname, unsigned int tracemask, int logmask);

/**
 * trace_category_get - Get the current mask used for trace filtering.
 * 
 * @return int - The filtering mask value
 */
extern unsigned int apos_ha_trace_category_get(void);

/* internal functions, do not use directly */
extern void _ha_logtrace_log(const char *file, unsigned int line, int priority,
		  const char *format, ...) __attribute__ ((format(printf, 4, 5)));
extern void _ha_logtrace_trace(const char *file, unsigned int line, unsigned int category,
		    const char *format, ...) __attribute__ ((format(printf, 4, 5)));

/* LOG API. Use same levels as syslog */
#define HA_LG_EM(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_EMERG, (format), ##args)
#define HA_LG_AL(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_ALERT, (format), ##args)
#define HA_LG_CR(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_CRIT, (format), ##args)
#define HA_LG_ER(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_ERR, (format), ##args)
#define HA_LG_WA(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_WARNING, (format), ##args)
#define HA_LG_NO(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_NOTICE, (format), ##args)
#define HA_LG_IN(format, args...) _ha_logtrace_log(__FILE__, __LINE__, LOG_INFO, (format), ##args)

/* TRACE API. */
#define HA_TRACE(format, args...)   _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE, (format), ##args)
#define HA_TRACE_1(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE1, (format), ##args)
#define HA_TRACE_2(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE2, (format), ##args)
#define HA_TRACE_3(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE3, (format), ##args)
#define HA_TRACE_4(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE4, (format), ##args)
#define HA_TRACE_5(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE5, (format), ##args)
#define HA_TRACE_6(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE6, (format), ##args)
#define HA_TRACE_7(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE7, (format), ##args)
#define HA_TRACE_8(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE8, (format), ##args)
#define HA_TRACE_ENTER()                 _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE_ENTER, "%s ", __FUNCTION__)
#define HA_TRACE_ENTER2(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE_ENTER, "%s: " format, __FUNCTION__, ##args)
#define HA_TRACE_LEAVE()                 _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE_LEAVE, "%s ", __FUNCTION__)
#define HA_TRACE_LEAVE2(format, args...) _ha_logtrace_trace(__FILE__, __LINE__, CAT_TRACE_LEAVE, "%s: " format, __FUNCTION__, ##args)

#ifdef  __cplusplus
}
#endif

#endif
 
