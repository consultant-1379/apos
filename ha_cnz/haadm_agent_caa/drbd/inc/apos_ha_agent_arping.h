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
 * @file apos_ha_agent_arping.h
 *
 * @brief
 * 
 * This class is used to send/receive arping request/response 
 * to/from nbi Address.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_ARPING_H
#define APOS_HA_AGENT_ARPING_H

#include <ace/ACE.h>
#include <ace/Time_Value.h>

#include <net/if.h>
#include <netpacket/packet.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <netinet/in.h>
#include <netinet/ether.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <sys/unistd.h>
#include <sys/socket.h>
#include <stropts.h>
#include <sys/types.h>

#include <netdb.h>
#include <sys/time.h>
#include <sys/syscall.h>
#include <iostream>
#include <string>

#include "apos_ha_logtrace.h"
#include "apos_ha_agent_utils.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_types.h"
using namespace std;


class Global;

class HA_AGENT_Arping
{
  
  public:	

	HA_AGENT_Arping();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_Arping();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	bool arping(const char *ipAddr, const char *interface);
	// Description:
	//    send an arp packet on cluster ip
	// Parameters:
	//    IP Address, Interface
	// Return value:
	//    true 	if reply is received
    //    false if not responding

	int init(const char *ipAddr, const char *interface);
	// Description:
    //    Initialise the sender and reciever.
    // Parameters:
	//    IP Address, Interface
    // Return value:
    //    none

  private:


	int recv_resp();
	// Description:
    //   recieve arping response 
    // Parameters:
    //    none
    // Return value:
    //    int

	int send_req();
	// Description:
    //   send arping request 
    // Parameters:
    //    none
    // Return value:
    //    int

	int mipInterface(const char *ipAddr, const char *interface);
	// Description:
    //   check the mipInterface
    // Parameters:
    //    none
    // Return value:
    //    int

	int set_destaddr(const char *interface);
	// Description:
    //   populate the destination address.
    // Parameters:
    //    none
    // Return value:
    //    int

	int set_srcaddr(const char *interface);
	// Description:
    //   populate the source address.
    // Parameters:
    //    none
    // Return value:
    //    int

	Global* m_globalInstance;
	HA_AGENT_ConfigT m_config;
	struct in_addr m_src;
	struct in_addr m_dst;
	struct sockaddr_ll m_curr;
	struct sockaddr_ll m_peer;
	ACE_HANDLE m_skfd;
};

#endif
// -------------------------------------------------------------------------
