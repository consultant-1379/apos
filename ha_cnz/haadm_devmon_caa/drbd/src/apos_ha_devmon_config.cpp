/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_devmon_config.cpp
 *
 * @brief
 *
 * This the configuration class of Devmon. It reads the configuration parameters
 * from config file and returns config object
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/

#include <apos_ha_devmon_config.h>

HA_DEVMON_Config::HA_DEVMON_Config()
{
	HA_TRACE_ENTER();
	m_Config.traceMask		=	0;
	m_Config.traceDir		=	const_cast<ACE_TCHAR*>("");
	m_Config.rebootTmout	=	0;
	m_Config.queryInterval	=	0;
	m_Config.callbackTmout  =   0;
	/* init Class with defaults */
	this->initConfig();
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------

HA_DEVMON_Config::~HA_DEVMON_Config()
{
	HA_TRACE_ENTER();
	delete[] m_Config.traceDir;
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------

int HA_DEVMON_Config::initConfig()
{
	HA_TRACE_ENTER();
	/* Initialize structure data with defaults */
	m_Config.traceMask		=	APOS_HA_DFLT_TRCE_CATGY;
	ACE_NEW_NORETURN(this->m_Config.traceDir, ACE_TCHAR[256]);
   	if (0 == this->m_Config.traceDir) {
   		HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.traceDir", __func__);
    }else {
		ACE_OS::memset(m_Config.traceDir, 0, sizeof(ACE_TCHAR[256])-1);
		ACE_OS::strcpy(m_Config.traceDir,APOS_HA_DFLT_TRCE_DIR);
	}
	m_Config.rebootTmout    =   APOS_HA_DFLT_REBOOT_TMOUT;
	m_Config.queryInterval  = 	APOS_HA_DFLT_QUERY_INTERVAL;
	m_Config.callbackTmout  =   APOS_HA_DFLT_CALLBACK_TMOUT;
	HA_TRACE_LEAVE();
	return 0;
}

//-------------------------------------------------------------------------

int HA_DEVMON_Config::readConfig()
{
	HA_TRACE_ENTER();
	FILE *fp;
	ACE_TCHAR buff[100]={0};
	ACE_TCHAR *pch, *pch1, *tmp;
	HA_DEVMON_ConfigT tmpConfig;
	std::string empStr("");
	ACE_INT32 rCode=0;
	bool file_open=true;
	fp = ACE_OS::fopen(APOS_HA_DEVMON_FILE_CNFG, "r");
	if (fp == NULL) {
		HA_LG_ER("Error! fopen FAILED to read [ %s ]",APOS_HA_DEVMON_FILE_CNFG);
		file_open=false;
		rCode=-1;
	}	
	/* initialize the tmpConfig structure to surpress the warnings */
	/* ----------- initialize begin ------------------------ */
	tmpConfig.traceMask 	=	0;
	tmpConfig.traceDir		=	const_cast<ACE_TCHAR*>("");
	tmpConfig.rebootTmout   =   0;
	tmpConfig.callbackTmout =   0;
	tmpConfig.queryInterval =	0; 
	/* ----------- initialize end -------------------------- */
	if (rCode == 0) {
	   	
		while(ACE_OS::fgets(buff, sizeof(buff), fp) != NULL) {
			
			/* Skip Comments and tab spaces in the beginning */
			pch = buff;
			while (*pch == ' ' || *pch == '\t')
				pch++;
			if (*pch == '#' || *pch == '\n')
				continue;
		
			/* In case if we have # somewhere in this line lets truncate the string from there */
			if ((pch1 = ACE_OS::strchr(pch, '#')) != NULL) {
				*pch1++ = '\n';
				*pch1 = '\0';
			}

        	if (ACE_OS::strstr(pch, "DEVMON_TRACE_CATGY=") != NULL) {
            	tmp=getToken(pch, '=');
				tmpConfig.traceMask=strtoull(tmp, NULL, 16);
            	HA_LG_IN("Setting traceMask to [%s]", tmp);
        	}

        	if (ACE_OS::strstr(pch, "DEVMON_TRACE_DIR=") != NULL) {
            	tmp=getToken(pch, '=');
				ACE_NEW_NORETURN(tmpConfig.traceDir, ACE_TCHAR[256]);
    			if (0 == tmpConfig.traceDir) {
        			HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory tmpConfig.traceDir", __func__);
					rCode=-1;
    			}else {
					ACE_OS::memset(tmpConfig.traceDir, 0, sizeof(ACE_TCHAR[256]) -1);
        			ACE_OS::strcpy(tmpConfig.traceDir, tmp);
           			HA_LG_IN("Setting traceDir to [%s]", tmpConfig.traceDir);
    			}
        	}

        	if (ACE_OS::strstr(pch, "DEVMON_QUERY_INTVL=") != NULL) {
            	tmp=getToken(pch, '=');
				tmpConfig.queryInterval=atol(tmp);
            	HA_LG_IN("Setting queryInterval to [%s]", tmp);
        	}

			if (ACE_OS::strstr(pch, "DEVMON_CALLBACK_TMOUT=") != NULL){
				tmp=getToken(pch, '=');
				tmpConfig.callbackTmout= atoi(tmp);
				HA_TRACE("Setting Callback timeout to [%d]", tmpConfig.callbackTmout);
			}

			if (ACE_OS::strstr(pch, "DEVMON_REBOOT_TMOUT=") != NULL){
				tmp=getToken(pch, '=');
				tmpConfig.rebootTmout= atoi(tmp);
				HA_TRACE("Setting Reboot Timeout to [%d]", tmpConfig.rebootTmout);
			}	
    	}
	}

	if (rCode == 0) {
		if (initLog(tmpConfig) < 0) {
			HA_LG_ER("%s(): initializing tracing subsystem failed", __func__);
			rCode=-1;
		}
	}
	if (file_open) {
		if (ACE_OS::fclose(fp) != 0) {
			HA_LG_ER("Error! fclose FAILED");
			rCode=-1;
		}	
	}
	if (*tmpConfig.traceDir) {
		delete[] tmpConfig.traceDir;
		tmpConfig.traceDir=0;
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------

ACE_TCHAR* HA_DEVMON_Config::getToken(char *str, unsigned char tok)
{
	HA_TRACE_ENTER();
	ACE_TCHAR *p, *q;
	int i=0;

	q=p=strchr(str,tok);
	if (!p)
		return (NULL);
    /* truncate the token from the string */
    p++;
    while ( *p != '\0' ){
		if (isspace(*p))
			break;
		else {
			q[i]=*p;
			i++;
		}
		p++;
	}
	q[i]='\0';
	HA_TRACE_LEAVE();
    return q;
}

//-------------------------------------------------------------------------

int HA_DEVMON_Config::initLog(HA_DEVMON_ConfigT tmpConfig) 
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	if (ACE_OS::strcmp(tmpConfig.traceDir, m_Config.traceDir) != 0 ||
		tmpConfig.traceMask != m_Config.traceMask) {
		/*  tracing mask or tracingDir is changed, inform our tracing subsystem
			to go with the change.
		*/
		ACE_TCHAR tracefile[256]={'\0'};
		HA_LG_IN("%s(): Intializing the tracing subsystem", __func__);
		snprintf(tracefile, sizeof(tracefile),"%s"APOS_HA_DEVMON_LOG_FILE, tmpConfig.traceDir);
		if (apos_ha_logtrace_init("apos_ha_devmond", tracefile, tmpConfig.traceMask) != 0) {
			HA_LG_ER("%s(): Failed to initialize the tracing subsystem", __func__);
			rCode=-1;
		}
	}

	/* Copy the HA_DEVMON_ConfigT structure into m_Config */
	if (rCode == 0) {
    	m_Config.traceMask 		= tmpConfig.traceMask;
    	ACE_OS::strcpy(m_Config.traceDir, tmpConfig.traceDir);
		m_Config.rebootTmout    = tmpConfig.rebootTmout;
		m_Config.queryInterval	= tmpConfig.queryInterval;
		m_Config.callbackTmout  = tmpConfig.callbackTmout;
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------

void HA_DEVMON_Config::dumpConfig()
{
	HA_TRACE_1("----------------------------------------------------------");
	HA_TRACE_1("- Dumping Configuration Parameters:");
	HA_TRACE_1("----------------------------------------------------------");
	HA_TRACE_1("- m_Config.traceMask    : %x",   (unsigned int)m_Config.traceMask);
	HA_TRACE_1("- m_Config.traceDir     : %s",   m_Config.traceDir);
	HA_TRACE_1("- m_Config.rebootTmout  : %d",   m_Config.rebootTmout);
	HA_TRACE_1("- m_Config.queryInterval: %x",	 m_Config.queryInterval);
	HA_TRACE_1("- m_Config.callbackTmout: %d",   m_Config.callbackTmout);
	HA_TRACE_1("----------------------------------------------------------");
}
//-------------------------------------------------------------------------
