#pragma once

//////////////////////////////////////// Generic String
#define SUFBS_SQUARE_OPEN				"["
#define SUFBS_SQUARE_CLOSE			"]"
#define SUFBS_SPACE							" "
//////////////////////////////////////// Main String

#define SUFBS_INTERNAL_FMTERR		"msg:[%s], code:[%i]\n"
#define SUFBS_MAIN_MISSINGARG		"[-%c] Missing argument.\n"
#define SUFBS_MAIN_UNKNOWARG		"[%s] Unknown option.\n"
#define SUFBS_MAIN_INVALIDUID		"[%s] Invalid UID argument.\n"
#define SUFBS_MAIN_INVALIDNUM		"Invalid argument numbers.\n"
#define SUFBS_MAIN_CLOSEDB			"Error while close the database.\n"
#define SUFBS_MAIN_REMOVEDB			"Error while remove item in the database.\n"
#define SUFBS_MAIN_OPENDB				"Error while open the database.\n"
#define SUFBS_MAIN_INSERTDB			"Error while insert item in the database.\n"
#define SUFBS_MAIN_LDAPINIT			"Error while initialize LDAP access\n"
#define SUFBS_MAIN_LDAPQUERY		"Error while LDAP query\n"
#define SUFBS_MAIN_CLEARDB			"Error while clear the database\n"
#define SUFBS_MAIN_SUCCESS			"Success\n"
#define SUFBS_MAIN_STARTAPP			"Start command\n"

#define SUFBS_MAIN_USAGE				"\n" \
																"usage: insert into the database the <uid> item extracted from LDAP: nss_ufbs -i <uid>\n" \
																"usage: remove the <uid> item from the database:                     nss_ufbs -r <uid>\n" \
																"usage: clear the database file:                                     nss_ufbs -d\n" \
																"\n"

//////////////////////////////////////// Error String UFBS class
#define SERR_UFBS_SUCCESS				"Success"
#define SERR_UFBS_UNKNOW				"Unknow error"
#define SERR_UFBS_INITIALIZED		"Library already initialized"
#define SERR_UFBS_UNABLELOADLIB	"Unable to load library"
#define SERR_UFBS_METHOD				"Unable to get method address in library"
#define SERR_UFBS_UIDNOTFOUND		"NSS: UID not found in LDAP"
#define SERR_UFBS_RETRY					"NSS: Resources or a service is currently not available"
#define SERR_UFBS_UNAVAIL				"NSS: A necessary input file cannot be found"

//////////////////////////////////////// Error String Db class
#define SERR_UFDB_SUCCESS				"Success"
#define SERR_UFDB_UNKNOW				"Unknow error"
#define SERR_UFDB_CREATEDB			"Unable to create db file"
#define SERR_UFDB_OPENDB				"Unable to open db file"
#define SERR_UFDB_ALREADYOPEN		"Database already open"
#define SERR_UFDB_DBNOTOPEN			"Database not open"
#define SERR_UFDB_DBHANDLING		"Unable to seek the file"
#define SERR_UFDB_DBFORMAT			"Database format error"
#define SERR_UFDB_OPENTMP				"Unable to open temp file"
#define SERR_UFDB_WRITEFILE			"Write error on database file"
#define SERR_UFDB_READFILE			"Read error from database file"
#define SERR_UFDB_CREATETMP			"Unable to create temporary file"
#define SERR_UFDB_TMPALREADY		"Temporary database file already opened"
#define SERR_UFDB_TMPCPY				"Error while copy a database to temporary file"
#define SERR_UFDB_TRUNCWORK			"Unable to truncate WorkFile"
#define SERR_UFDB_UIDNOTFOUND		"UID not found"
#define SERR_UFDB_RENAME				"Fail to rename work database"
#define SERR_UFDB_DBPATH  			"Unable to obtain database path from config file"
#define SERR_UFDB_DBWORKPATH  	"Unable to obtain work database path"
#define SERR_UFDB_DBTMPPATH  		"Unable to obtain temporary database path"
#define SERR_UFDB_CLOSEWDB  		"Fail to close work database (abort)"
#define SERR_UFDB_LOCKED				"Database is locked from another application"
#define SERR_UFDB_LOCKDESCR			"Unable to lock the database"
