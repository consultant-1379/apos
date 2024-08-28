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
 * @file apos_ha_devmon_adm.h
 *
 * @brief
 * This is the main class to be run in DEVMON. It is an active object that is
 * started by calling start() and then stopped by calling stop().
 * The thread is run in svc().
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_DEVMON_ADM_H
#define APOS_HA_DEVMON_ADM_H

#include <syslog.h>
#include <ace/Task_T.h>
#include <ace/OS.h>
#include <ace/Sig_Handler.h>
#include "apos_ha_devmon_types.h"
#include "apos_ha_devmon_global.h"
#include "apos_ha_devmon_drbdmon.h"
#include "apos_ha_devmon_drbdrecovery.h" 
#include "apos_ha_devmon_hamanager.h"
#include "apos_ha_logtrace.h"

class devmonHAClass;
class Global;
class HA_DEVMON_DRBDMon;
class HA_DEVMON_DRBDRecovery;
//------------------------------------------------------------------------
class HA_DEVMON_Adm: public ACE_Task<ACE_SYNCH> 
{
	
   public:
		
	HA_DEVMON_Adm();
	~HA_DEVMON_Adm();
	ACE_Sig_Handler sig_shutdown_;
	int close(u_long);
	int handle_signal(int signum,siginfo_t *,ucontext_t *);
	int start(devmonHAClass*);
	int start(int argc, char* argv[]);
	void stop();
	int svc();

   private:

	Global* m_globalInstance;
	devmonHAClass* m_haObj;
	HA_DEVMON_DRBDMon* m_dMonObj;
	HA_DEVMON_DRBDRecovery* m_dRcvyObj;
	HA_DEVMON_DRBDMon* DRBDMon();
	HA_DEVMON_DRBDRecovery* DRBDRecovery();
	void shutDown_all();
	int initClasses();
	void readConfig_r();
									
}; 

#endif /* APOS_HA_DEVMON_ADM_H */
//------------------------------------------------------------------------
