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
 * @file apos_ha_agent_hamanger.h
 *
 * @brief
 *
 * This class handles all the HA callbacks. 
 *
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/
#ifndef APOS_HA_AGENT_HAMANAGER_H
#define APOS_HA_AGENT_HAMANAGER_H

#include <unistd.h>
#include <syslog.h>
#include "apos_ha_agent_amfclass.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_actvAdm.h"
#include "apos_ha_agent_stbyAdm.h"

class HA_AGENT_ACTVAdm;
class HA_AGENT_STNBYAdm;
class Global;

class agentHAClass: public APOS_HA_RdeAgent_AmfClass 
{

 public:
	agentHAClass(const char* daemon_name, const char* user);
	// Description:
    //  Invokes parent constructor for daemonize
    // Parameters:
    //  none
    // Return value:
    //  none

	~agentHAClass();
	// Description:
    //  Destructor
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

	ACS_APGCC_ReturnType stopApp();
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none

	ACS_APGCC_ReturnType stopStndby();
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none

	ACS_APGCC_ReturnType stopActv();
	// Description:
    //
    // Parameters:
    //  none
    // Return value:
    //  none

	HA_AGENT_ACTVAdm  *m_actvAdmObj;
	HA_AGENT_STNBYAdm *m_stbyAdmObj;
	ACE_Thread_Mutex m_admLock; // Mutex to serialize access to m_Adm Classes
	Global* m_globalInstance;
}; 

#endif /* APOS_HA_AGENT_HAMANAGER_H */

