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
 * @file apos_ha_agent_tipc.h
 *
 * @brief
 *
 * This class handles the tipc communication with other node. 
 * 
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_TIPC_H
#define APOS_HA_AGENT_TIPC_H

#include <errno.h>
#include <sys/ioctl.h>
#include <linux/tipc.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <syslog.h>
#include <poll.h>
#include <string.h>
#include <stdio.h>
#include <ace/ACE.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"

class HA_AGENT_Tipc 
{

 public:

	HA_AGENT_Tipc();
	// Description:
	// 	Default constructor
	// Parameters:
	//	none
	// Return value:
	// 	none

	~HA_AGENT_Tipc(){};
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//

	int getfd();
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//

	int init(ACE_INT32 node_id);
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//
	
	int msg_init(ACE_INT32 node_id);
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//

	int query_topsrv(ACE_INT32 node_id, ACE_INT32 &Is_Published);
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//

	int topsrv_handler();
	// Description:
	// 	Destructor. Releases all allocated memory.
	// Parameters:
	// 	none
	// Return value:
	// 	none
	// Additional information:
	//

	bool tipc_config();
	// Description:
	//  Checks for tipc configuration of peer node
	// Parameters:
	//  none
	// Return value:
	//  true	if peer node is up
	//  false 	Otherwise
	// Additional information:
	//


 private:

	int sock_sd;
	int bind_sd;

	struct l_tipc_addr {
		unsigned long type;
		unsigned long instance;
	};

	int create_addr(struct l_tipc_addr &t_addr, ACE_INT32 node_id);
	// Description:
	// 	creates the tipc address
	// Parameters:
	// 	t_addr: tipc address structure
	//	node_id: node id 
	// Return value:
	// Additional information:
	//

	int subscribe(struct l_tipc_addr t_addr);
	// Description:
	// 	subscribes to the tipc address
	// Parameters:
	//	none
	// Return value:
	// 	none
	// Additional information:
	//

};

//----------------------------------------------------------------------------
inline
int 
HA_AGENT_Tipc::getfd()
{
	return this->sock_sd;
}
#endif 
//----------------------------------------------------------------------------
