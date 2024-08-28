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
 * @file apos_ha_agent_poweroff.h
 *
 * @brief
 * 
 * This class is used to handle the poweroff cases.
 *
 * @author Tanu Aggarwal (xtanagg)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_PWROFF_H
#define APOS_HA_AGENT_PWROFF_H

#include <ace/ACE.h>
#include <ace/Reactor.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"

class Global;

class HA_AGENT_PWROff
{
  
  public:	

	HA_AGENT_PWROff();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	virtual ~HA_AGENT_PWROff();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	bool get_persis_info(HA_AGENT_PersistantInfoT& persisInfo);
	// Description:
	//    check info  from persistent file.
	// Parameters:
	//    HA_AGENT_PersistantInfoT : out
	// Return value:
	//    bool

	bool write_persis_info(const HA_AGENT_PersistantInfoT& persisInfo );
	// Description:
	//    write info in persistent file.
	// Parameters:
	//    HA_AGENT_PersistantInfoT : in
	// Return value:
	//    bool

	int drbdinfo(DRBD_InfoT &drbdInfo);
	// Description:
	//    read drbd connection state from /proc/drbd
	// Parameters:
	//    connection state: out
	// Return value:
	//    int

	int peerdrbdinfo(DRBD_InfoT &drbdInfo);
	// Description:
	//    read peer drbd connection state from /proc/drbd
	// Parameters:
	//    connection state: out
	// Return value:
	//    int

	int init();
	// Description:
	// initializes power-off class.
	// Parameters:
	//    none
	// Return value:
	//    int

  private:

	int m_fd;
	HA_AGENT_PersistantInfoT *m_map;
	Global* m_globalInstance;
    
};

#endif

// -------------------------------------------------------------------------
