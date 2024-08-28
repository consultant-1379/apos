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
 * @file apos_ha_agent_lockFile.h
 *
 * @brief
 * 
 * This class creates and removes the lock file for AGENT. 
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_LFile_H
#define APOS_HA_AGENT_LFile_H

#include <ace/ACE.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"

class HA_AGENT_LFile
{
  
  public:	

	HA_AGENT_LFile();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_LFile();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	int LFile();
	// Description:
	//    creates the lock file
	// Parameters:
	//    none
	// Return value:
	//    none

	bool LFileExist();
	// Description:
	//    checks if the lock file exists
	// Parameters:
	//    none
	// Return value:
	//    none

	int RMLFile();
	// Description:
	//    removes the lock file
	// Parameters:
	//    none
	// Return value:
	//    none

  private:

};

#endif

// -------------------------------------------------------------------------
