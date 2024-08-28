#pragma once

#include <string>
#include <string.h>
#include <stddef.h>
#include <stdlib.h>
#include <pwd.h>

namespace eriNssUfbsCmdNamespace{
		////////////////////////////////////// Public Structure
	struct TsPassword{
		__uid_t uId;						// User ID
		__gid_t uGid;						// Group ID
		std::string strName;		// Username
		std::string strPasswd;	// Password
		std::string strGecos;		// Real name
		std::string strDir;			// Home directory
		std::string strShell;		// Shell program
	};
	//////////////////////////////////////// Return code enumerator
	enum errNssUfbs{
		errUfbsOk = 0,
		errUfbsUnknow,
		errUfbsInit,
		errUfbsUnableLoad,
		errUfbsMethod,
		errUfbsUIDnotFound,
		errUfbsRetry,
		errUfbsUnavail
	};
	//////////////////////////////////////// Class
	class TUfbsHandler
	{
	public:
	////////////////////////////////////// Costructor-Distructor
		TUfbsHandler();
		virtual ~TUfbsHandler();
		////////////////////////////////////// Public Method
		// Initialize the object. Return false if an error occur.
		bool Initialize();
		// Get LDAP password database from uid
		bool ldapGetPwUid(uid_t uid, TsPassword *pPasswd);
		// Get internal object error
		void GetInternalError(errNssUfbs *penmRetCode, std::string *strRetMsg);
	////////////////////////////////////// Private Method
	private:
		// Release the library
		void FreeLibrary();
		// Clear password structure
		void ClearPasswd(TsPassword *pPasswd);
		// Copy passwd structure to internal structure
		void CopyPasswd(TsPassword *pstrctPasswdDes, struct passwd &strctPwdSrc);
		// Set internal error
		void SetInternalError(const errNssUfbs &enmRetCode, const std::string &strRetMsg);
	////////////////////////////////////// Private Attribute
	private:
		void* m_handleNss;																					// Library libnss_ldap.so.2 handle
		int (*getldappwuid)(uid_t, void *, char *, size_t, int *);	// _nss_ldap_getpwuid_r function pointer of libnss_ldap.so.2 library
		errNssUfbs m_enmRetCode;																		// Return error code
		std::string m_strRetMsg;																		// Return error message
	}; // class TUfbsHandler
} // namespace eriNssUfbsCmdNamespace