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
 * @file apos_ha_devmon_drbdmgr.h
 *
 * @brief
 * 
 * This is the main class that handles drbd configuration for data disks.
 * It process the drbd information and takes necessary actions
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_DEVMON_DRBDMGR_H
#define APOS_HA_DEVMON_DRBDMGR_H

#include <ace/ACE.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_devmon_types.h"
#include "apos_ha_devmon_global.h"

class Global;

class HA_DEVMON_DRBDMgr
{
  public:	

	HA_DEVMON_DRBDMgr();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none
	 ~HA_DEVMON_DRBDMgr();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none
	int init();
	// Description:
	//   initialiser. Initilaises all objects
	// Parameters:
	//    none
	// Return value:
	//    none
	int isactive();
	// Description:
	//	 Checks drbd health
	// Parameters:
	//    none
	// Return value:
	//    1     success
	//    0    failure
	int recovery();
   // Description:
   // 	Launches ddmgr recvoery command
   // Parameters:
   // 	none
   // Return value:
   // 	0		success
   // 	-1		failure		
	int isdegraded();
	// Description:
	// 	Checks Disk health
	// Parameters:
	// 	none
	// Return value:
	// 	 1	success	
	// 	 0	failure
	HA_DEVMON_MsgT& fillMsg();
	// Description:
	// Has Information which needs to be sent to agent
	// Parameters:
	// none
	// Return value:
	// Object
	int parse_proc_drbd();
    // Description
    // Process the drbd from /proc/drbd file	
	void reset();
	//Description
	//Resets the class level variables

  private:

	Global* m_globalInstance;
	HA_DEVMON_MsgT m_msgInfo;
	char m_cstate[16];
	char m_ldisk[16];
	char m_role[16];
	char m_rdisk[16];
	char m_diskinfo[256];
};

#endif
// -------------------------------------------------------------------------
