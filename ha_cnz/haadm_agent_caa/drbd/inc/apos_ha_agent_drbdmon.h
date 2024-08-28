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
 * @file apos_ha_agent_drbdmon.h
 *
 * @brief
 * 
 * This class is used to monitor drbd1.
 *
 * @author Tanu Aggarwal (xtanagg)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_DRBDMON_H
#define APOS_HA_AGENT_DRBDMON_H

#include <ace/ACE.h>
#include <ace/Reactor.h>
#include "apos_ha_logtrace.h"

#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_powerOff.h"
#include "apos_ha_reactorrunner.h"
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_global.h"
#include <ace/Reactor.h>


class Global;
class HA_AGENT_PWROff;

class HA_AGENT_DRBDMon:public ACE_Task<ACE_SYNCH>
{
  
  public:	

	HA_AGENT_DRBDMon();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	virtual ~HA_AGENT_DRBDMon();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	void setRebuildInProgress();
	// Description:
	//    Sets Rebuild In Progress flag when DRBD rebuild is in progress. 
	// Parameters:
	//    none
	// Return value:
	//    none


	int svc();
	int close(u_long);
	int open();
	int close();
	int handle_timeout(const ACE_Time_Value&, const void*);


  private:

	int init();
	int superviseDRBD();
	Global* m_globalInstance;
	APOS_HA_ReactorRunner* m_reactorRunner;
	ACE_Reactor* m_reactor;
	HA_AGENT_PWROff* m_pwrOffObj;
	int m_timerid;
	bool m_rebuildInProgress;
    
};

//----------------------------------------------------------------------------
inline
void HA_AGENT_DRBDMon::setRebuildInProgress()
{	
    if (this->m_rebuildInProgress){ 
		this->m_rebuildInProgress=false;
	} else {
		this->m_rebuildInProgress=true;
	}
}

#endif
// -------------------------------------------------------------------------
