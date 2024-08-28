/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2019
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_agent_ndisc.h
 *
 * @brief
 * 
 * This class is used to send/receive neighbour discovery request/response 
 * to/from nbi Address.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_NDISC_H
#define APOS_HA_AGENT_NDISC_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h> /* div() */
#include <inttypes.h> /* uint8_t */
#include <limits.h> /* UINT_MAX */
#include <locale.h>
#include <stdbool.h>

#include <errno.h> /* EMFILE */
#include <sys/types.h>
#include <unistd.h> /* close() */
#include <time.h> /* clock_gettime() */
#include <poll.h> /* poll() */
#include <sys/socket.h>
#include <sys/uio.h>
#include <fcntl.h>

#include "gettime.h"

#include <netdb.h> /* getaddrinfo() */
#include <arpa/inet.h> /* inet_ntop() */
#include <net/if.h> /* if_nametoindex() */
//#include <net/if_dl.h> /* Link-Level sockaddr structure sockaddr_dl */
#include <ifaddrs.h> /* getifaddrs and freeifaddrs*/

#include <netinet/in.h>
#include <netinet/icmp6.h>

#ifndef IPV6_RECVHOPLIMIT
# define IPV6_RECVHOPLIMIT IPV6_HOPLIMIT
#endif

#include "apos_ha_logtrace.h"
#include "apos_ha_agent_utils.h"
#include "apos_ha_agent_global.h"
#include "apos_ha_agent_types.h"

using namespace std;

const uint8_t nd_type_advert = ND_NEIGHBOR_ADVERT;

typedef struct
{
  struct nd_neighbor_solicit hdr;
  struct nd_opt_hdr opt;
  uint8_t hw_addr[6];
} solicit_packet;

class Global;

class HA_AGENT_ndisc
{
  
  public:	

	HA_AGENT_ndisc();
	// Description:
    //    Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_ndisc();
	// Description:
    //    Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	bool ndisc(const char *ipaddress, const char *interface);
	// Description:
	//    send an arp packet on cluster ip
	// Parameters:
	//    IP Address, Interface
	// Return value:
	//    true 	if reply is received
  //    false if not responding

  private:

	int init(const char *ipaddress);
	// Description:
  //    Initialise the sender and reciever.
  // Parameters:
	//    IP Address, Interface
  // Return value:
  //    none

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

	int is_ifup();
	// Description:
  //   checks if the interface is up
  // Parameters:
  //    none
  // Return value:
  //    int

	int setsourceip(const char *src);
	// Description:
  //   populate the source address.
  // Parameters:
  //    none
  // Return value:
  //    int

  int sethoplimit(int value);

  int getipv6byname(const char *name, struct sockaddr_in6 *addr);

  int buildsol(solicit_packet *ns, struct sockaddr_in6 *tgt);
        
  int getmacaddress(uint8_t *addr);

  int printmacaddress(const uint8_t *ptr, size_t len);

  int parseadv(const uint8_t *buf, size_t len);

  int recvfromLL(void *buf, size_t len, int flags,
        struct sockaddr_in6 *addr);

	Global* m_globalInstance;
	HA_AGENT_ConfigT m_config;
	struct sockaddr_in6 *m_tgt;
	const char *m_interface;
	int m_skfd;
};

#endif
// -------------------------------------------------------------------------
