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
 * @file apos_ha_devmon_hamanager.h
 *
 * @brief
 *
 * This class handles all HA callbacks
 *
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/
#ifndef APOS_HA_DEVMON_HAMANAGER_H
#define APOS_HA_DEVMON_HAMANAGER_H

#include <unistd.h>
#include <syslog.h>
#include "apos_ha_devmon_amfclass.h"
#include "apos_ha_devmon_adm.h"
#include "apos_ha_logtrace.h" 
 
class HA_DEVMON_Adm;

class devmonHAClass: public APOS_HA_Devmon_AmfClass 
{
 public:
	 
	devmonHAClass(const char* daemon_name, const char* user);
	// Description:
    //  Invokes parent constructor for daemonize
    // Parameters:
    //  none
    // Return value:
    //  none
	~devmonHAClass();
	// Description:
    //  Destructor frees all the memory
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	// Description:
    //  
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performComponentHealthCheck(void);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performComponentTerminateJobs(void);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performComponentRemoveJobs (void);
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType performApplicationShutdownJobs(void);

 private:

	ACS_APGCC_ReturnType activateApp();
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	ACS_APGCC_ReturnType passifyApp();
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none
	HA_DEVMON_Adm *m_admObj;
	ACE_Thread_Mutex m_admLock; // Mutex to serialize access to m_Adm Classes
}; 

#endif /* APOS_HA_DEVMON_HAMANAGER_H */
