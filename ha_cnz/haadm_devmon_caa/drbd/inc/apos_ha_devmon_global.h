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
 * @file apos_ha_devmon_global.h
 *
 * @brief
 *  
 * A singleton class
 * This class contains all the global declarations used by
 * other HA Devmon classes.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ****************************************************************************/

#ifndef APOS_HA_DEVMON_GLOBAL_H
#define APOS_HA_DEVMON_GLOBAL_H

#include <time.h>
#include <ace/Basic_Types.h>
#include <ace/Manual_Event.h>
#include <ace/Recursive_Thread_Mutex.h>
#include <ace/Singleton.h>
#include <ACS_APGCC_AmfTypes.h>
#include "apos_ha_devmon_drbdmon.h"
#include "apos_ha_devmon_config.h"
#include "apos_ha_devmon_utils.h"
#include "apos_ha_devmon_hamanager.h"
#include "apos_ha_logtrace.h"
#include "apos_ha_devmon_types.h"

#define RELATIVETIME(x)    (ACE_OS::time(NULL) + x)

class ACE_event_t;
class ACE_Message_Block;
class ACE_Time_Value;
class ACE_Reactor;
class ACE_TP_Reactor;
class ACE_Reactor;
class HA_DEVMON_DRBDMon;
class HA_DEVMON_Config;
class HA_DEVMON_DRBDRecovery;
class HA_DEVMON_Utils;
class devmonHAClass;

using namespace std;

//----------------------------------------------------------------------------
// Lets make Global a Singleton
//----------------------------------------------------------------------------
class Global;
typedef ACE_Singleton<Global, ACE_Recursive_Thread_Mutex> HA_DEVMON_Global;

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
	void notifyGlobalShutdown();
	// Send a shutdown message to all registred handlers
	time_t* get_service_start_time();
	// Returns the start time for the service
	ACE_UINT32 get_service_uptime();
	// Returns the uptime for the service in minutes
	HA_DEVMON_DRBDMon* drbdMon();
	// Return pointer to the DRBDMon
	HA_DEVMON_DRBDRecovery* drbdRecovery();
	// Return pointer to the DiskMon
	HA_DEVMON_Utils* Utils();
	// Return pointer to the Utils
	HA_DEVMON_Config* Config();
	// Return pointer to the Config
	devmonHAClass* HAClass();
	// Return pointer to the HAClass	
	void setHaMgr(devmonHAClass* haObj);
	// Maintains global haObj
	bool haMode();
	// returns true if haMode is on
	void haMode(bool flag);
	// sets haMode
	void compRestart();
	// Request CMW to restart ourself.
	void nodefailOver();
	// Request CMW to initiate failOver (slow death :) )
	void nodefailFast();
	// Request CMW to initiate failFast (sudden death of node).
	int fifo_open();
	// open global fifo for communication between agent and devmon
	int fifo_close();
	//close the fifo
	//int write_buffer(void *buffer);
	int write_buffer(HA_DEVMON_MsgT const *);	
	// data to be written on fifo
	void reboot();
	//reboot the node in case of failure
	ACE_HANDLE get_handle(void) const;
    //get an ace_handle object	
	
 private:

	void reset(); // Call to reset state to initial state.
	void setHandle(ACE_HANDLE);
	bool m_shutdownOrdered;
	bool m_haMode;
	HA_DEVMON_DRBDMon* m_dMonObj;
	HA_DEVMON_DRBDRecovery* m_dRcvyObj;
	HA_DEVMON_Utils* m_utilObj;
	HA_DEVMON_Config* m_cngObj;
	devmonHAClass* m_haObj;
	ACE_HANDLE fifo_fd;
	// Serialize access
	ACE_Recursive_Thread_Mutex thread_lock_;
	ACE_Recursive_Thread_Mutex write_lock_;
};

//----------------------------------------------------------------------------
inline 
void Global::setHaMgr(devmonHAClass* haObj)
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
#endif 
