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
 ----------------------------------------------------------------------*//*
 *
 * @file apos_ha_agent_actvAdm.h
 *
 * @brief
 * This is the main class to be run in AGENT. It is an active object that is
 * started by calling start() and then stopped by calling stop().
 * The thread is run in svc().
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_ACTVADM_H
#define APOS_HA_AGENT_ACTVADM_H

#include <syslog.h>
#include <ace/Task_T.h>
#include <ace/OS.h>
#include <ace/Reactor.h>
#include <ace/Sig_Handler.h>
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_rolemngr.h"
#include "apos_ha_agent_hamanager.h"
#include "apos_ha_logtrace.h"

class agentHAClass;
class Global;

//------------------------------------------------------------------------

class HA_AGENT_ACTVAdm: public ACE_Task<ACE_SYNCH> 
{

   private:
	
	Global* m_globalInstance;
	agentHAClass* m_haObj;
	int startRoleMgr();
	void shutDown_all();
	int initClasses();
	void readConfig_r();

   public:

	HA_AGENT_ACTVAdm();
	~HA_AGENT_ACTVAdm();
	
	ACE_Sig_Handler sig_shutdown_;
	int close(u_long);
	int handle_signal(int signum,siginfo_t *,ucontext_t *);
	int start(agentHAClass*);
	int start(int argc, char* argv[]);
	void stop();
	int svc();
}; 

#endif /* APOS_HA_AGENT_ADM_H */
//------------------------------------------------------------------------

