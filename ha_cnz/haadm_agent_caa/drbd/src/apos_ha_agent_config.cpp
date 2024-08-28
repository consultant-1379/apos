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
 * @file apos_ha_agent_config.cpp
 *
 * @brief
 *
 * This the configuration class of agent. It reads the configuration parameters
 * from config file and returns config object
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_config.h"

//-------------------------------------------------------------------------
HA_AGENT_Config::HA_AGENT_Config():
m_globalInstance(HA_AGENT_Global::instance())
{	
	HA_TRACE_ENTER();
	m_Config.xtimes					=	0;
	m_Config.ysecs 					=	0;
	m_Config.traceMask				=	0;
	m_Config.rebootTmout			=	0;
	m_Config.traceDir				=	const_cast<ACE_TCHAR*>("");
	m_Config.rebootCount			=	0;
	m_Config.callbackTmout			=	0;
	m_Config.drbdSupervisionIntvl	=	0;
	m_Config.mipInfo.ipAddress 	=   0;
	m_Config.mipInfo.interface	=	0;
	m_Config.mipInfo.size		=	0;

	/* init Class with defaults */
	this->initConfig();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_Config::~HA_AGENT_Config()
{
	HA_TRACE_ENTER();
	delete[] m_Config.traceDir;
	if( m_Config.mipInfo.ipAddress !=0 ){
		for (unsigned int cntr=0; cntr < m_Config.mipInfo.size; cntr++)
		{
			delete[] m_Config.mipInfo.ipAddress[cntr];
		}
		delete[] m_Config.mipInfo.ipAddress;
		m_Config.mipInfo.ipAddress = 0;
	}
	if( m_Config.mipInfo.interface !=0 ){
		for (unsigned int cntr=0; cntr < m_Config.mipInfo.size; cntr++)
		{
			delete[] m_Config.mipInfo.interface[cntr];
		}
		delete[] m_Config.mipInfo.interface;
		m_Config.mipInfo.interface = 0;
	}
			
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_Config::initConfig()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	/* Initialize structure data with defaults */
	m_Config.xtimes					=	APOS_HA_DFLT_X_TIMES;
	m_Config.ysecs					=	APOS_HA_DFLT_Y_MSECS;
	m_Config.traceMask				=	APOS_HA_DFLT_TRCE_CATGY;
	m_Config.rebootTmout			=	APOS_HA_DFLT_REBOOT_TMOUT;
	m_Config.rebootCount			=	APOS_HA_DFLT_REBOOT_COUNT;
	m_Config.callbackTmout			=	APOS_HA_DFLT_CALLBACK_TMOUT;
	m_Config.drbdSupervisionIntvl	=	APOS_HA_DFLT_DRBD_SUPERVISION_INTVL;

	ACE_NEW_NORETURN(this->m_Config.traceDir, ACE_TCHAR[256]);
   	if (0 == this->m_Config.traceDir) {
   		HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.traceDir", __func__);
		rCode=-1;
    } else {
		ACE_OS::memset(m_Config.traceDir, 0, sizeof(ACE_TCHAR[256])-1);
		ACE_OS::strcpy(m_Config.traceDir,APOS_HA_DFLT_TRCE_DIR);
	}

	if (rCode == 0) {
		this->m_Config.mipInfo.size=0;
		this->m_Config.mipInfo.ipAddress=0;
		this->m_Config.mipInfo.interface=0;
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Config::readConfig()
{
	HA_TRACE_ENTER();
	FILE *fp;
	ACE_TCHAR buff[100];
	ACE_OS::memset(buff, 0, sizeof(buff));	
	ACE_TCHAR *ch=NULL, *ch1=NULL, *tmp=NULL;
	ACE_INT32 rCode=0;
	bool file_open=true;
	std::string empStr("");

	HA_AGENT_ConfigT tmpConfig;
	ACE_OS::memset(&tmpConfig, 0, sizeof(tmpConfig));

	fp = ACE_OS::fopen(APOS_HA_FILE_CNFG, "r");
	if (fp == NULL) {
		HA_LG_ER("Error! fopen FAILED to read [ %s ]",APOS_HA_FILE_CNFG);
		rCode=-1;
		file_open=false;
	}	

	/* initialize the tmpConfig structure to surpress the warnings */
	/* ----------- initialize begin ------------------------ */
	tmpConfig.xtimes				=	APOS_HA_DFLT_X_TIMES;
	tmpConfig.ysecs					=	APOS_HA_DFLT_Y_MSECS;
	tmpConfig.traceMask 			=	APOS_HA_DFLT_TRCE_CATGY;
	tmpConfig.rebootTmout			=	APOS_HA_DFLT_REBOOT_TMOUT;
	tmpConfig.rebootCount			=	APOS_HA_DFLT_REBOOT_COUNT;

	ACE_NEW_NORETURN(tmpConfig.traceDir, ACE_TCHAR[256]);
   	if (0 == tmpConfig.traceDir) {
   		HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory tmpConfig.traceDir", __func__);
		rCode=-1;
    } else {
		ACE_OS::memset(tmpConfig.traceDir, 0, sizeof(ACE_TCHAR[256])-1);
		ACE_OS::strcpy(tmpConfig.traceDir,APOS_HA_DFLT_TRCE_DIR);
	}
	if (rCode == 0) {
		tmpConfig.mipInfo.size=0;
		tmpConfig.mipInfo.ipAddress=0;
		tmpConfig.mipInfo.interface=0;
	}

	tmpConfig.callbackTmout			=	APOS_HA_DFLT_CALLBACK_TMOUT;
	tmpConfig.drbdSupervisionIntvl	=	APOS_HA_DFLT_DRBD_SUPERVISION_INTVL;
	/* ----------- initialize end -------------------------- */

	if (rCode == 0) 
	{
		while(ACE_OS::fgets(buff, sizeof(buff), fp) != NULL)
		{
			/* Skip Comments and tab spaces in the beginning */
			ch = buff;
			while (*ch == ' ' || *ch == '\t')
				ch++;
                
			if (*ch == '#' || *ch == '\n')
				continue;
		
			/* In case if we have # somewhere in this line lets truncate the string from there */
			if ((ch1 = ACE_OS::strchr(ch, '#')) != NULL) {
				*ch1++ = '\n';
				*ch1 = '\0';
			}

			if (ACE_OS::strstr(ch, "AGNT_X_TIMES=") != NULL){
				tmp=getToken(ch, '=');
				tmpConfig.xtimes = atoi(tmp);
            	HA_TRACE("Setting X_Times to [%d]", tmpConfig.xtimes);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_Y_MSECS=") != NULL){
            	tmp=getToken(ch, '=');
            	tmpConfig.ysecs = atoi(tmp);
            	HA_TRACE("Setting Y_Msecs to [%d] from next iteration", tmpConfig.ysecs);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_REBOOT_TMOUT=") != NULL){
            	tmp=getToken(ch, '=');
				tmpConfig.rebootTmout= atoi(tmp);
            	HA_TRACE("Setting Reboot Timeout to [%d]", tmpConfig.rebootTmout);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_REBOOT_COUNT=") != NULL){
            	tmp=getToken(ch, '=');
				tmpConfig.rebootCount= atoi(tmp);
            	HA_TRACE("Setting Reboot Count to [%d]", tmpConfig.rebootCount);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_CALLBACK_TMOUT=") != NULL){
            	tmp=getToken(ch, '=');
				tmpConfig.callbackTmout= atoi(tmp);
            	HA_TRACE("Setting Callback timeout to [%d]", tmpConfig.callbackTmout);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_DRBD_SUPERVISION_INTVL=") != NULL){
            	tmp=getToken(ch, '=');
				tmpConfig.drbdSupervisionIntvl= atoi(tmp);
            	HA_TRACE("Setting drbdSupervisionIntvl to [%d]", tmpConfig.drbdSupervisionIntvl);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_TRACE_CATGY=") != NULL){
            	tmp=getToken(ch, '=');
				tmpConfig.traceMask=strtoull(tmp, NULL, 16);
            	HA_TRACE("Setting traceMask to [%s]", tmp);
        	}

        	if (ACE_OS::strstr(ch, "AGNT_TRACE_DIR=") != NULL){
            	tmp=getToken(ch, '=');
        		ACE_OS::strcpy(tmpConfig.traceDir, tmp);
           		HA_TRACE("Setting traceDir to [%s]", tmpConfig.traceDir);
    		}
    	}
	}
	if (rCode == 0) {
		if (initLog(tmpConfig) < 0) {
			HA_LG_ER("%s(): initializing tracing subsystem failed", __func__);
			rCode=-1;
		}
	}	
	if (file_open){
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
ACE_TCHAR* HA_AGENT_Config::getToken(char *str, unsigned char tok)
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
int HA_AGENT_Config::initLog(HA_AGENT_ConfigT tmpConfig) 
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
		snprintf(tracefile, sizeof(tracefile),"%s"APOS_HA_AGENT_LOG_FILE, tmpConfig.traceDir);
		if (apos_ha_logtrace_init("apos_ha_rdeagentd", tracefile, tmpConfig.traceMask) != 0) {
			HA_LG_ER("%s(): Failed to initialize the tracing subsystem", __func__);
			rCode=-1;
		}
	}

	/* Copy the HA_AGENT_ConfigT structure into m_Config */
	if (rCode == 0) {
		m_Config.xtimes 		= tmpConfig.xtimes;
    	m_Config.ysecs 			= tmpConfig.ysecs;
    	m_Config.traceMask 		= tmpConfig.traceMask;
    	m_Config.rebootTmout 	= tmpConfig.rebootTmout;
    	m_Config.rebootCount 	= tmpConfig.rebootCount;
    	ACE_OS::strcpy(m_Config.traceDir, tmpConfig.traceDir);
    	m_Config.callbackTmout 	= tmpConfig.callbackTmout;
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Config::readMips()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	char *mip_info=0;

	char *Cmd[3]={0};
	ACE_NEW_NORETURN(Cmd[0], ACE_TCHAR[256]);
	if (Cmd[0] == NULL) {
		HA_LG_ER("%s(): Memory allocation failed for Cmd[0]", __func__);
		rCode=-1;
	} else {
		strcpy(Cmd[0], APOS_HA_CMD_HA_OPERATIONS);
	}
	if (rCode==0) {
		ACE_NEW_NORETURN(Cmd[1], ACE_TCHAR[256]);
		if (Cmd[1] == NULL) {
			HA_LG_ER("%s(): Memory allocation failed for Cmd[0]", __func__);
			rCode=-1;
		} 
	}

	/* get the mip info*/
	if (rCode == 0) {
		ACE_OS::memset(Cmd[1], 0, sizeof(ACE_TCHAR[256])-1);
		strcpy(Cmd[1], APOS_HA_CMD_GET_MIP_INFO_OPTS);

		rCode =  m_globalInstance->Utils()->_execvp(Cmd, &mip_info);
		if (rCode != 0) {
			HA_LG_ER("%s(): failed to get mip info with errCode: %d", __func__, rCode);
			rCode=-1;
		}
	}
	
	if (rCode == 0) {
		char *pch=mip_info;
		while (*pch  != '\0') {
			if (*pch == '\n') {
				 this->m_Config.mipInfo.size++;
			}
			pch++;
		}
        ACE_NEW_NORETURN(this->m_Config.mipInfo.ipAddress, ACE_TCHAR*[this->m_Config.mipInfo.size]);
        if (0 == this->m_Config.mipInfo.ipAddress) {
            HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.mipInfo.ipAddress", __func__);
            rCode=-1;
        }
		if (rCode == 0) {
			ACE_NEW_NORETURN(this->m_Config.mipInfo.interface, ACE_TCHAR*[this->m_Config.mipInfo.size]);
			if (0 == this->m_Config.mipInfo.interface) {
				HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.mipInfo.interface", __func__);
				rCode=-1;
			}
		}

		if (rCode == 0) {
			pch=mip_info;
			int cntr=0;

			while( *pch != '\0' && rCode == 0)  {
				char addr[256]={0} , intf[256]={0};
				int pos=0;
				while (*pch != ' ') {
					addr[pos++] = *pch++;
				}
				addr[pos] = '\0';
				pos=0;
				pch++;
				while (*pch !=  '\n') {
					intf[pos++] = *pch++;
				}
				intf[pos]= '\0';

				ACE_NEW_NORETURN(this->m_Config.mipInfo.ipAddress[cntr], ACE_TCHAR[256]);
                if (0 == this->m_Config.mipInfo.ipAddress[cntr]) {
                    HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.mipInfo.ipAddress[cntr]", __func__);
                    rCode=-1;
                } else {
                    ACE_OS::memset(m_Config.mipInfo.ipAddress[cntr], 0, sizeof(ACE_TCHAR[256])-1);
                    ACE_OS::strcpy(m_Config.mipInfo.ipAddress[cntr], addr);
					HA_TRACE("%s(): Setting m_Config.mipInfo.ipAddress[%d]:%s", __func__, cntr, addr);
                }
				if (rCode == 0) {
					ACE_NEW_NORETURN(this->m_Config.mipInfo.interface[cntr], ACE_TCHAR[256]);
					if (0 == this->m_Config.mipInfo.interface[cntr]) {
						HA_LG_ER("%s(): MEMORY PROBLEM: Could not allocate memory m_Config.mipInfo.interface[cntr]", __func__);
						rCode=-1;
					} else {
						ACE_OS::memset(m_Config.mipInfo.interface[cntr], 0, sizeof(ACE_TCHAR[256])-1);
						ACE_OS::strcpy(m_Config.mipInfo.interface[cntr], intf);
						HA_TRACE("%s(): Setting m_Config.mipInfo.interface[%d]:%s", __func__, cntr, intf);
					}
				}
				cntr++;
				pch++;
			}
		}
	}
	if( Cmd[0] != 0) {
		delete[] Cmd[0];
		Cmd[0] = 0;
	}
	if (Cmd[1] != 0) {
		delete[] Cmd[1];
		Cmd[1]=0;
	}
	if (mip_info != 0) {
		free(mip_info);
		mip_info=0;
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
void HA_AGENT_Config::dumpConfig()
{
	HA_TRACE_1("----------------------------------------------------------");
	HA_TRACE_1("- Dumping Configuration Parameters:");
	HA_TRACE_1("----------------------------------------------------------");
	HA_TRACE_1("- m_Config.xtimes       			: %d",   m_Config.xtimes);
	HA_TRACE_1("- m_Config.ysecs        			: %d",   m_Config.ysecs);
	HA_TRACE_1("- m_Config.traceMask    			: %x",   (unsigned int)m_Config.traceMask);
	HA_TRACE_1("- m_Config.rebootTmout  			: %d",   m_Config.rebootTmout);
	HA_TRACE_1("- m_Config.rebootCount  			: %d",   m_Config.rebootCount);
	HA_TRACE_1("- m_Config.traceDir     			: %s",   m_Config.traceDir);
	HA_TRACE_1("- m_Config.callbackTmout			: %d",   m_Config.callbackTmout);
	HA_TRACE_1("- m_Config.drbdSupervisionIntvl		: %d",	 m_Config.drbdSupervisionIntvl);
	HA_TRACE_1("- m_Config.mipInfo.size			: %d",   m_Config.mipInfo.size);
	for ( unsigned int cntr=0; cntr < m_Config.mipInfo.size; cntr++ )
	{
		HA_TRACE_1("- m_Config.mipInfo.ipAddress[cntr]	:	%s", m_Config.mipInfo.ipAddress[cntr]);
		HA_TRACE_1("- m_Config.mipInfo.interface[cntr]	:	%s", m_Config.mipInfo.interface[cntr]);
	}
	HA_TRACE_1("----------------------------------------------------------");
}
//-------------------------------------------------------------------------

