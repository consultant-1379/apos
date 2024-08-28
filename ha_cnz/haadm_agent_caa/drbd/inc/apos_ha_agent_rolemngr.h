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
 * @file apos_ha_agent_rolemngr.h
 *
 * @brief
 * 
 * This class is responsible for AGENT
 * functionality on active node 
 *
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/
#ifndef APOS_HA_AGENT_ROLEMNGR_H
#define APOS_HA_AGENT_ROLEMNGR_H

#include <iostream>
#include <sstream>
#include <ace/Task_T.h>
#include <ace/ACE.h>
#include <sys/poll.h>
#include <ace/Sig_Handler.h>
#include <ACS_APGCC_AmfTypes.h>
#include <ace/Reactor.h>

#include "apos_ha_agent_types.h"
#include "apos_ha_agent_arping.h"
#include "apos_ha_agent_ping.h"
#include "apos_ha_agent_ndisc.h"
#include "apos_ha_agent_drbdmgr.h"
#include "apos_ha_agent_immOm.h"
#include "apos_ha_agent_lockFile.h"
#include "apos_ha_agent_drbdmon.h"
#include "apos_ha_agent_powerOff.h"
#include "apos_ha_agent_hamanager.h"
#include "apos_ha_logtrace.h"
#include "apos_ha_reactorrunner.h"


/*===============================================================
		DIRECTIVE DECLARATION SECTION
=================================================================*/
class Global;
class HA_AGENT_Arping;
class HA_AGENT_Ping;
class HA_AGENT_ndisc;
class HA_AGENT_DRBDMgr;
class HA_AGENT_LFile;
class HA_AGENT_ImmOm;
class APOS_HA_ReactorRunner;
class HA_AGENT_PWROff;
class HA_AGENT_DRBDMon;

class HA_AGENT_RoleMgr:public ACE_Task<ACE_SYNCH> 
{
  private:

	Global* m_globalInstance;
	bool m_regHndlr;
	HA_AGENT_Arping* m_arpObj;
	HA_AGENT_Ping* m_pingObj;
	HA_AGENT_ndisc* m_ndiscObj;
	HA_AGENT_DRBDMgr* m_drbdObj;
	HA_AGENT_LFile* m_fileObj;
	HA_AGENT_ImmOm* m_immObj;
	HA_AGENT_PWROff* m_pwrOffObj;
	HA_AGENT_DRBDMon* m_DMObj;
	APOS_HA_ReactorRunner* m_reactorRunner;
	ACE_HANDLE m_handle;
	bool m_startJobsDone;
	bool m_isVirtual;
	int p_open();
	int p_close();
	int initRoleMgr();
	int splitBrainAlgo();
	int StartJobs();
	int StopJobs();
	int healthCheck();
	int readMsg(HA_DEVMON_MsgT *msg);
	int processMsg(HA_DEVMON_MsgT *msg);
	void dispatch();
    void setHandle(ACE_HANDLE);
	void printMsg(HA_DEVMON_MsgT* msg);

 public:

	HA_AGENT_RoleMgr();
	virtual ~HA_AGENT_RoleMgr();
	ACE_Sig_Handler sig_shutdown_;
	ACE_HANDLE get_handle(void) const;
	int svc();
	int close(u_long);
	int handle_input(ACE_HANDLE fd);
	int handle_close(ACE_HANDLE, ACE_Reactor_Mask mask);
	int handle_signal(int signum,siginfo_t *,ucontext_t *);
	int open(); 
	int close();
	void shutDown_all();
};

#endif

//----------------------------------------------------------------------------
