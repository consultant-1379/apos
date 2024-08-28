#pragma once

#include <string>

//////////////////////////////////////// Class
class TString
{
	public:
	////////////////////////////////////// Public static Method
	static std::string TrimLeft(const std::string &strIn);
	static std::string TrimRight(const std::string &strIn);
	static std::string Trim(const std::string &strIn);
	static std::string PathFileName(const std::string &strFullPath);
};