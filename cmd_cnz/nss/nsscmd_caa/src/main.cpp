#include "TUfbsHandler.h"
#include "TDbHandler.h"
#include "TStringTable.h"
#include "syslog.h"
#include "nss.h"

#include <stdio.h>
#include <unistd.h>

#define NSSUFBS_OPTSEPARATOR	'-'
#define NSSUFBS_INSERTCMD			'i'
#define NSSUFBS_REMOVECMD			'r'
#define NSSUFBS_DELETECMD			'd'
#define NSSUFBS_MISSINGARG		0x02
#define NSSUFBS_UNKNOWCMD			0x01

#define RET_UNKNOW						-1
#define RET_SUCCESS						0
#define RET_ABORT							1
#define RET_SYNTAX						2
#define ERR_NOTFOUND					3

#define NSSUFBS_UID_CHARS			"0123456789"

using namespace eriNssUfbsCmdNamespace;

void nssPrintUsage()
{
	printf(SUFBS_MAIN_USAGE);
}

int nssInsertItem(char *pArg)
{
	int iRet;
	int iUid;
	TUfbsHandler *pUfbs;
	TDbHandler *pDb;
	TsPassword pwd;
	std::string strMsg;
	errNssUfbs nUfbsErr;
	errNssDb nDbErr;
	// Initialization
	iRet = RET_ABORT;
	iUid = 0;
	pUfbs = NULL;
	pDb = NULL;
	nUfbsErr = errUfbsUnknow;
	nDbErr = errDbUnknow;
	// Create instance of ufbs
	pUfbs = new TUfbsHandler();
	// Verify if pArg is a digit
	if((pArg != NULL) && strspn(pArg, NSSUFBS_UID_CHARS) == strlen(pArg)){
		// Convert string in number
		iUid = atoi(pArg);
		// Initialize the UFBS object
		if(pUfbs->Initialize() == true){
			// Query to LDAP
			if (pUfbs->ldapGetPwUid(iUid, &pwd) == true){
				// Create DB instance
				pDb = new TDbHandler();
				// Open the database
				if (pDb->OpenDbInstance() == true){
					// Now insert the item
					if (pDb->InsertItemInDb(pwd) == true){
						// Set flag too success
						iRet = RET_SUCCESS;
						// Print inserted tuple
						pDb->printPwd(pwd);
					}else{
						// Error while insert the item in the database
						printf(SUFBS_MAIN_INSERTDB);
						pDb->GetInternalError(&nDbErr, &strMsg);
						printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
						// Log in syslog
						syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
					}
					// Now close the database
					if(pDb->CloseDbInstance() != true){
						// Set exit error
						iRet = RET_ABORT;
						// Error while close the database
						printf(SUFBS_MAIN_CLOSEDB);
						pDb->GetInternalError(&nDbErr, &strMsg);
						printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
						// Log in syslog
						syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
					}
				}else{
					// Error while open the database
					printf(SUFBS_MAIN_OPENDB);
					pDb->GetInternalError(&nDbErr, &strMsg);
					printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
					// Log in syslog
					syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
				}
				// Release object
				delete(pDb);
				// Invalidate the pointer
				pDb = NULL;
			}else{
				// Problem while query from LDAP
				printf(SUFBS_MAIN_LDAPQUERY);
				pUfbs->GetInternalError(&nUfbsErr, &strMsg);
				printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nUfbsErr);
				// Log in syslog
				syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nUfbsErr);
			}
		}else{
				// Problem while initialize LDAP
				printf(SUFBS_MAIN_LDAPINIT);
				pUfbs->GetInternalError(&nUfbsErr, &strMsg);
				printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nUfbsErr);
				// Log in syslog
				syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nUfbsErr);
		}
	}else{
		// UID is invalid.
		printf(SUFBS_MAIN_INVALIDUID, pArg);
	}
	// Release ufbs object
	delete pUfbs;
	// clear pointer
	pUfbs = NULL;
	// Exit from method
	return (iRet);
}

int nssRemoveItem(char *pArg)
{
	int iRet;
	int iUid;
	TDbHandler *pDb;
	std::string strMsg;
	errNssDb nDbErr;
	// Initialization
	iRet = RET_ABORT;
	iUid = 0;
	pDb = NULL;
	nDbErr = errDbUnknow;
	// Verify if pArg is a digit
	if((pArg != NULL) && strspn(pArg, NSSUFBS_UID_CHARS) == strlen(pArg)){
		// Convert string in number
		iUid = atoi(pArg);
		// Create DB instance
		pDb = new TDbHandler();
		// Open the database
		if (pDb->OpenDbInstance() == true){
			// Now remove it
			if (pDb->RemoveItemInDb(iUid) == true){
				// Set flag too success
				iRet = RET_SUCCESS;
			}else{
				// Get internal class error
				pDb->GetInternalError(&nDbErr, &strMsg);
				// Codify extern error code
				if(nDbErr == errDbUidNotFound){
					// Set extern code to item not fount
					iRet = ERR_NOTFOUND;
				}
				// Error while remove the item in the database
				printf(SUFBS_MAIN_REMOVEDB);
				printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
				// Log in syslog
				syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
			}
			// Now close the database
			if(pDb->CloseDbInstance() != true){
				// Set exit error
				iRet = RET_ABORT;
				// Error while close the database
				printf(SUFBS_MAIN_CLOSEDB);
				pDb->GetInternalError(&nDbErr, &strMsg);
				printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
				// Log in syslog
				syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
			}
		}else{
			// Error while open the database
			printf(SUFBS_MAIN_OPENDB);
			pDb->GetInternalError(&nDbErr, &strMsg);
			printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
			// Log in syslog
			syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
		}
		// Release object
		delete(pDb);
		// Invalidate the pointer
		pDb = NULL;
	}else{
		// UID is invalid.
		printf(SUFBS_MAIN_INVALIDUID, pArg);
	}
	// Exit from method
	return iRet;
}

int nssDeleteDb()
{
	int iRet;
	TDbHandler *pDb;
	std::string strMsg;
	errNssDb nDbErr;
	// Initialization
	iRet = RET_ABORT;
	pDb = NULL;
	nDbErr = errDbUnknow;
	// Create DB instance
	pDb = new TDbHandler();
	// Open the database
	if (pDb->OpenDbInstance() == true){
		// Now clear the database
		if (pDb->ClearDatabase() == true){
			// Set flag too success
			iRet = RET_SUCCESS;
		}else{
			// Error while insert the item in the database
			printf(SUFBS_MAIN_CLEARDB);
			pDb->GetInternalError(&nDbErr, &strMsg);
			printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
			// Log in syslog
			syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
		}
		// Now close the database
		if(pDb->CloseDbInstance() != true){
			// Set exit error
			iRet = RET_ABORT;
			// Error while close the database
			printf(SUFBS_MAIN_CLOSEDB);
			pDb->GetInternalError(&nDbErr, &strMsg);
			printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
			// Log in syslog
			syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
		}
	}else{
		// Error while open the database
		printf(SUFBS_MAIN_OPENDB);
		pDb->GetInternalError(&nDbErr, &strMsg);
		printf(SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
		// Log in syslog
		syslog(LOG_ERR, SUFBS_INTERNAL_FMTERR, strMsg.c_str(), nDbErr);
	}
	// Release object
	delete(pDb);
	// Invalidate the pointer
	pDb = NULL;
	// Exit from method
	return (iRet);
}

char ParseOption(int argc, char *argv[], char **szOpt, char **szValue)
{
	char chRet;
	// Initialization
	chRet = NSSUFBS_UNKNOWCMD;
	// Check argument
	if((szOpt != NULL) && (szValue != NULL)){
		// Initialize output argument
		*szOpt = NULL;
		*szValue = NULL;
		// Check number of argument
		if(argc > 1){
			// Set parsed argument
			*szOpt = argv[1];
			// Chekc for length of option
			if(strlen(argv[1]) == 2){
				// Check for option
				if (argv[1][0] == NSSUFBS_OPTSEPARATOR){
					// Set the return option
					chRet = argv[1][1];
					// Check for argument
					if(argc > 2){
						// Extract argument
						*szValue = argv[2];
					}
				}
			}
		}else{
			// No arguments
			chRet = NSSUFBS_MISSINGARG;
		}
	}
	// Exit from method
	return (chRet);
}

int nssExecuteCommand(int argc, char *argv[])
{
	int iRet;
	int iOpt;
	char *pszArgument;
	char *pszOpt;
	// Initialization
	iRet = RET_SYNTAX;
	iOpt = -1;
	pszArgument = NULL;
	// Get Option
	iOpt = ParseOption(argc, argv, &pszOpt, &pszArgument);
	// Switch for option
	switch(iOpt){
		// Insert (-i <uid>)
		case NSSUFBS_INSERTCMD:
			// Check for argument
			if((pszArgument != NULL) && (argc == 3)){
				// Insert <uid> item in the local database
				iRet = nssInsertItem(pszArgument);
			}else{
				// Invalid number of argument
				printf(SUFBS_MAIN_INVALIDNUM);
			}
		break;
		// Remove (-r <uid>)
		case NSSUFBS_REMOVECMD:
			// Check for argument
			if((pszArgument != NULL) && (argc == 3)){
				// Remove <uid> item from the local database
				iRet = nssRemoveItem(pszArgument);
			}else{
				// Invalid number of argument
				printf(SUFBS_MAIN_INVALIDNUM);
			}
		break;
		// Delete <-d>
		case NSSUFBS_DELETECMD:
			// Check for number of argument
			if(argc == 2){
				// Delete database
				iRet = nssDeleteDb();
			}else{
				// Invalid number of argument
				printf(SUFBS_MAIN_INVALIDNUM);
			}
		break;
		// Missing args
		case NSSUFBS_MISSINGARG:
			// Print unknow message
			printf(SUFBS_MAIN_INVALIDNUM);
			// Set ret code
			iRet = RET_SYNTAX;
		break;
		// Other error
		default:
			// Print unknow message
			printf(SUFBS_MAIN_UNKNOWARG, pszOpt);
			// Set ret code
			iRet = RET_SYNTAX;
	}
	// Exit from method
	return(iRet);
}

int main(int argc, char *argv[])
{
	int iRet;
	// Initialization
	iRet = RET_ABORT;	// Syntax error
	// No printout message for getopt
	opterr = 0;
	// Log launch
	syslog(LOG_INFO, SUFBS_MAIN_STARTAPP);
	// Parsing argument
	iRet = nssExecuteCommand(argc, argv);
	// Check for success
	if(iRet == RET_SUCCESS){
		// SUCCESS message
		printf(SUFBS_MAIN_SUCCESS);
	}else if(iRet == RET_SYNTAX){
		// Error. Print usage message
		nssPrintUsage();
	}
	// Exit from method
	return iRet;
}
