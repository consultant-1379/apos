#include "nss_fbs.h"
#include "nss_fbs_params.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <pthread.h>
#include <syslog.h>
#include <errno.h>

static char passwd_filepath[1024]= {0};										// path of PASSWD database
static FILE * passwd_stream = NULL;											// stream used to read PASSWD database
static pthread_mutex_t passwd_lock = PTHREAD_MUTEX_INITIALIZER;				// pthread mutex used to sync access to PASSWD database
static fpos_t passwd_position;												// current position in PASSWD database
static enum { no_op, getent_op, getby_op } last_op;							// last operation requested on PASSWD database


static char * skip_blanks(char *p)
{
	if(!p) return 0;

	char *q;
	for(q = p; *q != '\0' && *q != '\n' && isblank(*q); ++q)
		;

	return q;
}


/* Get file path of PASSWD database from configuration file of NSS FBS Service */
static int get_passwd_filepath(int force_read)
{
	if(*passwd_filepath && !force_read)
		return 0;

	int retval = 0;

	// Open configuration file in order to read PASSWD filepath (R_FILE parameter)
	FILE * f = fopen(NSS_FBS_CONFIG_FILEPATH, "r");
	if(f == NULL )
	{
		syslog(LOG_ERR, "NSS FBS Service: unable to read configuration from file '%s' - errno == [ %d ]", NSS_FBS_CONFIG_FILEPATH, errno);
		return -1;
	}

	// Scan configuration file line by line
	char linebuf[1024] = {0};
	while(fgets(linebuf, sizeof(linebuf), f))
	{
		// Got a new line. Skip leading blanks
		char *p = skip_blanks(linebuf);
		if(*p == '\n' || *p == '\0') continue;	// no match in this line

		// now search for PASSWD_FILE_PARAM_NAME
		int param_len = strlen(PASSWD_FILE_PARAM_NAME);
		if(!strncmp(p, PASSWD_FILE_PARAM_NAME, param_len))
		{
			// OK, not-blank part of the line starts with PASSWD_FILE_PARAM_NAME; skip following blanks and move on '=' character
			char *q = skip_blanks(p + param_len);
			if(*q != '=') continue;	// no match : line is not valid

			// match found ! Skip blanks following '='
			q = skip_blanks(q+1);
			if(*q == '\n' || *q == '\0') continue; // no match. Blank param value found !

			// search for end of line
			char *r = strchr(q, '\n');
			if(!r) continue;	// no match ! Line is not valid

			// trim blanks at the end of param value
			for(--r; r > q && isblank(*r); --r)
						;

			if((unsigned)(r-q+1) > sizeof(passwd_filepath) - 1)
			{	// No match ! The param value is too long for our buffer
				retval = -1;
				break;
			}

			// success ! Store passwd_filepath
			memcpy(passwd_filepath, q, r-q+1);
			passwd_filepath[r-q+1] = '\0';

			syslog(LOG_DEBUG, "NSS FBS Service: Read configuration file '%s'. R_FILE parameter = '%s'",NSS_FBS_CONFIG_FILEPATH, passwd_filepath);
		}
	}

	// check for errors
	if(ferror(f))
		retval = -1;

	fclose(f);

	return retval;
}


/* Initialize PASSWD database */
static enum nss_status init_passwd_database()
{
 	enum nss_status status = NSS_STATUS_SUCCESS;

 	if (passwd_stream == NULL)
 	{
 		// if not yet done, read the passwd file path (RW_FILE parameter) from FBS service configuration file
 		if(!*passwd_filepath)
 			get_passwd_filepath(0);

 		passwd_stream = fopen(passwd_filepath, "a+e");
 		if (passwd_stream == NULL)
 		{
			status = errno == EAGAIN ? NSS_STATUS_TRYAGAIN : NSS_STATUS_UNAVAIL;
			syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. Result = [ %d ] - Details: unable to open the passwd database '%s' - errno == [ %d ]", __func__, status, passwd_filepath, errno);
 		}
 	}
 	else
 		rewind (passwd_stream);// set file position indicator to the beginning of the file

 	return status;
}

/* Close PASSWD database */
static void close_passwd_database()
{
	if (passwd_stream != NULL)
	{
		fclose(passwd_stream);
		passwd_stream = NULL;
	}
}


/* INTERNAL : Get next entry from PASSWD database, also opening it if not yet done */
static enum nss_status getent_from_passwd(struct passwd *result, char *buffer, size_t buflen, int *errnop)
{
	enum nss_status status = NSS_STATUS_SUCCESS;

	struct passwd * pwp = NULL;
	int retval = fgetpwent_r(passwd_stream, result, buffer, buflen, & pwp);

	if(retval)
	{
		if(retval == ERANGE)
		{
			status = NSS_STATUS_TRYAGAIN;	// not enough space in buffer
			if(errnop) *errnop = ERANGE;
		}
		else
			status = NSS_STATUS_NOTFOUND;   // no more entries
	}

	return status;
}


enum nss_status _nss_fbs_setpwent(void)
{
	// this function prepares the NSS service for following operations
	enum nss_status status = NSS_STATUS_SUCCESS;

	pthread_mutex_lock (& passwd_lock);

	// open passwd file or, if yet opened, reset file position indicator to the beginning of the file
	status = init_passwd_database();

	// move on current position
	if (status == NSS_STATUS_SUCCESS && fgetpos (passwd_stream, & passwd_position) < 0)
	{
		fclose(passwd_stream);
		passwd_stream = NULL;
		status = NSS_STATUS_UNAVAIL;
	}

	last_op = getent_op;

	pthread_mutex_unlock (& passwd_lock);

//	syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. Result = [ %d ] ", __func__, status);

	return status;
}


enum nss_status _nss_fbs_endpwent(void)
{
	enum nss_status status = NSS_STATUS_SUCCESS;

	pthread_mutex_lock (& passwd_lock);

	close_passwd_database();

	pthread_mutex_unlock (& passwd_lock);

//	syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. Result = [ %d ] ", __func__, status);

	return status;
}


enum nss_status _nss_fbs_getpwent_r (struct passwd *result, char *buffer, size_t buflen, int *errnop)
{
	enum nss_status status = NSS_STATUS_SUCCESS;

	pthread_mutex_lock (& passwd_lock);

	// if PASSWD file has not been opened, try to open it now
	if (passwd_stream == NULL)
	{
		int save_errno = errno;
		status = init_passwd_database();
	    errno = save_errno;

	    if (status == NSS_STATUS_SUCCESS && fgetpos (passwd_stream, & passwd_position) < 0)
		{
	    	fclose (passwd_stream);
	    	passwd_stream = NULL;
	    	status = NSS_STATUS_UNAVAIL;
		}
	}

	if (status == NSS_STATUS_SUCCESS)
	{
	      /* If the last operation was not the getent function we need to position the stream.  */
		if (last_op != getent_op)
		{
			if (fsetpos (passwd_stream, & passwd_position) < 0)
				status = NSS_STATUS_UNAVAIL;
			else
				last_op = getent_op;
		}

		if (status == NSS_STATUS_SUCCESS)
		{
			 status = getent_from_passwd(result, buffer, buflen, errnop);

			 if (status == NSS_STATUS_SUCCESS)
				 fgetpos (passwd_stream, & passwd_position);
			 else
				 last_op = no_op;
		}
	}

	pthread_mutex_unlock (& passwd_lock);

/*
	if(status == NSS_STATUS_SUCCESS)
		syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. Result = [ %d ], DETAILS: found entry [user ID == %u], [username == %s] ", __func__, status, result->pw_uid, result->pw_name);
	else
		syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. Result = [ %d ] ", __func__, status);
*/
	return status;
}


enum nss_status _nss_fbs_getpwnam_r(const char *name,struct passwd *result, char *buffer, size_t buflen, int *errnop)
{
	enum nss_status status = NSS_STATUS_SUCCESS;

	pthread_mutex_lock (& passwd_lock);

	// let's move on beginning of the passwd file
	status = init_passwd_database();

	if (status == NSS_STATUS_SUCCESS)
	{
		last_op = getby_op;

		while ((status = getent_from_passwd(result, buffer, buflen, errnop)) == NSS_STATUS_SUCCESS)
		{
			if (name[0] != '+' && name[0] != '-' && ! strcmp (name, result->pw_name))
				break;
		}

		// close password database
		close_passwd_database();
	}

	pthread_mutex_unlock (& passwd_lock);

	//syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. 'name' parameter is '%s'. Result = [ %d ] ",  __func__, name, status);

	return status;
}


enum nss_status _nss_fbs_getpwuid_r(uid_t uid,struct passwd *result, char *buffer, size_t buflen, int *errnop)
{
	enum nss_status status = NSS_STATUS_SUCCESS;

	pthread_mutex_lock (& passwd_lock);

	// let's move on beginning of the passwd file
	status = init_passwd_database();

	if (status == NSS_STATUS_SUCCESS)
	{
		last_op = getby_op;

		while ((status = getent_from_passwd(result, buffer, buflen, errnop)) == NSS_STATUS_SUCCESS)
		{
			if (result->pw_uid == uid && result->pw_name[0] != '+' && result->pw_name[0] != '-')
				break;
		}

		// close password database
		close_passwd_database();
	}

	pthread_mutex_unlock (& passwd_lock);

	// syslog(LOG_DEBUG, "NSS FBS Service: called function '%s'. 'uid' parameter is '%u'. Result = [ %d ] ", __func__, uid, status);

	return status;

}
