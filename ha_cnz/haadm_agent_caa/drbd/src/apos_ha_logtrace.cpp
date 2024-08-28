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
 * @file apos_ha_logtrace.cpp
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
 * @author	Malangsha Shaik (xmalsha)
 * 
 -------------------------------------------------------------------------*/
#include "apos_ha_logtrace.h"

static int trace_fd = -1;
static int category_mask;
static char *prefix_name[] = { (char*)"EM", (char*)"AL", (char*)"CR", (char*)"ER", (char*)"WA",(char*)"NO", (char*)"IN", (char*)"DB", (char*)"TR", (char*)"T1", (char*)"T2", (char*)"T3", (char*)"T4", (char*)"T5", (char*)"T6", (char*)"T7", (char*)"T8", (char*)">>", (char*)"<<"
};

static const char *ident;
static const char *pathname;

//---------------------------------------------------------------------
static void output(const char *file, unsigned int line, int priority, int category, const char *format, va_list ap)
{
	int i, j;
	struct timeval tv;
	char preamble[512];
	char log_string[1024];

	assert(priority <= LOG_DEBUG && category < CAT_MAX);

	/* Create a nice syslog looking date string */
	gettimeofday(&tv, NULL);
	strftime(log_string, sizeof(log_string), "%b %e %k:%M:%S", localtime(&tv.tv_sec));
	i = snprintf(preamble, sizeof(preamble), "%s.%06ld %s ", log_string, tv.tv_usec, ident);

	snprintf(&preamble[i], sizeof(preamble) - i, "[%d:%s:%04u] %s %s",
		getpid(), file, line, prefix_name[priority + category], format);
	i = vsnprintf(log_string, sizeof(log_string), preamble, ap);

	/* Add line feed if not there already */
	if (log_string[i - 1] != '\n') {
		log_string[i] = '\n';
		log_string[i + 1] = '\0';
		i++;
	}

	/* If we got here without a file descriptor, trace was enabled in runtime, open the file */
	if (trace_fd == -1) {
		trace_fd = open(pathname, O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		if (trace_fd < 0) {
			syslog(LOG_ERR, "ha_trace: open failed, file=%s (%s)", pathname, strerror(errno));
			return;
		}
	}

write_retry:
	j = write(trace_fd, log_string, i);
	if (j == -1) {
		if (errno == EAGAIN)
			goto write_retry;
		else
			syslog(LOG_ERR, "ha_trace: write failed, %s", strerror(errno));
	}
}

//---------------------------------------------------------------------
void _ha_logtrace_log(const char *file, unsigned int line, int priority, const char *format, ...)
{
	va_list ap;
	va_list ap2;
	std::string str(file);
	int i;

	/* Uncondionally send to syslog */
	va_start(ap, format);
	va_copy(ap2, ap);

	char *tmp_str = NULL;

	if (asprintf(&tmp_str, "%s %s", prefix_name[priority], format) < 0) {
		vsyslog(priority, format, ap);
	}
	else {
		vsyslog(priority, tmp_str, ap);
		free(tmp_str);
	}

	/* All the messages goes in syslog, shall be also reported in log/trace file. */
	/* if (!(category_mask & (1 << CAT_LOG)))
		goto done;
	 */	

	// strip only file name from the entire file path
    i=str.find_last_of('/');
    str.assign(str, i+1, str.size());

	output(str.data(), line, priority, CAT_LOG, format, ap2);

	va_end(ap);
	va_end(ap2);
}

//---------------------------------------------------------------------
void _ha_logtrace_trace(const char *file, unsigned int line, unsigned int category, const char *format, ...)
{
	va_list ap;

	/* Filter on category */
	if (category > (unsigned int) category_mask)
		return;

	// strip only file name from the entire file path	
	std::string str(file);
	int i=str.find_last_of('/');
	str.assign(str, i+1, str.size());

	va_start(ap, format);
	output(str.data(), line, LOG_DEBUG, category, format, ap);
	va_end(ap);
}

//---------------------------------------------------------------------
int apos_ha_logtrace_init(const char *_ident, const char *_pathname, unsigned int _mask)
{
	ident = _ident;
	pathname = _pathname;
	category_mask = _mask;
	int rCode=0;

	if (_mask != 0) {

		// Create the directory structure for the log file.
		std::string fPath(_pathname);
		std::string dirPath("");
		int pos = fPath.find_last_of('/');
		if (pos != (int)fPath.npos) {
			dirPath = fPath.substr(0, pos);
		} else {
			rCode=-1;
		}
		
		if (rCode == 0) {
			int resMkdir = mkdir(dirPath.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH); // See if it's the last dir thats missing.
			if (resMkdir == -1) {
				if (errno == EEXIST) {
					//directory already exists	
					rCode=0;
				} else if (errno == ENOENT) {
					std::string dir = dirPath;
					dir.append("/");
					pos = 0;
					int lastpos = 1;
					do {
						pos = dir.find('/', lastpos); // pos of first/next dir-delimiter
						lastpos = pos+1;
						if (pos != (int)dir.npos) {
							resMkdir = mkdir(dir.substr(0, pos).c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
							if (resMkdir == -1) {
								if (errno == EEXIST) {
									continue;
								} else {
									rCode = -1;
								}
							} 
						}
					}while ((pos != (int)dir.npos) && (rCode == 0));   
				} else {
					rCode=-1;
				}
			}
		}
			
		if (rCode == 0) {
			trace_fd = open(pathname, O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
			if (trace_fd < 0) {
				syslog(LOG_ERR, "ha_trace: open failed, file=%s (%s)", pathname, strerror(errno));
				return rCode;
			}
		}

		syslog(LOG_INFO, "ha_trace: trace enabled to file %s, mask=0x%x", pathname, category_mask);
	}
	return rCode;
}
//---------------------------------------------------------------------

