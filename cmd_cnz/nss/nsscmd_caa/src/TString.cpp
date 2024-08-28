#include "TString.h"

#define STR_PATH_SEPARATPR					"\\/"
#define STR_TRIM_CHARACTER					" \f\n\r\t\v"

std::string TString::TrimLeft(const std::string &strIn)
{
	std::string strOut;
	// Assign to local string
	strOut = strIn;
	// Trim
	strOut.erase(0, strOut.find_first_not_of(STR_TRIM_CHARACTER));
	// Exit from method. NOTE: this method return an object for semplify assignation
	return (strOut);
}

std::string TString::TrimRight(const std::string &strIn)
{
	std::string strOut;
	// Assign to local string
	strOut = strIn;
	// Trim
	strOut.erase(strOut.find_last_not_of(STR_TRIM_CHARACTER) + 1 );
	// Exit from method. NOTE: this method return an object for semplify assignation
	return (strOut);
}

std::string TString::Trim(const std::string &strIn)
{
	std::string strOut;
	// Assign left trim input string
	strOut = TString::TrimLeft(strIn);
	// Trim Right
	strOut = TString::TrimRight(strOut);
	// Exit from method. NOTE: this method return an object for semplify assignation
	return (strOut);
}

std::string TString::PathFileName(const std::string &strFullPath)
{
	int iPos;
	int iLen;
	std::string strRet;
	// Initialization
	iPos = -1;
	// Check for input argument
	if(strFullPath.empty() == false){
		// Get string length
		iLen = strFullPath.length();
		// Find last of separator
		iPos = strFullPath.find_last_of(STR_PATH_SEPARATPR);
		// Chekc if the separator has been found
		if((iPos >= 0) && (iPos < iLen - 1)){
			strRet.assign(strFullPath.substr(iPos + 1, iLen - iPos));
		}else if(iPos < 0){
			// No separator found. Assign all the name
			strRet.assign(strFullPath);
		}
	}
	// Exit from method. NOTE: this method return an object for semplify assignation
	return(strRet);
}
