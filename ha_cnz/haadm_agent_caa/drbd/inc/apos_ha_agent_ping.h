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
 * This class is used to send/receive ping request/response 
 * to/from nbi Address.
 *
 * @author Sankara Jayanth (xsansud)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_PING_H
#define APOS_HA_AGENT_PING_H

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
#include <netinet/ip_icmp.h>
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

class HA_AGENT_Ping
{
  
  public:	
	HA_AGENT_Ping();	// HA_AGENT_Ping Constructor
	~HA_AGENT_Ping();	// HA_AGENT_Ping Destructor

	/*
	 * Ping the destination and determine whether <IP address> is reachable from <Interface name>.
	 *
	 * Parameters	: 	IP address, Interface name
	 * Return Value	:	true, if ipAddr is reachable via interface
	 * 					false, if ipAddr is not reachable via interface
	 */
	bool ping(const char *ipAddr, const char *interface);

	/*
	 * Initialize the socket, packet and address structures used for sending and receiving ICMP packets.
	 * Parameters	: 	IP address, Interface name
	 * Return Value	:	true, if ipAddr is reachable via interface
	 * 					false, if ipAddr is not reachable via interface
	 */
	int init(const char *ipAddr, const char *interface);

  private:
	/*
	 * Send an ICMP_ECHO packet to destination address and receive the response.
	 * Parameters	:	Ping Sequence Number
	 * Return Value	:	true, if ping send and receive are successful i.e destination is reachable
	 * 					false, if destination is not reachable
	 */
	int send_ping(const int pingSeqNum);
	int mipInterface(const char *interface);
	int set_destaddr(const char *interface);
	uint16_t checksum(uint16_t *buffer = NULL, unsigned len = 0);		//default values to surpress code-checker warning

	Global* m_globalInstance;
	HA_AGENT_ConfigT m_config;
	struct in_addr m_src;
	struct in_addr m_dst;
	int m_skfd;
};
#endif
