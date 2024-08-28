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
 * @file apos_ha_agent_arping.cpp
 *
 * @brief
 *
 * This class is used to send/receive arping request/response
 * to/from mip Address.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <apos_ha_agent_arping.h>

//-------------------------------------------------------------------------
HA_AGENT_Arping::HA_AGENT_Arping():
 m_globalInstance(HA_AGENT_Global::instance()),
 m_config()
{
	HA_TRACE_ENTER();
	m_skfd = -1;
	memset(&m_curr, 0, sizeof(struct sockaddr_ll));
	memset(&m_peer, 0, sizeof(struct sockaddr_ll));
	memset(&m_src,  0, sizeof(struct in_addr));
	memset(&m_dst,  0, sizeof(struct in_addr));
	
  HA_TRACE_LEAVE();     	
}

//-------------------------------------------------------------------------
HA_AGENT_Arping::~HA_AGENT_Arping()
{
  HA_TRACE_ENTER();
  if (m_skfd == -1)
	  close(m_skfd);
  HA_TRACE_LEAVE(); 
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::init(const char *ipAddr, const char *interface)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	//Get the configuration object.
	m_config = m_globalInstance->Config()->getConfig();

	m_skfd = socket(AF_PACKET, SOCK_DGRAM, 0);
	if (m_skfd == -1) {
		HA_LG_ER("%s(): socket creation failed. ", __func__ );
		rCode=-1;
	}
	if (rCode == 0) {
		if (mipInterface(ipAddr, interface) != 0) {
			HA_LG_ER("%s(): interface is down or is not ARPable ", __func__ );
			rCode=-1;
		}
	}
	if (rCode == 0) {
		if (set_destaddr(ipAddr) != 0) {
			HA_LG_ER("%s(): retrieval of destination address failed.", __func__ );
			rCode=-1;
		}
	}
	if (rCode == 0) {
		if (set_srcaddr(interface) != 0) {
			HA_LG_ER("%s(): retrieval of source address failed.", __func__ );
			rCode=-1;
		}
	}
	if (rCode == 0) {
		m_curr.sll_family = AF_PACKET;
		m_curr.sll_protocol = htons(ETH_P_ARP);
		bind(m_skfd, (struct sockaddr *) &m_curr, sizeof(m_curr));
		socklen_t alen = sizeof(m_curr);

		if (getsockname(m_skfd, (struct sockaddr *) &m_curr, &alen) == -1) {
			HA_LG_ER("%s(): getsockname failed.", __func__ );
			rCode=-1;
		}
		if (rCode == 0) {
			if (m_curr.sll_halen == 0) {
				HA_LG_ER("%s(): destination is not ARPable (no ll address).", __func__ );
				rCode=-1;
			}
		}
		m_peer=m_curr;
		memset(m_peer.sll_addr, -1, m_peer.sll_halen);
	}
		
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::set_srcaddr(const char* interface)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	struct sockaddr_in saddr;
	memset(&saddr, 0, sizeof(saddr));
	saddr.sin_family = AF_INET;
	
	int probe_fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (probe_fd == -1) {
		HA_LG_ER("%s(): socket failed", __func__ );
		rCode=-1;
	}

	if (rCode == 0) {
		setsockopt(probe_fd, SOL_SOCKET, SO_BINDTODEVICE, interface, 4);
		socklen_t alen = sizeof(saddr);
		saddr.sin_port = htons(1025);
		saddr.sin_addr = m_dst;

		const int temp=1;
		if (setsockopt(probe_fd, SOL_SOCKET, SO_DONTROUTE, &temp, sizeof(temp)) == -1) {
			HA_LG_ER("%s(): setsockopt failed.", __func__ );
			rCode=-1;
		}
		if (rCode == 0) {
			if (connect(probe_fd, (struct sockaddr *) &saddr, sizeof(saddr)) == -1) {
				HA_LG_ER("%s(): connect failed.", __func__ );
				rCode=-1;
			}
		}
		if (rCode == 0) {
			if (getsockname(probe_fd, (struct sockaddr *) &saddr, &alen) == -1) {
				HA_LG_ER("%s(): getsockname failed.", __func__ );
				rCode=-1;
			}
		}
		if (rCode == 0) {
			if (saddr.sin_family != AF_INET) {
				HA_LG_ER("%s(): No IP Address configured.", __func__ );
				rCode=-1;
			}
		}
		if (rCode == 0) {
			m_src = saddr.sin_addr;
		}
	}
	close(probe_fd);


	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::set_destaddr(const char* ipAddr)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	//Get the destination address.
	struct addrinfo *addr=0;


	if (getaddrinfo( ipAddr, 0, 0, &addr ) != 0) {
		HA_LG_ER("%s(): error in getaddrinfo", __func__ );
		rCode=-1;
	}

	if (rCode == 0) {
		m_dst = (struct in_addr) ((struct sockaddr_in*)( addr->ai_addr))->sin_addr;
		freeaddrinfo( addr);
	}


	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::mipInterface(const char* ipAddr, const char *interface)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	struct ifreq ifr;
	ACE_OS::memset(&ifr, 0, sizeof(ifr));
	char *err_str=0;


	strncpy(ifr.ifr_name, interface, sizeof(ifr.ifr_name) - 1);
	ioctl(m_skfd, SIOCGIFINDEX, &ifr, err_str, "Not found");
	m_curr.sll_ifindex = ifr.ifr_ifindex;

	ioctl(m_skfd, SIOCGIFFLAGS, (char *) &ifr);
	if (!(ifr.ifr_flags & IFF_UP)) {
		HA_LG_ER("%s(): interface %s is down.", __func__ , interface );
		rCode=-1;
	}
	if (rCode == 0) {
		if (ifr.ifr_flags & (IFF_NOARP | IFF_LOOPBACK)) {
			HA_LG_ER("%s(): destination %s is not ARPable.", __func__, ipAddr );
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
bool HA_AGENT_Arping::arping(const char *ipAddr, const char *interface)
{
	HA_TRACE_ENTER();
	bool rCode=true;
	ACE_UINT32 cntr=0, sendCntr=0, recvCntr=0;

	if( init(ipAddr, interface) != 0 ) {
		HA_LG_ER("%s(): HA_AGENT_Arping::init failed", __func__);
		rCode=false;
	}
	if (rCode == true) {
		while (cntr < m_config.xtimes) {
			if (send_req() == 0) {
				sendCntr++;

				if (recv_resp() == 0) {
					recvCntr++;
					break;
				}
			}
			cntr++;
		}

		// If ARP request has been sent and reply is recieved, it means
		// the other node is up and active.
		if (sendCntr == 0 || (sendCntr > 0 && (recvCntr == 0 ))) {
			HA_LG_ER("%s(): sendCntr = %x, recvCntr = %x for IP: %s, interface: %s", __func__, sendCntr, recvCntr, ipAddr, interface );
			rCode=false;
		} else {
			HA_LG_IN("%s(): arping is successful", __func__);
		}
	}

  /* reset class-level data */
	{
	  if (m_skfd != -1) {
      close(m_skfd);
      m_skfd = -1;
	  }
	  memset(&m_curr, 0, sizeof(struct sockaddr_ll));
	  memset(&m_peer, 0, sizeof(struct sockaddr_ll));
	  memset(&m_src,  0, sizeof(struct in_addr));
	  memset(&m_dst,  0, sizeof(struct in_addr));
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::send_req()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	unsigned char buf1[256]={0};
	struct arphdr *ah = (struct arphdr *) buf1;
	unsigned char *p = (unsigned char *) (ah + 1);
	ah->ar_hrd = htons(ARPHRD_ETHER);
	ah->ar_pro = htons(ETH_P_IP);
	ah->ar_hln = m_curr.sll_halen;
	ah->ar_pln = 4;
	ah->ar_op = htons(ARPOP_REQUEST);
	p=(unsigned char*)mempcpy(p, &m_curr.sll_addr, ah->ar_hln);
	p=(unsigned char*)mempcpy(p, &m_src, 4);
	p=(unsigned char*)mempcpy(p, &m_peer.sll_addr, ah->ar_hln);
	p=(unsigned char*)mempcpy(p, &m_dst, 4);
	int err = sendto(m_skfd, buf1, p - buf1, 0, (struct sockaddr *) &m_peer, sizeof(m_peer));
	if (err != p - buf1) {
		HA_LG_ER("%s(): sendto failed" , __func__ );
		rCode=-1;	//error in sending the data.
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Arping::recv_resp()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	
	fd_set readfdset, writefdset, excepfdset;
    FD_ZERO( &readfdset);
    FD_ZERO( &writefdset );
    FD_ZERO( &excepfdset );

	struct timeval timeout;
	timeout.tv_sec =  m_config.ysecs/APOS_HA_ONESEC_IN_MILLI;
	timeout.tv_usec = ((m_config.ysecs%APOS_HA_ONESEC_IN_MILLI)*APOS_HA_ONESEC_IN_MICRO)/APOS_HA_ONESEC_IN_MILLI;

	FD_SET( m_skfd, &readfdset);
	int ret=-1;

	while(1) {
		ret = select( m_skfd +1, &readfdset, &writefdset, &excepfdset, &timeout);
		if (ret >  0 && FD_ISSET( m_skfd, &readfdset)) {
			char packet[4096] = {0};
			struct sockaddr_ll from;
			socklen_t alen = sizeof(from);

			int cc = recvfrom( m_skfd, packet, sizeof(packet),  0, (struct sockaddr *) &from, &alen);
			if (cc <= 0) {
				HA_TRACE("%s(): recvfrom failed" , __func__ ); //error in recieving the data.
				rCode=-1;
			}
			if (rCode == 0) {
				struct arphdr *ah = (struct arphdr *) &packet;
				unsigned char *p = (unsigned char *) (ah + 1);
				struct in_addr src_ip, dst_ip;

				if (from.sll_pkttype != PACKET_HOST 
					&& from.sll_pkttype != PACKET_BROADCAST
					&& from.sll_pkttype !=  PACKET_MULTICAST) {
						HA_LG_ER("%s(): invalid packet type" , __func__ );
						rCode=-1;
			}
			if (rCode == 0) {
				if (ah->ar_op != htons(ARPOP_REPLY)) {
					HA_TRACE_1("%s(): invalid arp request ah->ar_op=%u" , __func__, ah->ar_op);
					continue;
				}
			}
			if (rCode == 0) {
				if (ah->ar_hrd != htons(from.sll_hatype)
					&& (from.sll_hatype != ARPHRD_FDDI || ah->ar_hrd != htons(ARPHRD_ETHER))) {
						HA_LG_ER("%s(): invalid arp header type" , __func__ );
						rCode=-1;
				}
			}
			if (rCode == 0) {
				if (ah->ar_pro != htons(ETH_P_IP)
					|| (ah->ar_pln != 4)
					|| (ah->ar_hln != m_curr.sll_halen)
					|| (cc < (int)(sizeof(*ah) + 2 * (4 + ah->ar_hln)))) {
						HA_LG_ER("%s(): invalid arp header fields" , __func__);
						rCode=-1; 
				}
			}
			if (rCode == 0) {
				memcpy(&src_ip, p + ah->ar_hln, 4);
				memcpy(&dst_ip, p + ah->ar_hln + 4 + ah->ar_hln, 4);
				if (m_dst.s_addr != src_ip.s_addr) {
					HA_TRACE_1("%s(): m_dst.s_addr != src_ip.s_addr", __func__);
					continue;
				}
			}
			if (rCode == 0) {
				if ((m_src.s_addr != dst_ip.s_addr)
					|| (memcmp(p + ah->ar_hln + 4, &m_curr.sll_addr, ah->ar_hln))) {
						HA_TRACE_1("%s(): m_src.s_addr != dst_ip.s_addr" , __func__);
						continue;
					}
				}
			}
		}
		if (ret <= 0) {
			HA_TRACE_1("%s(): timeout received" , __func__ );
			rCode=-1;
		}
		break;
	}
	HA_TRACE_LEAVE();
	return rCode;
}
//-------------------------------------------------------------------------

