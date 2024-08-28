#include <stdio.h>
#include "TString.h"
#include "TConfigFile.h"

#define STR_CONFIG_FILEPATH					"/opt/ap/apos/conf/fbs.conf"
#define CHR_CONFIG_SEPARATOR				'='
#define STR_CONFIG_WFILE						"W_FILE"
#define STR_CONFIG_RFILE						"R_FILE"
#define MAX_CONFIG_LINEBUFFER				2048

using namespace eriNssUfbsCmdNamespace;

TConfigFile::TConfigFile() :
m_nStatus(errConfEmpty)
{
}

TConfigFile::~TConfigFile()
{
}

bool TConfigFile::GetConfigValue(int iParam, std::string *pstrValue)
{
	bool bRet;
	FILE *pFile;
	std::string strReadPath;
	std::string strWritePath;
	// Initialization
	bRet = false;
	pFile = NULL;
	// Check for argument pointer
	if(pstrValue != NULL){
		// Clear out argument
		pstrValue->clear();
		// Check internal status
		if(m_nStatus == errConfEmpty){
			// Open the config file
			pFile = fopen(STR_CONFIG_FILEPATH, "r");
			// Chekc for error
			if(pFile != NULL){
				// Parsing file
				bRet = ParsingConfigFile(pFile, &strReadPath, &strWritePath);
				// Check result
				if(bRet == true){
					// Copy the value for R_FILE
					m_strReadPath.assign(strReadPath);
					// Copy the value for W_FILE
					m_strWritePath.assign(strWritePath);
					// Set flag to OK
					m_nStatus = errConfOk;
				}
				// close the file
				fclose(pFile);
				// Invalidate the pointer
				pFile = NULL;
			}
		}
		// Check if the config file was correctly readed
		if(m_nStatus == errConfOk){
			// Switch for request param
			if(iParam == NSS_CONFIG_RFILE){
				// Request is Read File Path
				pstrValue->assign(m_strReadPath);
				// Set exit flag to OK
				bRet = true;
			}else if(iParam == NSS_CONFIG_WFILE){
				// Request is Write File Path
				pstrValue->assign(m_strWritePath);
				// Set exit flag to OK
				bRet = true;
			}
		}
	}
	// Exit from method
	return(bRet);
}

//////////////////////////////////////// Private method of the class

bool TConfigFile::ParsingConfigFile(FILE *pFile, std::string *pstrReadPath, std::string *pstrWritePath)
{
	bool bExit;
	int iLen;
	int iPos;
	char *pBuf;
	std::string strLine;
	std::string strLeft;
	std::string strRight;
	// Initialization
	bExit = false;
	iPos = -1;
	iLen = 0;
	pBuf = NULL;
	// Check input argument pointer
	if((pstrReadPath != NULL) && (pstrWritePath != NULL)){
		// Clear the string
		pstrReadPath->clear();
		pstrWritePath->clear();
		// Create buffer
		pBuf = new char[MAX_CONFIG_LINEBUFFER];
		// For all the line
		while((fgets(pBuf, MAX_CONFIG_LINEBUFFER, pFile) != NULL) && (bExit == false)){
			// Convert the buffer in string
			strLine.assign(pBuf);
			// Trim the buffer
			strLine = TString::Trim(strLine);
			// Get trimmed buffer lenght
			iLen = strLine.length();
			// Check the length of the string
			if(iLen > 0){
				// Get separator location
				iPos = strLine.find(CHR_CONFIG_SEPARATOR, 0);
				// Check if one of separator are been found
				if (iPos > 0){
					// Copy substring in relative array
					strLeft = TString::Trim(strLine.substr(0, iPos));
					// Check for right part
					if(iLen > iPos + 1){
						// Get right part
						strRight = TString::Trim(strLine.substr(iPos + 1, (iLen - iPos)));
						// Interpret the tag
						if((strLeft.compare(STR_CONFIG_WFILE) == 0) && (pstrWritePath->empty() == true)){
							// Assign to WritePath
							pstrWritePath->assign(strRight);
						}else if((strLeft.compare(STR_CONFIG_RFILE) == 0) && (pstrReadPath->empty() == true)){
							// Assign to RightPath
							pstrReadPath->assign(strRight);
						}
					}else{
						// Exit with format error
						bExit = true;
					}
				}else{
					// Exit with format error
					bExit = true;
				}
			}
		} // while
		// Desttroy the buffer
		delete[](pBuf);
		// Invalidate the pointer
		pBuf = NULL;
		// Check for correct argument
		if((pstrWritePath->empty() == true) || (pstrReadPath->empty() == true)){
			// This is an error
			bExit = true;
		}
	}else{
		// Force exit
		bExit = true;
	}
	// Exit from method
	return(!bExit);
}

