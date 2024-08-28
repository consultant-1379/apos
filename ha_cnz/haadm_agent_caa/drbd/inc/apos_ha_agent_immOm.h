/***************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 -------------------------------------------------------------------------
 *
 * @file apos_ha_agent_imm.h
 *
 * @brief
 * 
 * This class is used for fetching information from IMM using IMM APIs
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_ImmOm_H
#define APOS_HA_AGENT_ImmOm_H

#include <ace/ACE.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"
#include <saImm.h>
#include <saImmOm.h>


class Global;

class HA_AGENT_ImmOm
{
  
  public:	

	HA_AGENT_ImmOm();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_ImmOm();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	bool peerNodeLockd();
	// Description:
	//    Checks whether remote node is locked or not.
	// Parameters:
	//    none
	// Return value:
	//    none
	bool isVirtualNode();
	// Description:
	//    Returns whether Node environment is VIRTUALIZED
	// Parameters:
	//    none
	// Return value:
	//    true, if node architecture is VIRTUAL
	//	  false, if node architecture is NATIVE
  private:

	Global* m_globalInstance;
    
};

#endif

// -------------------------------------------------------------------------
