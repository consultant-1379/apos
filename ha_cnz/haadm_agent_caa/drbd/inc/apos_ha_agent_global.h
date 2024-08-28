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
 * @file apos_ha_agent_global.h
 *
 * @brief
 *
 * A singleton class
 * This class contains all the global declarations used by 
 * other HA AGENT classes. 
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ****************************************************************************/

#ifndef APOS_HA_AGENT_GLOBAL_H
#define APOS_HA_AGENT_GLOBAL_H

#include <time.h>
#include <ace/Basic_Types.h>
#include <ace/Manual_Event.h>
#include <ace/Recursive_Thread_Mutex.h>
#include <ace/Singleton.h>
#include <ace/Guard_T.h>
#include <ace/Reactor.h>
#include <ace/TP_Reactor.h>

#include "apos_ha_agent_rolemngr.h"
#include "apos_ha_agent_config.h"
#include "apos_ha_agent_utils.h"
#include "apos_ha_agent_powerOff.h"
#include "apos_ha_agent_hamanager.h"
#include "apos_ha_logtrace.h"
#include <ACS_APGCC_AmfTypes.h>

#define RELATIVETIME(x)    (ACE_OS::time(NULL) + x)

class ACE_event_t;
class ACE_Message_Block;
class ACE_Time_Value;
class ACE_Reactor;
class ACE_TP_Reactor;
class ACE_Reactor;
class HA_AGENT_RoleMgr;
class HA_AGENT_Config;
class HA_AGENT_Utils;
class HA_AGENT_PWROff;
class agentHAClass;

using namespace std;

//----------------------------------------------------------------------------
// Lets make Global a Singleton
//----------------------------------------------------------------------------
class Global;
typedef ACE_Singleton<Global, ACE_Recursive_Thread_Mutex> HA_AGENT_Global;

//----------------------------------------------------------------------------
class Global
{

 public:

	Global();

	virtual ~Global();

	void deactivate(); // call to deactivate object

	//=== Access methods ===

	bool shutdown_ordered();
	void shutdown_ordered(bool set);
	// Get/Set if the service is ordered to shutdown

   	ACE_Reactor* reactor();
	
	HA_AGENT_RoleMgr* roleMgr();
	// Return pointer to the RoleMgr

	HA_AGENT_Utils* Utils();
	// Return pointer to the Utils

	HA_AGENT_PWROff* PWROff();

	HA_AGENT_Config* Config();
	// Return pointer to the Config

	agentHAClass* HAClass();
	// Return pointer to the HAClass	

	void setHaMgr(agentHAClass* haObj);
	// Maintains global haObj

	bool haMode();
	// returns true if haMode is on

	void haMode(bool flag);
	// sets haMode

	void setOldhaState(ACS_APGCC_AMF_HA_StateT);
	// sets old hastate

	void setTasksDone(bool flag);
	// sets tasksdone indicator

	int waitOntask();
	// wait for tasksdone indicator to turn on.

	ACS_APGCC_AMF_HA_StateT getOldhaState();
	// gets old hastate

	ACS_APGCC_AMF_HA_StateT getHAState();
	// get hastate

	void compRestart();
	// Request CMW to restart ourself.

	void nodefailOver();
	// Request CMW to initiate failOver (slow death :) )

	void nodefailFast();
	// Request CMW to initiate failFast (sudden death of node).

	void reboot();

	
 private:

	//Internal variables
	//-------------------
	
	void reset(); // Call to reset state to initial state.

	bool m_shutdownOrdered;
	// True if shutdown has been ordered 

	bool m_haMode;

	bool m_tasksDone;

	bool m_compRestart;

	ACS_APGCC_AMF_HA_StateT m_oldhaState;

	HA_AGENT_RoleMgr* m_rMgrObj;
	
	HA_AGENT_Utils* m_utilObj;

	HA_AGENT_PWROff* m_pwrOffObj;
	
	HA_AGENT_Config* m_cngObj;

	agentHAClass* m_haObj;

	// Serialize access
	ACE_Recursive_Thread_Mutex thread_lock_;

	static ACE_Recursive_Thread_Mutex varLock_;
};

//----------------------------------------------------------------------------
inline 
void Global::setHaMgr(agentHAClass* haObj)
{
	m_haObj=haObj;
}

//----------------------------------------------------------------------------
inline
bool Global::haMode()
{
	return this->m_haMode;
}

//----------------------------------------------------------------------------
inline
bool Global::shutdown_ordered()
{
	return this->m_shutdownOrdered;
}	

//----------------------------------------------------------------------------
inline 
void Global::shutdown_ordered(bool ordered)
{
	this->m_shutdownOrdered = ordered;
}

//----------------------------------------------------------------------------
inline
void Global::haMode(bool flag)
{
	this->m_haMode = flag;
}

//----------------------------------------------------------------------------
inline 
void Global::setOldhaState(ACS_APGCC_AMF_HA_StateT OldhaState)
{
	this->m_oldhaState=OldhaState;
}

//----------------------------------------------------------------------------
inline 
ACS_APGCC_AMF_HA_StateT Global::getOldhaState()
{
	return this->m_oldhaState;
}

//----------------------------------------------------------------------------
inline 
void Global::setTasksDone(bool flag)
{
	this->m_tasksDone=flag;
}

#endif 

