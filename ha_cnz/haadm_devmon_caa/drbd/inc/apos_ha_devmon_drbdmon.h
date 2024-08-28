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
 * @file apos_ha_devmon_drbdmon.h
 *
 * @brief
 * 
 * This class is responsible for monitoring of drbd resource 
 * 
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/
#ifndef APOS_HA_DEVMON_DRBDMON_H
#define APOS_HA_DEVMON_DRBDMON_H

#include <iostream>
#include <ace/Task_T.h>
#include <ace/ACE.h>
#include <sys/poll.h>
#include "apos_ha_devmon_types.h"
#include "apos_ha_devmon_global.h"
#include "apos_ha_devmon_hamanager.h"
#include "apos_ha_devmon_drbdmgr.h"
#include "apos_ha_reactorrunner.h"
#include "apos_ha_logtrace.h"

/*===============================================================
		DIRECTIVE DECLARATION SECTION
=================================================================*/
class Global;
class HA_DEVMON_DRBDMgr;
class APOS_HA_ReactorRunner;

class HA_DEVMON_DRBDMon:public ACE_Task<ACE_SYNCH> 
{
 public:

	HA_DEVMON_DRBDMon();
	virtual ~HA_DEVMON_DRBDMon();
	int svc();
	int close(u_long);
	int open(); 
	int close();
	int sendMsg();
	int handle_timeout(const ACE_Time_Value&, const void*);
	
  private:

	Global* m_globalInstance;
	HA_DEVMON_DRBDMgr* m_drbdObj;
	APOS_HA_ReactorRunner* m_reactorRunner;
	ACE_Reactor* m_reactor;
	bool m_sendMsg;
	int m_timerid;
	int initDRBDMon();
	int healthCheck();
};

#endif

//----------------------------------------------------------------------------
