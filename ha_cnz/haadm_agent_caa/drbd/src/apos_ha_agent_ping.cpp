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
  * @file apos_HA_AGENT_Ping.cpp
  *
  * @brief
  *
  * This class is used to send/receive arping request/response
  * to/from mip Address.
  *
  * @author Malangsha Shaik (xmalsha)
  *
 -------------------------------------------------------------------------*/
#include <apos_ha_agent_ping.h>
#define	DEFDATALEN	(64 - ICMP_MINLEN)
#define	MAXIPLEN	60
#define	MAXICMPLEN	76
#define	MAXPACKET	(65536 - 60 - ICMP_MINLEN)

//-------------------------------------------------------------------------
HA_AGENT_Ping::HA_AGENT_Ping():
m_globalInstance(HA_AGENT_Global::instance()),
m_config()
{
	HA_TRACE_ENTER();
	m_skfd = -1;
	memset(&m_dst,  0, sizeof(struct in_addr));
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_Ping::~HA_AGENT_Ping()
{
	HA_TRACE_ENTER();
	if (m_skfd == -1)
		close(m_skfd);
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_Ping::init(const char *ipAddr, const char *interface)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode = 0;

	//Get the configuration object.
	m_config = m_globalInstance->Config()->getConfig();
	m_skfd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
	if (m_skfd == -1)
	{
		HA_LG_ER("%s(): socket creation failed. ", __func__ );
		rCode = -1;
	}
	if (rCode == 0) {
		if (mipInterface(interface) != 0)
		{
			HA_LG_ER("%s(): interface is down. ", __func__ );
			rCode = -1;
		}
		else
		{
			//To make sure the socket uses the desired interface, we bind it to the interface using sock opt SO_BINDTODEVICE.
			if(setsockopt(m_skfd, SOL_SOCKET, SO_BINDTODEVICE, interface, 4) == -1)
			{
				HA_LG_ER("%s(): Failed to bind m_skfd[%d] to interface[%s]", __func__, m_skfd, interface);
				rCode = -1;
			}
		}
	}
	if (rCode == 0)
	{
		if (set_destaddr(ipAddr) != 0)
		{
			HA_LG_ER("%s(): retrieval of destination address failed.", __func__ );
			rCode = -1;
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Ping::set_destaddr(const char* ipAddr)
{
	HA_TRACE_ENTER();
	int rCode = 0;

	//Get the destination address.
	struct addrinfo *addr=0;
	if (getaddrinfo(ipAddr, 0, 0, &addr) != 0)
	{
		HA_LG_ER("%s(): error in getaddrinfo()", __func__);
		rCode = -1;
	}

	if (rCode == 0)
	{
		m_dst = (struct in_addr) ((struct sockaddr_in*)(addr->ai_addr))->sin_addr;
		freeaddrinfo(addr);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Ping::mipInterface(const char *interface)
{
	HA_TRACE_ENTER();
	int rCode = 0;
	struct ifreq ifr;
	ACE_OS::memset(&ifr, 0, sizeof(ifr));
	char *err_str = 0;

	strncpy(ifr.ifr_name, interface, sizeof(ifr.ifr_name) - 1);
	ioctl(m_skfd, SIOCGIFINDEX, &ifr, err_str, "Not found");

	ioctl(m_skfd, SIOCGIFFLAGS, (char *) &ifr);
	if (!(ifr.ifr_flags & IFF_UP))
	{
		HA_LG_ER("%s(): interface %s is down.", __func__ , interface);
		rCode = -1;
	}

	if(rCode == 0)
		HA_LG_IN("%s(): interface %s is up.", __func__ , interface);

	HA_TRACE_LEAVE();
	return rCode;
}

int HA_AGENT_Ping::send_ping(const int pingSeqNum)
{
	HA_TRACE_ENTER();
	int bytesSent = 0, sendBufSize = 0, packetlen = 0, datalen = DEFDATALEN;
	struct sockaddr_in  from;
	u_char *packet, outpack[MAXPACKET];
	struct icmp *icp;
	int recvBytes = 0, fromlen = 0, hlen = 0;
	fd_set readFd;
	struct timeval tv;
	int retval = -1;
	struct timeval start;
	int retCode = -1;
	struct sockaddr_in dest_addr;
	memset(&dest_addr, 0, sizeof(dest_addr));
	dest_addr.sin_family = AF_INET;
	dest_addr.sin_addr = m_dst;

	packetlen = datalen + MAXIPLEN + MAXICMPLEN;
	if ((packet = (u_char *)malloc((u_int)packetlen)) == NULL)
	{
		HA_LG_ER("%s(): Allocating memory error for ICMP_ECHO packet - errno == %d!", __func__, errno);
		return retCode;
	}
	icp = (struct icmp *)outpack;
	icp->icmp_type = ICMP_ECHO;
	icp->icmp_code = 0;
	icp->icmp_cksum = 0;
	icp->icmp_seq = pingSeqNum;
	icp->icmp_id = getpid();
	sendBufSize = datalen + ICMP_MINLEN;
	icp->icmp_cksum = checksum((unsigned short *)icp,sendBufSize);

	bytesSent = sendto(m_skfd, (char *)outpack, sendBufSize, 0, (struct sockaddr*)&dest_addr, (socklen_t)sizeof(struct sockaddr_in));
	if ((bytesSent < 0) || (bytesSent != sendBufSize))
	{
		HA_LG_ER("%s(): Error when sending ICMP_ECHO packet(size = %d) - only %d bytes sent!", __func__, sendBufSize, bytesSent);
		retCode = -1;
	}
	else	// packet sent successfully
	{
		gettimeofday(&start, NULL);
		FD_ZERO(&readFd);
		FD_SET(m_skfd, &readFd);
		tv.tv_sec =  m_config.ysecs/APOS_HA_ONESEC_IN_MILLI;
		tv.tv_usec = ((m_config.ysecs%APOS_HA_ONESEC_IN_MILLI)*APOS_HA_ONESEC_IN_MICRO)/APOS_HA_ONESEC_IN_MILLI;
		struct timeval timeout_in_microsec;
		timeout_in_microsec.tv_usec = m_config.ysecs * APOS_HA_ONEMILLISEC_IN_MICRO;
		while(true)
		{
			retval = select(m_skfd+1, &readFd, NULL, NULL, &tv);
			if (retval == -1)
			{
				HA_LG_ER("%s(): select() error while waiting for response to ICMP_ECHO! errno == %d", __func__, errno);
				retCode = -1;
				break;
			}
			else if (retval)
			{
				fromlen = sizeof(sockaddr_in);
				if ((recvBytes = recvfrom(m_skfd, (char *)packet, packetlen, 0,(struct sockaddr *)&from, (socklen_t*)&fromlen)) < 0)
				{
					HA_LG_ER("%s(): Reading from socket failed! - recvBytes == %d, errno == %d", __func__, recvBytes, errno);
				}
				else
				{
					// Check the IP header
					hlen = sizeof( struct ip );
					if (recvBytes < (hlen + ICMP_MINLEN))
					{
						HA_LG_ER("%s(): Received packet too short! received packet size == %d, ipHeaderLen == %d, expectedMinLen == %d", __func__, recvBytes,hlen,(hlen + ICMP_MINLEN));
					}
					else
					{
						// Now the ICMP part
						icp = (struct icmp *)(packet + hlen);
						if (icp->icmp_type == ICMP_ECHOREPLY)
						{
							HA_TRACE("%s(): Received packet - receivedSeqNumber = %d, sentSeqNumber == %d, icmp_id == %d, sent_icmp_id == %d", __func__, icp->icmp_seq, pingSeqNum, icp->icmp_id, getpid());
							if ((icp->icmp_seq != pingSeqNum) || (icp->icmp_id != getpid()))
							{
								HA_TRACE("%s(): icmp_seq and/or icmp_id not matching with sent ICMP_ECHO packet!", __func__);
							}
							else
							{
								HA_LG_IN("%s(): ICMP_ECHOREPLY received!", __func__);
								retCode = 0;
								break;
							}
						}
						else
						{
							HA_TRACE("%s(): Received packet is not an ICMP_ECHOREPLY!", __func__);
						}
					}
				}
				// recalculate timeout value for select() so that overall, we only wait m_config.ysecs for all select() & recvFrom() calls
				struct timeval newCurTime;
				gettimeofday(&newCurTime, NULL);
				struct timeval loop_time;
				loop_time.tv_usec = APOS_HA_ONESEC_IN_MICRO*(newCurTime.tv_sec - start.tv_sec) + (newCurTime.tv_usec - start.tv_usec);
				long int diff_usec = timeout_in_microsec.tv_usec - loop_time.tv_usec;
				if(diff_usec < 0)	// 'config.ysecs' is elapsed. exit from loop
				{
					retCode = -1;
					break;
				}
				else	// call select() again with new timeout of 'config.ysecs - <elapsed time>'
				{
					tv.tv_sec = diff_usec / APOS_HA_ONESEC_IN_MICRO;
					tv.tv_usec = diff_usec % APOS_HA_ONESEC_IN_MICRO;
				}
			}
			else
			{
				retCode = -1;
				break;
			}
		}
	}
	(void)retCode;
	if(retCode == -1)
		HA_LG_IN("%s(): No response received for the ICMP_ECHO packet sent! retCode == %d", __func__, retCode);

	if(packet)
		free(packet);
	HA_TRACE_LEAVE();
	return retCode;
}


//-------------------------------------------------------------------------
bool HA_AGENT_Ping::ping(const char *ipAddr, const char *interface)
{
	HA_TRACE_ENTER();
	bool rCode = true;
	unsigned int counter = 0;
	int pingSeqNum = -1;
	int pingSuccessCount = 0;
	bool isIPReachable = false;

	if(init(ipAddr, interface) != 0)
	{
		HA_LG_ER("%s(): HA_AGENT_Ping::init() failed", __func__);
		rCode = false;
	}
	if (rCode == true)
	{
		while (counter < m_config.xtimes)
		{
			++pingSeqNum;
			if(send_ping(pingSeqNum) == 0)
			{
				pingSuccessCount++;
				if((pingSuccessCount > 1) || ((pingSuccessCount == 1) && (counter == (m_config.xtimes - 1))))
				{ // IP addr is considered reachable if 2 pings are successful OR if ping is successful in last retry
					isIPReachable = true;
					counter++;
					break;
				}

				if(counter < (m_config.xtimes - 1))
					m_globalInstance->Utils()->msec_sleep(m_config.ysecs);
			}
			counter++;
		}

		if (isIPReachable)
			HA_LG_IN("%s(): ip-address[ %s ] is reachable!", __func__, ipAddr);
		else
		{
			HA_LG_IN("%s(): ip-address[ %s ] is not reachable! retry count == %d", __func__, ipAddr, counter);
			rCode = false;
		}

	}

	/* reset class-level data */
	if (m_skfd != -1)
	{
		close(m_skfd);
		m_skfd = -1;
	}
	memset(&m_dst,  0, sizeof(struct in_addr));

	HA_TRACE_LEAVE();
	return rCode;
}

//Standard checksum calculation of ICMP packet
uint16_t HA_AGENT_Ping::checksum(uint16_t *buffer, unsigned len)
{
	if(buffer == NULL || len == 0)
		return 0;
	uint16_t checksum = 0;
	uint32_t sum = 0;
	while (len > 1)
	{
		sum += *buffer++;
		len -= 2;
	}

	if (len == 1)
	{
		*(unsigned char *)&checksum = *(unsigned char *)buffer;
		sum += checksum;
	}

	sum = (sum >> 16) + (sum & 0xffff);
	sum += (sum >> 16);
	checksum = ~sum;
	return checksum;
}
