#ifndef _NSS_FBS_H
#define _NSS_FBS_H

#include <nss.h>
#include <pwd.h>
#include <sys/types.h>

/*
 * NSS Interface functions.
 * Note that only lookup functions for 'passwd' database are supported.
 */

#ifdef __cplusplus
extern "C" {
#endif

// Rewind to the beginning of the passwd database
enum nss_status _nss_fbs_setpwent(void);

// Close the password database after all processing has been performed
enum nss_status _nss_fbs_endpwent(void);

// Read the next entry from the passwd database, and store the result in the 'result' parameter
enum nss_status _nss_fbs_getpwent_r (struct passwd *result, char *buffer, size_t buflen, int *errnop);

// Retrieve from the passwd database the info regarding the user identified by 'name'. The result is stored in the 'result' parameter
enum nss_status _nss_fbs_getpwnam_r(const char *name,struct passwd *result, char *buffer, size_t buflen, int *errnop);

// Retrieve from the passwd database the info regarding the user identified by 'uid'. The result is stored in the 'result' parameter
enum nss_status _nss_fbs_getpwuid_r(uid_t uid,struct passwd *result, char *buffer, size_t buflen, int *errnop);

#ifdef __cplusplus
};
#endif

#endif
