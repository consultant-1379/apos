#include <dlfcn.h>
#include <sstream>
//#include <errno.h>
#include "nss.h"
#include "TStringTable.h"
#include "TUfbsHandler.h"
#include <unistd.h>
//////////////////////////////////////// Library reference
#define SLDAP_LIB_NAME					"libnss_ldap.so.2"
#define SLDAP_LIB_GETPWUID			"_nss_ldap_getpwuid_r"

using namespace eriNssUfbsCmdNamespace;

// Public method of the class
TUfbsHandler::TUfbsHandler() :
m_handleNss(NULL),
getldappwuid(NULL),
m_enmRetCode(),
m_strRetMsg("")
{
	// Set initial error to SUCCESS
	SetInternalError(errUfbsOk, SERR_UFBS_SUCCESS);
}

TUfbsHandler::~TUfbsHandler()
{
	// Release library
	FreeLibrary();
}

bool TUfbsHandler::Initialize()
{
	bool bRet;
	std::ostringstream ostErrMsg;
	// Initialization
	bRet = false;
	// Set internal error to unknow
	SetInternalError(errUfbsUnknow, SERR_UFBS_UNKNOW);
	// Check for last initialization
	if(m_handleNss == NULL){
		// Load library
		m_handleNss = dlopen(SLDAP_LIB_NAME, RTLD_NOW | RTLD_LOCAL);
		// Check for error
		if(m_handleNss != NULL){
			// Get proc address
			getldappwuid = (int(*)(uid_t, void *, char *, size_t, int *))dlsym(m_handleNss, SLDAP_LIB_GETPWUID);
			// Check for error
			if(getldappwuid != NULL){
				// Ok, the method is correctly mapped.
				SetInternalError(errUfbsOk, SERR_UFBS_SUCCESS);
				// Set exit flag
				bRet = true;
			}else{
				// Error to get the method address
				SetInternalError(errUfbsMethod, SERR_UFBS_METHOD);
			}
		}else{
			// Unable to load library
			ostErrMsg << SERR_UFBS_UNABLELOADLIB << SUFBS_SPACE << SUFBS_SQUARE_OPEN << SLDAP_LIB_NAME << SUFBS_SQUARE_CLOSE;
			// Set the error
			SetInternalError(errUfbsUnableLoad, ostErrMsg.str());
		}
	}else{
		// Already initialized error
		SetInternalError(errUfbsInit, SERR_UFBS_INITIALIZED);
	}
	// Exit from method
	return (bRet);
}

bool TUfbsHandler::ldapGetPwUid(uid_t uid, TsPassword *pPasswd)
{
	bool bRet;
	int iStatus;
	int iBufSize;
	int iErrResult;
	char *pBuf;
	struct passwd strctPwd;
	// Initialization
	bRet = false;
	iBufSize = -1;
	iErrResult = -1;
	iStatus = NSS_STATUS_UNAVAIL;
	pBuf = NULL;
	memset(&strctPwd, 0, sizeof(struct passwd));
	// Set internal error to unknow
	SetInternalError(errUfbsUnknow, SERR_UFBS_UNKNOW);
	// check argument
	if(pPasswd != NULL){
		// Clear output args
		ClearPasswd(pPasswd);
		// Get the buffer size
		iBufSize = sysconf(_SC_GETPW_R_SIZE_MAX);
		// Check the correct buffer size result
		if(iBufSize < 0){
			// Set default value
			iBufSize = 1024;
		}
		// Allocate the buffer
		pBuf = new char [iBufSize];
		// Invoke _nss_ldap_getpwuid_r
		iStatus = getldappwuid(uid, &strctPwd, pBuf, 16384, &iErrResult);
			// Check for errors
		if(iStatus == NSS_STATUS_SUCCESS){
			// Ok. Copy to output structure
			CopyPasswd(pPasswd, strctPwd);
			// Set error to success
			SetInternalError(errUfbsOk, SERR_UFBS_SUCCESS);
			// Set exit code to ok
			bRet = true;
		}else if(iStatus == NSS_STATUS_NOTFOUND){
			// UID not found in ldap
			SetInternalError(errUfbsUIDnotFound, SERR_UFBS_UIDNOTFOUND);
		}else if(iStatus == NSS_STATUS_TRYAGAIN){
			// Currently not available
			SetInternalError(errUfbsRetry, SERR_UFBS_RETRY);
		}else if(iStatus == NSS_STATUS_UNAVAIL){
			// Resource not available
			SetInternalError(errUfbsUnavail, SERR_UFBS_UNAVAIL);
		}
		// Release the buffer
		delete[] (pBuf);
		pBuf = NULL;
	}
	// Exit from method
	return bRet;
}

void TUfbsHandler::GetInternalError(errNssUfbs *penmRetCode, std::string *strRetMsg)
{
	// Set the return code
	*penmRetCode = m_enmRetCode;
	// Set the return message string
	*strRetMsg = m_strRetMsg;
}

//////////////////////////////////////// Private method of the class
void TUfbsHandler::FreeLibrary()
{
	// Check if the handle exist
	if(m_handleNss != NULL) {
		// Close the library
		dlclose(m_handleNss);
		// Set the handle to null
		m_handleNss = NULL;
		// Set procs to null
		getldappwuid = NULL;
	}
}

void TUfbsHandler::SetInternalError(const errNssUfbs &enmRetCode, const std::string &strRetMsg)
{
	// Store the return code
	m_enmRetCode = enmRetCode;
	// Store the return message string
	m_strRetMsg = strRetMsg;
}

void TUfbsHandler::ClearPasswd(TsPassword *pPasswd)
{
	// Check for valid argument
	if(pPasswd != NULL){
		// Clear the item
		pPasswd->uId = 0;
		pPasswd->uGid = 0;
		pPasswd->strName.clear();
		pPasswd->strPasswd.clear();
		pPasswd->strGecos.clear();
		pPasswd->strDir.clear();
		pPasswd->strShell.clear();
	}
}

void TUfbsHandler::CopyPasswd(TsPassword *pstrctPasswdDes, struct passwd &strctPwdSrc)
{
	// Check for valid argument
	if(pstrctPasswdDes != NULL){
		// Copy the item
		pstrctPasswdDes->uId = strctPwdSrc.pw_uid;
		pstrctPasswdDes->uGid = strctPwdSrc.pw_gid;
		pstrctPasswdDes->strName.assign(strctPwdSrc.pw_name);
		pstrctPasswdDes->strPasswd.assign(strctPwdSrc.pw_passwd);
		pstrctPasswdDes->strGecos.assign(strctPwdSrc.pw_gecos);
		pstrctPasswdDes->strDir.assign(strctPwdSrc.pw_dir);
		pstrctPasswdDes->strShell.assign(strctPwdSrc.pw_shell);
	}
}