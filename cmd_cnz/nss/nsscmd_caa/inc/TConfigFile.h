#include <string>

#define NSS_CONFIG_RFILE									0
#define NSS_CONFIG_WFILE									1

namespace eriNssUfbsCmdNamespace{
	//////////////////////////////////////// Error code enumerator
	enum errConfig{
		errConfOk = 0,	// OK. The config file is correctly readed
		errConfEmpty,		// The attribute class is empty (config file not read yet)
		errConfBroken		// Error in config file		
	};
	//////////////////////////////////////// Class
	class TConfigFile{
		public:
		////////////////////////////////////// Public Method
			TConfigFile();
			virtual ~TConfigFile();
		////////////////////////////////////// Public Method
			// Retrive configuration parameter
			bool GetConfigValue(int iParam, std::string *pstrValue);
		////////////////////////////////////// Private Method
		private:
			// Parsing configuration file
			bool ParsingConfigFile(FILE *pFile, std::string *pstrReadPath, std::string *pstrWritePath);
		////////////////////////////////////// Private Attribute
		private:
			errConfig m_nStatus;					// Config Read status
			std::string m_strReadPath;		// Read path attribute
			std::string m_strWritePath;		// Write path attribute
	};
} // namespace