#include <sstream>
#include <cstdlib>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include "TString.h"
#include "TStringTable.h"
#include "TDbHandler.h"

#define STR_NSSDB_LOCKPATH			"/var/lock/~nss_ufbs.lck"

#define MAX_UFDB_FILEBUFFER			2048
#define MAX_UFDB_CPYBUFFER			4096
#define IUFBS_DB_PASSWDFIELDS		7

#define SDB_FIELD_SEPARATOR			":"
#define SDB_FIELD_ENDLINE       "\n"
#define SDB_FILEOPEN_WRITEPLUS	"w+"
#define SDB_FILEOPEN_WRITE			"w"
#define SDB_FILEOPEN_READPLUS		"r+"
#define SDB_FILEOPEN_READ				"r"
#define SDB_PATH_SEPARATOR			"/"
#define SDB_PATH_TMPDBSUFFIX		"~tmp_"
#define SDB_PATH_WORKDBEXT			"~.tmp"

using namespace eriNssUfbsCmdNamespace;

TDbHandler::TDbHandler() :
m_pWorkFile(NULL),
m_pTmpFile(NULL),
m_iLckFile(-1),
m_pConfig(NULL)
{
	// Create config file object. If this pointer is null, must be crash (segmentation)
	m_pConfig = new TConfigFile();
	// Set initial error to SUCCESS
	SetInternalError(errDbOk, SERR_UFBS_SUCCESS);
}

TDbHandler::~TDbHandler()
{
	// Delete config file
	delete(m_pConfig);
	// Invalidate pointer
	m_pConfig = NULL;
}

bool TDbHandler::OpenDbInstance()
{
	bool bRet;
	std::string strDbFilePath;	// Original DB path
	std::string strDbWorkPath;	// Work DB path (where the class operate)
	std::string strDbTempPath;	// Temporary DB (where the class temporary operate)
	std::ostringstream ostErrMsg;
  struct stat fileInfo;
	// Initialization
	bRet = false;
	// Set error to undefined
	SetInternalError(errDbUnknow, SERR_UFDB_UNKNOW);
	// Lock database
	if(LockDatabase() == true){
		// Check if the database is already opened
		if(m_pWorkFile == NULL){
			// Get database path for W_FILE
			bRet = m_pConfig->GetConfigValue(NSS_CONFIG_WFILE, &strDbFilePath);
			// Check for error
			if(bRet == true){
				// Set flag to error
				bRet = GetDatapaseWorkPath(&strDbWorkPath);
				// Check for error
				if(bRet == true){
					// Reset flag
					bRet = false;
					// Check if the database file exist
					if(stat(strDbFilePath.c_str(), &fileInfo) != 0){
						// Not exist. Create the work db file
						m_pWorkFile = fopen(strDbWorkPath.c_str(),SDB_FILEOPEN_WRITEPLUS);
						// Check for error
						if (m_pWorkFile != NULL){
							// File created successfully
							bRet = true;
							// Set error to success
							SetInternalError(errDbOk, SERR_UFDB_SUCCESS);
						}else{
							// Unable to create database file
							ostErrMsg << SERR_UFDB_CREATEDB << SUFBS_SPACE << SUFBS_SQUARE_OPEN << strDbFilePath.c_str() << SUFBS_SQUARE_CLOSE;
							// Set error
							SetInternalError(errDbCreate, ostErrMsg.str());
						}
					}else{
						// File exist. copy it in the tmp folder
						bRet = CopyFile(strDbFilePath, strDbWorkPath);
						// Check for copy error
						if(bRet == true){
							// Reset flag
							bRet = false;
							m_pWorkFile = fopen(strDbWorkPath.c_str(),SDB_FILEOPEN_READPLUS);
							// Check for error
							if (m_pWorkFile != NULL){
								// File opened successfully
								bRet = true;
							}else{
								// Unable to create database file
								ostErrMsg << SERR_UFDB_OPENDB << SUFBS_SPACE << SUFBS_SQUARE_OPEN << strDbFilePath.c_str() << SUFBS_SQUARE_CLOSE;
								// Set error
								SetInternalError(errDbOpen, ostErrMsg.str());
							}
						}
					}
				}else{
					// Unable to create temporary DB
					ostErrMsg << SERR_UFDB_CREATETMP << SUFBS_SPACE << SUFBS_SQUARE_OPEN << strDbWorkPath.c_str() << SUFBS_SQUARE_CLOSE;
					// Set error
					SetInternalError(errDbTmpCreate, ostErrMsg.str());
				}
			}else{
				// Unable to get DB path from config file
				SetInternalError(errDbPath, SERR_UFDB_DBPATH);
			}
		}else{
			// Database is already opened
			SetInternalError(errDbAlready, SERR_UFDB_ALREADYOPEN);
		}
	}else{
		// Database file is locked.
		SetInternalError(errDbLocked, SERR_UFDB_LOCKED);
	}
	// Check for create tmp file
	if(bRet == true){
		// Open temporary file
		bRet = CreateTmpFile();
		// Check for error
		if(bRet == false){
			// Close work database
			fclose(m_pWorkFile);
			// Invalidate the pointer
			m_pWorkFile = NULL;
		}
	}
	// Exit from method
	return(bRet);
}

bool TDbHandler::CloseDbInstance()
{
	bool bRet;
	std::string strDb;
	std::string strWorkDb;
	// Initialization
	bRet = false;
	// Close temp file
	CloseTmpFile();
	// Check if the work database is open
	if(m_pWorkFile != NULL){
		// Close the file
		if (fclose(m_pWorkFile) == 0){
			// Invalid the pointer
			m_pWorkFile = NULL;
			// Get the path for DB and workDB
			if(GetDatapaseWorkPath(&strWorkDb) == true){
				// Get database path
				if(m_pConfig->GetConfigValue(NSS_CONFIG_WFILE, &strDb) == true){
					// Rename the database file
					if(rename(strWorkDb.c_str(), strDb.c_str()) == 0){
						// Success
						bRet = true;
						// Set internal error
						SetInternalError(errDbOk, SERR_UFDB_SUCCESS);
					}else{
						// Rename error
						SetInternalError(errDbRename, SERR_UFDB_RENAME);
					}
				}else{
					// Unable to get DB path from config file
					SetInternalError(errDbPath, SERR_UFDB_DBPATH);
				}
			}
		}else{
			// Failed to close work db.
			SetInternalError(errDbCloseWDb, SERR_UFDB_CLOSEWDB);
		}
	}
	// Release lock file handle
	UnLockDatabase();
	// Exit from method
	return (bRet);
}

bool TDbHandler::RemoveItemInDb(__uid_t uiUid)
{
	bool bRet;
	bool bIsNewLine;
	int iFlag;
	// Initialization
	bRet = false;
	bIsNewLine = false;
	iFlag = IUFBS_DB_ERROR;
	// Set error to undefined
	SetInternalError(errDbUnknow, SERR_UFDB_UNKNOW);
	// Check if the database is opened
	if(m_pWorkFile != NULL){
		// Remove item
		iFlag = RemoveItemInDb(uiUid, &bIsNewLine);
		// Check for error
		if(iFlag == IUFBS_DB_SUCCESS_FOUND){
			// Flush the database
			bRet = FlushTmpFile();
			// Check for error
			if (bRet==true){
				// Set error to succes
				SetInternalError(errDbOk, SERR_UFDB_SUCCESS);
			}
		}else if(iFlag == IUFBS_DB_SUCCESS_NOTFOUND){
			// Set error to succes
			SetInternalError(errDbUidNotFound, SERR_UFDB_UIDNOTFOUND);
		}
	}else{
		// Error database is not open
		SetInternalError(errDbNotOpen, SERR_UFDB_DBNOTOPEN);
	}
	// Exit from method
	return (bRet);
}

bool TDbHandler::InsertItemInDb(const TsPassword &pwd)
{
	bool bRet;
	bool bIsNewLine;
	int iFlag;
	size_t iIoBytes;
	std::ostringstream ostrTuple;
	// Initialization
	bRet = false;
	bIsNewLine = false;
	iIoBytes = 0;
	iFlag = IUFBS_DB_ERROR;
	// Set error to undefined
	SetInternalError(errDbUnknow, SERR_UFDB_UNKNOW);
	// Check if the database is opened
	if(m_pWorkFile != NULL){
		// Remove item UID from database
		iFlag = RemoveItemInDb(pwd.uId, &bIsNewLine);
		// Check for error
		if(iFlag != IUFBS_DB_ERROR){
			// Ok. Reset flag to error
			bRet = false;
			// Check for new line
			if(bIsNewLine == false){
				// Insert new line
				ostrTuple << SDB_FIELD_ENDLINE;
			}
			// Create the tuple
			ostrTuple << pwd.strName << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.strPasswd << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.uId << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.uGid << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.strGecos << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.strDir << SDB_FIELD_SEPARATOR;
			ostrTuple << pwd.strShell << SDB_FIELD_ENDLINE;
			// Insert in the database
			iIoBytes = fwrite(ostrTuple.str().c_str(), 1, ostrTuple.str().length(), m_pTmpFile);
			// Check for error
			if(iIoBytes == ostrTuple.str().length()){
				// Write OK. Set return flag to true
				bRet = true;
				// Set error to success
				SetInternalError(errDbOk, SERR_UFDB_SUCCESS);
			}else{
				// Write ERROR.
				SetInternalError(errDbWrite, SERR_UFDB_WRITEFILE);
			}
			// Flush tmp file
			bRet = FlushTmpFile();
		}
	}else{
		// Error database is not open
		SetInternalError(errDbNotOpen, SERR_UFDB_DBNOTOPEN);
	}
	// Exit from method
	return (bRet);
}

bool TDbHandler::ClearDatabase()
{
	bool bRet;
	// Initialization
	bRet = false;
	// Set error to undefined
	SetInternalError(errDbUnknow, SERR_UFDB_UNKNOW);
	// Check if the database is opened
	if(m_pWorkFile != NULL){
		// Truncate the work database
		bRet = Truncate(m_pWorkFile);
		// Check for error
		if(bRet == true){
			// Set error to success
			SetInternalError(errDbOk, SERR_UFDB_SUCCESS);
		}
	}else{
		// Error database is not open
		SetInternalError(errDbNotOpen, SERR_UFDB_DBNOTOPEN);
	}
	// Exit from method
	return (bRet);
}

void TDbHandler::GetInternalError(errNssDb *penmRetCode, std::string *strRetMsg)
{
	// Set the return code
	*penmRetCode = m_enmRetCode;
	// Set the return message string
	*strRetMsg = m_strRetMsg;
}

// DEBUG only
void TDbHandler::printPwd(TsPassword pwd)
{
	std::ostringstream ostrTuple;
	// Create the tuple
	ostrTuple << pwd.strName << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.strPasswd << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.uId << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.uGid << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.strGecos << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.strDir << SDB_FIELD_SEPARATOR;
	ostrTuple << pwd.strShell;
	printf("%s\n", ostrTuple.str().c_str());
//	printf("pwd contains:\n");
//	printf("pwd.pw_dir    [%s]\n", pwd.strDir.c_str());
//	printf("pwd.pw_gecos  [%s]\n", pwd.strGecos.c_str());
//	printf("pwd.pw_gid    [%i]\n", pwd.uGid);
//	printf("pwd.pw_name   [%s]\n", pwd.strName.c_str());
//	printf("pwd.pw_passwd [%s]\n", pwd.strPasswd.c_str());
//	printf("pwd.pw_shell  [%s]\n", pwd.strShell.c_str());
//	printf("pwd.pw_uid    [%i]\n", pwd.uId);
}

//////////////////////////////////////// Private method of the class

bool TDbHandler::LockDatabase()
{
	bool bLocked;
	struct flock strctFileLock;
	std::string strLockPath;
	// Initialization
	bLocked = false;
	memset(&strctFileLock, 0, sizeof(struct flock));
	// Check for old lock
	if(m_iLckFile < 0){
		// Get Lock path
		strLockPath.assign(STR_NSSDB_LOCKPATH);
		// Open it
		m_iLckFile = open(strLockPath.c_str(), O_RDWR | O_CREAT);
		// Check for error
		if(m_iLckFile >= 0){
			// Now Fill the structure
			strctFileLock.l_type = F_WRLCK;
			strctFileLock.l_whence = SEEK_SET;
			// Retrive file lock status
			if(fcntl(m_iLckFile, F_SETLK, &strctFileLock) == -1){
				// Filter error type
				if (errno == EACCES || errno == EAGAIN){
					// File is locked
					bLocked = true;
				}
			}
		}else{
			// Unable to obtain file descriptor
			SetInternalError(errDbLockD, SERR_UFDB_LOCKDESCR);
		}
	}else{
		// File is previously locked
		bLocked = true;
	}
	// Exit from method
	return (!bLocked);
}

bool TDbHandler::UnLockDatabase()
{
	bool bRet;
	struct flock strctFileLock;
	// Initialization
	bRet = false;
	memset(&strctFileLock, 0, sizeof(struct flock));
	// Check for lock
	if(m_iLckFile >= 0){
		// Fill the structure
		strctFileLock.l_type = F_UNLCK;
		strctFileLock.l_whence = SEEK_SET;
		// Send unlock
		if(fcntl(m_iLckFile, F_SETLK, &strctFileLock) != -1){
			// Set oexit flag to success
			bRet = true;
    }
		// Close file descriptor
		close(m_iLckFile);
		// Invalidate the descriptor
		m_iLckFile = -1;
	}
	// Exit frim method
	return(bRet);
}

bool TDbHandler::GetTempFilePath(std::string *pstrTmpFilePath)
{
	bool bRet;
	std::string strDbPath;
	std::ostringstream strTmpPath;
	// Initialization
	bRet = false;
	// Check argument pointer
	if (pstrTmpFilePath != NULL){
		// Get database path
		if (m_pConfig->GetConfigValue(NSS_CONFIG_WFILE, &strDbPath) == true){
			// Create the temporary file string
			strTmpPath << P_tmpdir;
			strTmpPath << SDB_PATH_SEPARATOR;
			strTmpPath << SDB_PATH_TMPDBSUFFIX;
			strTmpPath << getpid();
			strTmpPath << TString::PathFileName(strDbPath);
			// Set tmp file path
			pstrTmpFilePath->assign(strTmpPath.str());
			// Set exit flag
			bRet = true;
		}
	}
	// Check for error
	if(bRet == false){
		// Unable to obtain database path
		SetInternalError(errDbTmpPath, SERR_UFDB_DBTMPPATH);
	}
	// Exit from method
	return (bRet);
}

bool TDbHandler::GetDatapaseWorkPath(std::string *pstrWorkPath)
{
	bool bRet;
	std::string strDbPath;
	std::ostringstream strTmpPath;
	// Initialization
	bRet = false;
	// Check argument pointer
	if (pstrWorkPath != NULL){
		// Get database path
		if (m_pConfig->GetConfigValue(NSS_CONFIG_WFILE, &strDbPath) == true){
			// Create the temporary file string
			strTmpPath << strDbPath;
			strTmpPath << SDB_PATH_WORKDBEXT;
			// Set tmp file path
			pstrWorkPath->assign(strTmpPath.str());
			// Set exit flag
			bRet = true;
		}
	}
	// Check for error
	if(bRet == false){
		// Unable to obtain database path
		SetInternalError(errDbTmpPath, SERR_UFDB_DBTMPPATH);
	}
	// Exit from method
	return (bRet);
}

bool TDbHandler::CreateTmpFile()
{
	bool bRet;
	std::string strTmpFilePath;
	// Initialization
	bRet = false;
	// Check if the database is already opened
	if(m_pTmpFile == NULL){
		// Get temp file
		bRet = GetTempFilePath(&strTmpFilePath);
		// Check for error
		if(bRet == true){
			// Reset flag
			bRet = false;
			// Open the output file
			m_pTmpFile = fopen(strTmpFilePath.c_str(), SDB_FILEOPEN_WRITEPLUS);
			// Check for error
			if (m_pTmpFile != NULL){
				// Set exit flag
				bRet = true;
			}else{
				// Error to open tmp file
				SetInternalError(errDbTmpCreate, SERR_UFDB_CREATETMP);
			}
		}
	}else{
		// Tmp file is opened
		bRet = true;
	}
	// Exit from method
	return (bRet);
}

int TDbHandler::RemoveItemInDb(__uid_t uiUid, bool *pbNlLatest)
{
	int iRet;
	bool bExit;
	bool bFound;
	int iFlag;
	unsigned int istrLen;
	unsigned int uiByteWrited;
	char *pBuf;
	char chEndLine;
	std::string strTmpFilePath;
	std::ostringstream ostErrMsg;
	TsPassword pwd;
	// Initialization
	iRet = IUFBS_DB_ERROR;
	bExit = false;
	bFound = false;
	iFlag = IUFBS_DB_ERROR;
	istrLen = 0;
	uiByteWrited = 0;
	pBuf = NULL;
	chEndLine = std::string(SDB_FIELD_ENDLINE).at(0);
	// Check database status
	if((m_pWorkFile != NULL) && (m_pTmpFile != NULL) && (pbNlLatest != NULL)){
		// Seek to begin of the database
		if ((fseek(m_pWorkFile, 0, SEEK_SET) == 0) && ((fseek(m_pTmpFile, 0, SEEK_SET) == 0))){
			// Create buffer
			pBuf = new char[MAX_UFDB_FILEBUFFER];
			// Set flag (true to prevent empty file that not have NL).
			*pbNlLatest = true;
			// for all line of the database
			while((fgets(pBuf, MAX_UFDB_FILEBUFFER, m_pWorkFile) != NULL) && (bExit == false)){
				// Parsing the string
				iFlag = ParsingLine(pBuf, &pwd);
				// Check if the tuble must be inserted
				if(((iFlag == IUFBS_DB_SUCCESS) && (uiUid != pwd.uId)) || (iFlag == IUFBS_DB_EMPTY)){
					// Get string buffer len
					istrLen = strlen(pBuf);
					// Insert it in the tmp file.
					uiByteWrited = fwrite(pBuf, 1, istrLen, m_pTmpFile);
					// Store if the latest character of the buffer is a "\n"
					if(pBuf[istrLen - 1] == chEndLine){
						// The lina have a latest char as new line
						*pbNlLatest = true;
					}else{
						// The lina not have a latest char as new line
						*pbNlLatest = false;
					}
					// Check for write error
					if(uiByteWrited != istrLen){
						// Write error. Set exit flag
						bExit = true;
					}
				}else if (iFlag == IUFBS_DB_ERROR){
					// Set exit flag
					bExit = true;
					// Error while parsing the file
					SetInternalError(errDbFormat, SERR_UFDB_DBFORMAT);
				}else if((iFlag == IUFBS_DB_SUCCESS) && (uiUid == pwd.uId)){
					// Item found. Set found path
					bFound = true;
				}
			} // while
			// Desttroy the buffer
			delete[](pBuf);
			// Invalidate the pointer
			pBuf = NULL;
			// Set ret flag
			if(bExit == false){
				iRet = IUFBS_DB_SUCCESS;
			}
		}else{
			// Error to handling database file
			SetInternalError(errDbHandling, SERR_UFDB_DBHANDLING);
		}
	}else{
		// Error database is not open
		SetInternalError(errDbNotOpen, SERR_UFDB_DBNOTOPEN);
	}
	// codify return code
	if(iRet == IUFBS_DB_SUCCESS){
		// Codify found
		if(bFound == true){
			// Success and item found
			iRet = IUFBS_DB_SUCCESS_FOUND;
		}else{
			// Succes but item not found
			iRet = IUFBS_DB_SUCCESS_NOTFOUND;
		}
	}
	// Exit from method
	return (iRet);
}

int TDbHandler::ParsingLine(const char *pBuf, TsPassword *pwd)
{
	bool bExit;
	int iCount;
	int iPos;
	int iOldPos;
	int iRet;
	std::string strLine;
	std::string strSeparator;
	std::string strSplit[IUFBS_DB_PASSWDFIELDS];
	// Initialization
	bExit = false;
	iCount = 0;
	iOldPos = 0;
	iPos = 0;
	iRet = IUFBS_DB_ERROR;
	// Check arguments pointer
	if(pwd != NULL){
		// Clear structure
		ClearPwdStruct(pwd);
		// Check for valid buffer
		if(pBuf != NULL){
			// Convert the buffer in string
			strLine.assign(pBuf);
			// Trim the buffer
			strLine = TString::Trim(strLine);
			// Check if "/n" exist on the end of the buffer
			if(strLine.length() > 0){
				// Insert terminator
				strLine.append(SDB_FIELD_ENDLINE);
				// Set default database field separator
				strSeparator.assign(SDB_FIELD_SEPARATOR);
				// For all field in the string
				while ((iCount < IUFBS_DB_PASSWDFIELDS) && (bExit == false)){
					// Switch for field separator
					if(iCount == IUFBS_DB_PASSWDFIELDS - 1){
						// For the latest field the separator is new line
						strSeparator.assign(SDB_FIELD_ENDLINE);
					}
					// Get separator location
					iPos = strLine.find(strSeparator, iOldPos);
					// Check if one of separator are been found
					if (iPos >= 0){
						// Copy substring in relative array
						strSplit[iCount] = strLine.substr(iOldPos, iPos - iOldPos);
						// Store iPos
						iOldPos = iPos + 1;
					}else{
						// Exit with format error
						bExit = true;
						// Set internal error
						SetInternalError(errDbFormat, SERR_UFDB_DBFORMAT);
					}
					// Next field
					++iCount;
				} // while
				// Check for while error
				if(bExit == false){
					// The latest string (obtained finding a "\n") could be contains a ":" separator.
					// This is a error.
					iPos = strSplit[IUFBS_DB_PASSWDFIELDS - 1].find(SDB_FIELD_SEPARATOR, 0);
					// Verify that the latest field is correct (not contain ":")
					if (iPos < 0){
						// Copy the array of parsering information in output structure
						pwd->strName = TString::Trim(strSplit[0]);
						pwd->strPasswd = TString::Trim(strSplit[1]);
						pwd->uId = std::strtoul(TString::Trim(strSplit[2]).c_str(),0,10);
						pwd->uGid = std::strtoul(TString::Trim(strSplit[3]).c_str(),0,10);
						pwd->strGecos = TString::Trim(strSplit[4]);
						pwd->strDir = TString::Trim(strSplit[5]);
						pwd->strShell = TString::Trim(strSplit[6]);
						// Set exit flag to success
						iRet = IUFBS_DB_SUCCESS;
					}else{
						// Found ":". Set the error
						bExit = true;
					}
				}
			}else{
				// Set exitcode to empty
				iRet = IUFBS_DB_EMPTY;
			}
		}else{
			// Set exitcode to empty
			iRet = IUFBS_DB_EMPTY;
		}
	}
	// Exit from method
	return (iRet);
}

bool TDbHandler::Truncate(FILE *pFile)
{
	bool bRet;
	int iFileD;
	// initialization
	bRet = false;
	iFileD = -1;
	// Seek to begin
	if (fseek(pFile, 0, SEEK_SET) == 0){
		// Trouncate the workfile
		iFileD = fileno(pFile);
		// Check for error
		if(iFileD > -1){
			// Truncate the file
			if(ftruncate(iFileD, 0) > -1){
				// Set exit flag
				bRet = true;
			}else{
				// Unable to truncate the workfile
				SetInternalError(errDbTruncate, SERR_UFDB_TRUNCWORK);
			}
		}else{
			// Unable to truncate the file
			SetInternalError(errDbWrite, SERR_UFDB_WRITEFILE);
		}
	}else{
		// Error to handling database file
		SetInternalError(errDbHandling, SERR_UFDB_DBHANDLING);
	}
	// Exit from method
	return(bRet);
}

bool TDbHandler::FlushTmpFile()
{
	bool bRet;
	// Initialization
	bRet = false;
	// Reset files pointer
	if (fseek(m_pTmpFile, 0, SEEK_SET) == 0){
		// Truncate the file
		if(Truncate(m_pWorkFile) == true){
			// Ok. Workfile was been truncate. Copy the stream from tmp file and workfile
			bRet = FileTransfer(m_pTmpFile, m_pWorkFile);
			// Check for error
			if(bRet == true){
				// Truncate tmp file
				bRet = Truncate(m_pTmpFile);
			}
		}
	}else{
		// Error to handling database file
		SetInternalError(errDbHandling, SERR_UFDB_DBHANDLING);
	}
	// Exit from method
	return (bRet);
}

void TDbHandler::CloseTmpFile()
{
	std::string strTmpFile;
	// Check if the tmp file is open
	if(m_pTmpFile != NULL){
		// Close the file
		fclose(m_pTmpFile);
		// Invalid the pointer
		m_pTmpFile = NULL;
		// Get temporary file
		if(GetTempFilePath(&strTmpFile) == true){
			// Then, remove it
			remove(strTmpFile.c_str());
		}
	}
}

void TDbHandler::ClearPwdStruct(TsPassword *pwd)
{
	pwd->strName.clear();
	pwd->strPasswd.clear();
	pwd->uId = 0;
	pwd->uGid = 0;
	pwd->strGecos.clear();
	pwd->strDir.clear();
	pwd->strShell.clear();
}

bool TDbHandler::CopyFile(const std::string &strFrom, const std::string &strTo)
{
	bool bRet;
	FILE *pFileIn;
	FILE *pFileOut;
	// Initilaization
	bRet = false;
	pFileIn = NULL;
	pFileOut = NULL;
	// Open source file
	pFileIn = fopen(strFrom.c_str(), SDB_FILEOPEN_READ);
	// Check for error
	if(pFileIn != NULL){
		// Create output file
		pFileOut = fopen(strTo.c_str(), SDB_FILEOPEN_WRITE);
		// Check for error
		if(pFileOut != NULL){
			// Transfer bytes of the source file to destination file
			bRet = FileTransfer(pFileIn, pFileOut);
			// Close output file handle
			fclose(pFileOut);
			// Invalidate the pointer
			pFileOut = NULL;
		}else{
			// Unable to create destination file
			SetInternalError(errDbCopy, SERR_UFDB_TMPCPY);
		}
		// Close input file handle
		fclose(pFileIn);
		// Invalidate the pointer
		pFileIn = NULL;
	}else{
		// Error to open source file
		SetInternalError(errDbCopy, SERR_UFDB_TMPCPY);
	}
	// Exit from method
	return(bRet);
}

bool TDbHandler::FileTransfer(FILE *pFileIn, FILE *pFileOut)
{
	bool bError;
	int iRCount;
	int iWCount;
	char *pBuffer;
	// Initialization
	bError = false;
	iRCount = 0;
	iWCount = 0;
	// Allocate the buffer
	pBuffer = new char[MAX_UFDB_CPYBUFFER];
	// Read first block
	iRCount = fread(pBuffer, 1, MAX_UFDB_CPYBUFFER, pFileIn);
	// Check for error
	if(ferror(pFileIn) == true){
		// Error while read input file
		bError = true;
		// Set internal error
		SetInternalError(errDbCopy, SERR_UFDB_TMPCPY);
	}
	// Cycle to copy all
	while((iRCount > 0) && (bError == false)){
		// Write to destination
		iWCount = fwrite(pBuffer, 1, iRCount, pFileOut);
		// Chekc for write error
		if(iWCount == iRCount){
			// Read next block
			iRCount = fread(pBuffer, 1, MAX_UFDB_CPYBUFFER, pFileIn);
			// Check for error
			if(ferror(pFileIn) == true){
				// Error while read input file
				bError = true;
				// Set internal error
				SetInternalError(errDbCopy, SERR_UFDB_TMPCPY);
			}
		}else{
			// Write error
			bError = true;
			// Set internal error
			SetInternalError(errDbCopy, SERR_UFDB_TMPCPY);
		}
	} // while
	// Release the buffer
	delete[] (pBuffer);
	// Invalidate the buffer
	pBuffer = NULL;
	// Exit form method
	return (!bError);
}

void TDbHandler::SetInternalError(const errNssDb &enmRetCode, const std::string &strRetMsg)
{
	// Store the return code
	m_enmRetCode = enmRetCode;
	// Store the return message string
	m_strRetMsg = strRetMsg;
}
