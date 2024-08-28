#pragma once

#include <string>
#include <string.h>
#include <stddef.h>
#include "TConfigFile.h"
#include "TUfbsHandler.h"

#define IUFBS_DB_ERROR							-1
#define IUFBS_DB_SUCCESS						0
#define IUFBS_DB_EMPTY							1
#define IUFBS_DB_SUCCESS_FOUND			2
#define IUFBS_DB_SUCCESS_NOTFOUND		3

namespace eriNssUfbsCmdNamespace{
	//////////////////////////////////////// Return code enumerator
	enum errNssDb{
		errDbOk = 0,
		errDbUnknow,
		errDbCreate,
		errDbOpen,
		errDbAlready,
		errDbNotOpen,
		errDbHandling,
		errDbFormat,
		errDbTmp,
		errDbWrite,
		errDbRead,
		errDbTmpCreate,
		errDbTmpAlready,
		errDbCopy,
		errDbTruncate,
		errDbUidNotFound,
		errDbRename,
		errDbPath,
		errDbWorkPath,
		errDbTmpPath,
		errDbCloseWDb,
		errDbLocked,
		errDbLockD
	};
	//////////////////////////////////////// Class
	class TDbHandler
	{
	public:
	////////////////////////////////////// Costructor-Distructor
		TDbHandler();
		virtual ~TDbHandler();
	////////////////////////////////////// Public Method
		// Open Database
		bool OpenDbInstance();
		// Close
		bool CloseDbInstance();
		// Insert the input tuple in the database
		bool InsertItemInDb(const TsPassword &pwd);
		// Remove item UID from database
		bool RemoveItemInDb(__uid_t uiUid);
		// Clear the database
		bool ClearDatabase();
		// Get internal object error
		void GetInternalError(errNssDb *penmRetCode, std::string *strRetMsg);
		// Debug only
		void printPwd(TsPassword pwd);
	////////////////////////////////////// Private Method
	private:
		// Get the database work file path
		bool GetDatapaseWorkPath(std::string *pstrWorkPath);
		// Get the temporary file path
		bool GetTempFilePath(std::string *pstrTmpFilePath);
		// Remove item UID from database and set pbNlLatest to true if the latest char of the DB file is '\n'
		int RemoveItemInDb(__uid_t uiUid, bool *pbNlLatest);
		// Convert the database file line in TsPassword structure
		int ParsingLine(const char *pBuf, TsPassword *pwd);
		// Clear structure
		void ClearPwdStruct(TsPassword *pwd);
		// Create temporary database file
		bool CreateTmpFile();
		// Flush temporary database file. Force the transfer from tmp file and WorkFile
		bool FlushTmpFile();
		// Close temporary file
		void CloseTmpFile();
		// Copy source file to destination
		bool CopyFile(const std::string &from, const std::string &to);
		// Trasfer the byte of the In file to Out file
		bool FileTransfer(FILE *pFileIn, FILE *pFileOut);
		// Truncate to 0 length the file
		bool Truncate(FILE *pFile);
		// Check if the database is locked. Return true if the database is not locked
		bool LockDatabase();
		// Unlock the database
		bool UnLockDatabase();
		// Set internal error
		void SetInternalError(const errNssDb &enmRetCode, const std::string &strRetMsg);
	////////////////////////////////////// Private Attribute
	private:
		FILE *m_pWorkFile;					// Db Work file instance
		FILE *m_pTmpFile;						// Db temporary file instance
		int m_iLckFile;							// Lock file descriptor
		TConfigFile *m_pConfig;			// Parameter readed from config file
		errNssDb m_enmRetCode;			// Return error code
		std::string m_strRetMsg;		// Return error message
	}; // class TDbHandler
} // namespace eriNssUfbsCmdNamespace