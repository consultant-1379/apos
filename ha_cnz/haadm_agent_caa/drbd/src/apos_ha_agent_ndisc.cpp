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
 * @file apos_ha_agent_ndisc.cpp
 *
 * @brief
 *
 * This class is used to send/receive icmpv6 requests on
 * mip address.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <apos_ha_agent_ndisc.h>

//-------------------------------------------------------------------------
HA_AGENT_ndisc::HA_AGENT_ndisc():
 m_globalInstance(HA_AGENT_Global::instance()),
 m_config()
{
	HA_TRACE_ENTER();
	m_skfd = -1;
	m_tgt=0;
	m_interface=0;
  HA_TRACE_LEAVE();     	
}

//-------------------------------------------------------------------------
HA_AGENT_ndisc::~HA_AGENT_ndisc()
{
  HA_TRACE_ENTER();
  if (m_skfd != -1){
	  close(m_skfd);
	  m_skfd = -1;
	}  
	if (m_tgt){
	  m_tgt=0;
	}
	if (m_interface){
 	  m_interface=0;
 	}  
  HA_TRACE_LEAVE(); 
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::init(const char *name)
{
	HA_TRACE_ENTER();
	int sCode=0, eCode=-1;

	//Get the configuration object.
	m_config = m_globalInstance->Config()->getConfig();

	m_skfd = socket(PF_INET6, SOCK_RAW, IPPROTO_ICMPV6);
	if (m_skfd == -1) {
		HA_LG_ER("%s(): socket creation failed. ", __func__ );
		return eCode;
	}

	fcntl(m_skfd, F_SETFD, FD_CLOEXEC);
	/* set ICMPv6 filter */
	{
    struct icmp6_filter f;
    ICMP6_FILTER_SETBLOCKALL(&f);
    ICMP6_FILTER_SETPASS(nd_type_advert, &f);
    setsockopt(m_skfd, IPPROTO_ICMPV6, ICMP6_FILTER, &f, sizeof (f));
	}

  int value=1;
	setsockopt(m_skfd, SOL_SOCKET, SO_DONTROUTE, &value, sizeof(int));

	/* sets Hop-by-hop limit to 255 */
	sethoplimit(255);
	setsockopt (m_skfd, IPPROTO_IPV6, IPV6_RECVHOPLIMIT, 
	            &value, sizeof(int));

	/* resove target's IPv6 address */
	if (getipv6byname(name, m_tgt)){
	  close(m_skfd);m_skfd = -1;
	  return eCode;
  }

  if (is_ifup() != 0){
		HA_LG_ER("%s(): interface (%s) is down. ", __func__, m_interface);
    close(m_skfd);m_skfd = -1;
    return eCode;
  }

	HA_TRACE_LEAVE();
	return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::is_ifup()
{
	HA_TRACE_ENTER();
	int sCode=0, eCode=-1;

	struct ifreq ifr;
	memset(&ifr, 0, sizeof(ifr));
	char *err_str=0;

	strncpy(ifr.ifr_name, m_interface, sizeof(ifr.ifr_name) - 1);
	ioctl(m_skfd, SIOCGIFINDEX, &ifr, err_str, "Not found");

	ioctl(m_skfd, SIOCGIFFLAGS, (char *) &ifr);
	if (!(ifr.ifr_flags & IFF_UP)) {
		HA_LG_ER("%s(): interface %s is down.", __func__ , m_interface );
		return eCode;
	}

	HA_TRACE_LEAVE();
	return sCode;
}

//-------------------------------------------------------------------------
bool HA_AGENT_ndisc::ndisc(const char *ipaddress, const char *interface)
{
	HA_TRACE_ENTER();
	bool sCode=true, eCode=false;
	unsigned int retry=0, sendCntr=0, recvCntr=0;

	/* fill class-wide data */
	struct sockaddr_in6 tgt; 
	m_tgt = &tgt;
  m_interface = interface;

	if(init(ipaddress) != 0 ) {
		HA_LG_ER("%s(): HA_AGENT_ndisc::init failed", __func__);
		return eCode;
	}
  
  char s[INET6_ADDRSTRLEN]= {0};
  inet_ntop(AF_INET6, &m_tgt->sin6_addr, s, sizeof(s));
  HA_TRACE_1("%s(): Soliciting %s (%s) on %s...", __func__, ipaddress, s, interface);

	while (retry < m_config.xtimes) {
	  /* sends a Solitication */
		if (send_req() == 0) {
			sendCntr++;

			/* receives an Advertisement */
			ssize_t value = recv_resp();
			if (value > 0) {
			  recvCntr++;
			  break;
			}else if ( value == 0)
			  HA_TRACE_1("%s(): Timed out.", __func__);
		}
		retry++;
  }

	// If Solictication request has been sent and receives an Advertisement,
	// it means that the other node is up and active.
	if (sendCntr == 0 || (sendCntr > 0 && (recvCntr == 0 ))) {
		HA_LG_ER("%s(): sendCntr = %x, recvCntr = %x for IP: %s, interface: %s", __func__, sendCntr, recvCntr, ipaddress, interface);
		return eCode;
	} else {
		HA_LG_IN("%s(): neighbor discovery successful", __func__);
	}

  /* reset class-level data*/
	{
    if (m_skfd != -1) {
      close(m_skfd);
      m_skfd = -1;
    }
    if (m_tgt){
	    m_tgt=0;
	  }  
	  if (m_interface){
	    m_interface=0;
	  }   
	}

	HA_TRACE_LEAVE();
	return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::send_req()
{
	HA_TRACE_ENTER();
	int sCode=0, eCode=-1;

	solicit_packet packet;
	struct sockaddr_in6 dst;
	ssize_t plen;

	memcpy (&dst, m_tgt, sizeof(dst));
	plen = buildsol(&packet, &dst);
	if (plen == -1)
	  return eCode;

	if (sendto(m_skfd, &packet, plen, 0,
	          (const struct sockaddr *)&dst,
	          sizeof (dst)) != plen)
  {
    HA_LG_ER("%s(): Sending ICMPv6 packet failed", __func__);
    return eCode;
  }

	HA_TRACE_LEAVE();
	return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::recv_resp()
{
	HA_TRACE_ENTER();

	struct timespec end;
	unsigned responses = 0;

	/* computes deadline time */
	mono_gettime(&end);
	{
    div_t d;
    d = div(m_config.ysecs, 1000);
    end.tv_sec += d.quot;
    end.tv_nsec += d.rem * 1000000;
	}

	/* receive loop */
	for (;;)
	{ 
    /* waits for reply until deadline */
    struct timespec now;
    ssize_t val = 0;

    mono_gettime(&now);
    if (end.tv_sec >= now.tv_sec)
    {
      val = (end.tv_sec - now.tv_sec) * 1000 +
            (int) ((end.tv_nsec - now.tv_nsec) / 1000000);
      if (val < 0) 
        val = 0;
    }

    struct pollfd fds[1];
    fds[0].fd = m_skfd;
    fds[0].events = POLLIN;
    val = poll(fds, 1, val);
    if (val <= 0)
      break;
    
    if (val == 0)
      return responses;

    /* receives an ICMPv6 packet */
    union
    {
      uint8_t b[1460];
      uint64_t align;
    } buf;
    struct sockaddr_in6 addr;

    val = recvfromLL(&buf, sizeof(buf), MSG_DONTWAIT, &addr);
    if (val == -1) {
      if (errno != EAGAIN)
		    HA_LG_ER("%s(): error receiving ICMPv6 packet" , __func__ );
      continue;
    }
    
    /* ensures the response came through the right interface */ 
    if (addr.sin6_scope_id &&
       (addr.sin6_scope_id != m_tgt->sin6_scope_id))
       continue;
    
    if (parseadv(buf.b, val) == 0)
    {
      char str[INET6_ADDRSTRLEN];
      if (inet_ntop (AF_INET6, &addr.sin6_addr, str, sizeof(str)) != NULL)
			  HA_LG_IN("%s(): from %s ", __func__, str);

      if (responses < INT_MAX)
        responses++;
    }
	} /* end for */
	
	HA_TRACE_LEAVE();
	return responses;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::recvfromLL(void *buf, size_t len, int flags, 
                               struct sockaddr_in6 *addr)
{
	HA_TRACE_ENTER();
  char cbuf[CMSG_SPACE (sizeof (int))];
  struct iovec iov =
  {
    .iov_base = buf,
    .iov_len = len
  };

  struct msghdr hdr =
  {
    .msg_name = addr,
    .msg_namelen = sizeof (*addr),
    .msg_iov = &iov,
    .msg_iovlen = 1,
    .msg_control = cbuf,
    .msg_controllen = sizeof (cbuf),
    .msg_flags = 0
  };

  ssize_t val = recvmsg(m_skfd, &hdr, flags);
  if (val == -1)
    return val;

  /* ensures the hop limit is 255 */
  for (struct cmsghdr *cmsg = CMSG_FIRSTHDR (&hdr);
       cmsg != NULL;
       cmsg = CMSG_NXTHDR (&hdr, cmsg))
  {
    if ((cmsg->cmsg_level == IPPROTO_IPV6)
      && (cmsg->cmsg_type == IPV6_HOPLIMIT))
    {
      if (255 != *(int *)CMSG_DATA (cmsg))
      {
        // pretend to be a spurious wake-up
        errno = EAGAIN;
        return -1;
      }
    }
  }
  
	HA_TRACE_LEAVE();
  return val;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::parseadv(const uint8_t *buf, size_t len)
{                             
  HA_TRACE_ENTER();
  int sCode=0, eCode=-1;
  const struct nd_neighbor_advert *na =
        (const struct nd_neighbor_advert *)buf;

  const uint8_t *ptr=NULL;

  /* checks if the packet is a Neighbor Advertisement, and
     if the target IPv6 address is the right one */
  if ((len < sizeof (struct nd_neighbor_advert))
    || (na->nd_na_type != ND_NEIGHBOR_ADVERT)
    || (na->nd_na_code != 0)
    || memcmp(&na->nd_na_target, &m_tgt->sin6_addr, 16))
    return eCode;

  len -= sizeof (struct nd_neighbor_advert);

  /* looks for Target Link-layer address option */
  ptr = buf + sizeof (struct nd_neighbor_advert);
  while (len >= 8)
  {
    uint16_t optlen;

    optlen = ((uint16_t)(ptr[1])) << 3;
    if (optlen == 0)
      break; /* invalid length */

    if (len < optlen) /* length > remaining bytes */
      break;

    len -= optlen;

    /* skips unrecognized option */
    if (ptr[0] != ND_OPT_TARGET_LINKADDR)
    {
      ptr += optlen;
      continue;
    }

    /* Found! displays link-layer address */
    ptr += 2;
    optlen -= 2;
   
    printmacaddress(ptr, optlen);
    return sCode;
  } 

  HA_TRACE_LEAVE();
  return eCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::printmacaddress(const uint8_t *ptr, size_t len)
{
  HA_TRACE_ENTER();
  int sCode=0;
  char buff[256]={0};
  int index=0;

  while (len > 1)
  { 
    sprintf((buff+index), "%02X:", *ptr);
    ptr++;
    len--;
    index+=3;
  }

  if (len == 1){
    sprintf((buff+index), "%02X", *ptr);
    buff[index+3]='\0';
  }

  HA_LG_IN("%s():Target link-layer address: %s", __func__, buff);
  HA_TRACE_LEAVE();
  return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::getmacaddress(uint8_t *addr)
{
  HA_TRACE_ENTER();
  struct ifreq req;
  int sCode=0, eCode=-1;
  memset (&req, 0, sizeof (req));

  if (((unsigned)strlen (m_interface)) >= (unsigned)IFNAMSIZ)
    return eCode; /* buffer overflow = local root */
  strcpy(req.ifr_name, m_interface);

  int fd = socket(AF_INET6, SOCK_DGRAM, 0);
  if (fd == -1)
    return eCode;

  if (ioctl(fd, SIOCGIFHWADDR, &req))
  {
    HA_LG_ER("%s(): Error [%s]", __func__, m_interface);
    close(fd);
    return eCode;
  }

  close(fd);
  memcpy(addr, req.ifr_hwaddr.sa_data, 6);
  HA_TRACE_LEAVE();
  return sCode;
}

//-------------------------------------------------------------------------
inline int HA_AGENT_ndisc::sethoplimit(int value)
{
  return (setsockopt(m_skfd, IPPROTO_IPV6, IPV6_MULTICAST_HOPS,
                     &value, sizeof(value))
       || setsockopt(m_skfd, IPPROTO_IPV6, IPV6_UNICAST_HOPS, 
                     &value, sizeof(value))) ? -1 : 0;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::setsourceip(const char *src)
{
  HA_TRACE_ENTER();
  int sCode=0, eCode=-1;
  struct sockaddr_in6 addr;

  if (getipv6byname(src, &addr)) {
    return eCode;
  }

  if (bind(m_skfd, (const struct sockaddr *)&addr, sizeof(addr))) {
    HA_LG_ER("%s(): %s", __func__, src);
    return eCode;
  }

  HA_TRACE_LEAVE();
  return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::getipv6byname(const char *name, struct sockaddr_in6 *addr)
{
  HA_TRACE_ENTER();

  int sCode=0, eCode=-1;
  struct addrinfo hints, *res;
  memset (&hints, 0, sizeof (hints));
  hints.ai_family = PF_INET6;
  hints.ai_socktype = SOCK_DGRAM; /* dummy */
  hints.ai_flags = 0;

  int val = getaddrinfo(name, NULL, &hints, &res);
  if (val) {
    HA_LG_ER("%s(): %s: %s", __func__, name, gai_strerror(val));
    return eCode;
  }

  memcpy(addr, res->ai_addr, sizeof(struct sockaddr_in6));
  freeaddrinfo(res);

  val = if_nametoindex(m_interface);
  if (val == 0) {
    HA_LG_ER("%s(): ETH: %s", __func__, m_interface);
    return eCode;
  }
  addr->sin6_scope_id = val;

  HA_TRACE_LEAVE();
  return sCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_ndisc::buildsol(solicit_packet *ns, struct sockaddr_in6 *tgt)
{
  HA_TRACE_ENTER();

  /* builds ICMPv6 Neighbor Solicitation packet */
  ns->hdr.nd_ns_type = ND_NEIGHBOR_SOLICIT;
  ns->hdr.nd_ns_code = 0;
  ns->hdr.nd_ns_cksum = 0;
  ns->hdr.nd_ns_reserved = 0;
  memcpy(&ns->hdr.nd_ns_target, &m_tgt->sin6_addr, 16);

  /* determines actual multicast destination address */
  memcpy (tgt->sin6_addr.s6_addr, "\xff\x02\x00\x00\x00\x00\x00\x00"
                                  "\x00\x00\x00\x01\xff", 13);
  
  /* gets our own interface's link-layer address (MAC) */
  if (getmacaddress(ns->hw_addr))
    return sizeof (ns->hdr);

  ns->opt.nd_opt_type = ND_OPT_SOURCE_LINKADDR;
  ns->opt.nd_opt_len = 1; /* 8 bytes */

  HA_TRACE_LEAVE();
  return sizeof (*ns);
}
//-------------------------------------------------------------------------
