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
 * @file apos_ha_agent_drbdmgr.h
 *
 * @brief
 * 
 * This is the main class that handles drbd configuration for data disks. 
 * It is an active object that is started by calling drbdStartJobs()
 * and then stopped by calling drbdStopJobs()
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_DRBDMGR_H
#define APOS_HA_AGENT_DRBDMGR_H

#include <ace/ACE.h>
#include <ace/Process.h>

#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_utils.h"

class Global;

class HA_AGENT_DRBDMgr
{
  
  public:	

	HA_AGENT_DRBDMgr();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_DRBDMgr();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	int init();
	// Description:
	//    initilaizer. Initializes the variables
	// Parameters:
	//    none
	// Return value:
	//    none

	int drbdStartJobs();
	// Description:
	//    Perform start jobs of drbd
	// Parameters:
	//    none
	// Return value:
	//    0		success
	//	 -1		failure

	int drbdStopJobs();
	// Description:
	//    Perform stop jobs of drbd
	// Parameters:
	//    none
	// Return value:
	//    0		success
	//	 -1		failure

	int drbdHealth(bool);
	// Description:
	//    Checks local drbd health
	// Parameters:
	//    none
	// Return value:
	//    0     success
	//   -1     failure

	int processDataFromDevMon(unsigned char* buffer);
	// Description:
	//    Processes data from devmon
	// Parameters:
	//    none
	// Return value:
	//    none	
	
	int activate();

	void set_assemble_force(bool flag);

  private:

	int assemble();

	int disable();

	int setMipAddrs();

	int usetMipAddrs();
    
    	int _execlp(const char *str);

	int aposJobs();

	Global* m_globalInstance;
	ACE_TCHAR* m_aposOpts;
	bool m_assemble_force;
    
};

#endif
// -------------------------------------------------------------------------
