/*===================================================================
 *  
 *  @file   apos_ha_rdeagent_tipc.cpp
 *
 *  @brief
 * 
 * 
 *  @version 1.0.0
 *
 *
 *  HISTORY
 * 
 * 
 * 
 *
 *       PR           DATE      INITIALS    DESCRIPTION
 *--------------------------------------------------------------------
 *       N/A       DD/MM/YYYY     NS       Initial Release
 *==================================================================== */

/*====================================================================
 *                           DIRECTIVE DECLARATION SECTION
 * =================================================================== */

#include "apos_ha_rdeagent_tipc.h"


ACS_APGCC_AgentMsging::ACS_APGCC_AgentMsging():
	sock_sd(0),
	bind_sd(0)
{

}

ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::_create_tipc_address(struct l_tipc_addr &t_addr, ACE_INT32 node_id){

	if (node_id == NODE_ONE){
		t_addr.type=100;
		t_addr.instance=2010;
	}

	if (node_id == NODE_TWO){
		t_addr.type=100;
		t_addr.instance=2020;
	}
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::tipc_subscribe(struct l_tipc_addr t_addr){

	struct tipc_subscr subscr = {  {(unsigned int)t_addr.type,
					(unsigned int)t_addr.instance,
					(unsigned int)t_addr.instance},
					(unsigned int)TIPC_WAIT_FOREVER,
					(unsigned int)TIPC_SUB_PORTS,
					{}};

	// Subscribe to this event
	if (send(sock_sd,&subscr,sizeof(subscr),0) != sizeof(subscr)){
		syslog(LOG_ERR, "Failed to send subscrption");
		return ACS_APGCC_FAILURE;
	}else {
		syslog(LOG_INFO, "Subscribed to event for <%u, %u, %u>", (unsigned int)t_addr.type,(unsigned int)t_addr.instance,(unsigned int)t_addr.instance);
	}
	
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::tipc_initialize(ACE_INT32 node_id){

	struct sockaddr_tipc topsrv;

	memset(&topsrv, 0, sizeof(topsrv));
	topsrv.family = AF_TIPC;
	topsrv.addrtype = TIPC_ADDR_NAME;
	topsrv.addr.name.name.type = TIPC_TOP_SRV;
	topsrv.addr.name.name.instance = TIPC_TOP_SRV;

	sock_sd = socket (AF_TIPC, SOCK_SEQPACKET,0);

	if (sock_sd == -1) {
		syslog(LOG_ERR, "Failed to create socket for topology subscription mgmt. errno=%d", errno);
		return ACS_APGCC_FAILURE;
	}

	if (connect(sock_sd,(struct sockaddr*)&topsrv,sizeof(topsrv)) < 0){
		syslog(LOG_ERR, "failed to connect to topology server");
		return ACS_APGCC_FAILURE;
	}

	if (tipc_msg_intialize(node_id) != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "tipc subscription failed");
		return ACS_APGCC_FAILURE;
	}

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::tipc_msg_intialize(ACE_INT32 node_id){

	struct sockaddr_tipc sockaddr;

	struct l_tipc_addr t_addr;
	_create_tipc_address(t_addr, node_id); 	

	sockaddr.family = AF_TIPC;
	sockaddr.addrtype = TIPC_ADDR_NAMESEQ;
	sockaddr.scope = TIPC_CLUSTER_SCOPE;
	sockaddr.addr.nameseq.type = t_addr.type;
	sockaddr.addr.nameseq.lower = t_addr.instance;
	sockaddr.addr.nameseq.upper = t_addr.instance;

	bind_sd = socket (AF_TIPC, SOCK_RDM, 0);

	if (0 != bind (bind_sd, (struct sockaddr*)&sockaddr,sizeof(sockaddr))){
		syslog(LOG_ERR,"Server: Failed to bind port name");
		return ACS_APGCC_FAILURE;
	}
		
	u_int optval_true = 1;
	if( setsockopt(bind_sd, SOL_TIPC, TIPC_DEST_DROPPABLE, &optval_true, sizeof(optval_true) ) != 0 ){
		syslog(LOG_ERR, "Unable to set socket options.");
	}

	if (tipc_subscribe(t_addr) != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "tipc subscription failed");
	}

	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::query_tipc_topserver(ACE_INT32 node_id, ACS_APGCC_BOOL &Is_Published){

	struct tipc_event evt;
	struct l_tipc_addr t_addr;

	_create_tipc_address(t_addr, node_id);	

	struct tipc_subscr subscr = { {(unsigned int)t_addr.type,
					(unsigned int)t_addr.instance,
					(unsigned int)t_addr.instance},
					0,
					(unsigned int)TIPC_SUB_PORTS,
					{}};
	
	/* Name subscription: for port availability */
	if (send(sock_sd,&subscr,sizeof(subscr),0) != sizeof(subscr)){
		syslog(LOG_ERR, "failed to send subscription");
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO, "Waiting for topology event <%u, %u, %u>",(unsigned int)t_addr.type,(unsigned int)t_addr.instance,(unsigned int)t_addr.instance);

	/* Now wait for the subscriptions to fire: */
	int sz = recv(sock_sd,&evt,sizeof(evt),0);
	
	if ( (sz == sizeof(evt)) && (evt.event == TIPC_PUBLISHED) && (evt.found_lower == t_addr.instance) ) {
		syslog(LOG_INFO,"<%u> is ALREADY published" ,(unsigned int)t_addr.instance);
		Is_Published=TRUE;
	}
	else {
		syslog(LOG_INFO,"<%u> not currently published" ,(unsigned int)t_addr.instance);
		Is_Published=FALSE;
	}

	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType ACS_APGCC_AgentMsging::topserver_handler(){

	struct tipc_event evt;
	recv(sock_sd, &evt, sizeof(evt), 0);

	switch(evt.event){

	case TIPC_PUBLISHED:
			
			syslog(LOG_INFO, "Published <%u,%u,%u> port id <%x:%u>",evt.s.seq.type,evt.found_lower,evt.found_upper,evt.port.node,evt.port.ref);
			break;
	
	case TIPC_WITHDRAWN:
	
			syslog(LOG_INFO, "Withdrawn <%u,%u,%u> port id <%x:%u>",evt.s.seq.type,evt.found_lower,evt.found_upper,evt.port.node,evt.port.ref);
			break;

	case TIPC_SUBSCR_TIMEOUT:
			
			syslog(LOG_INFO, "Timeout <%u,%u,%u> port id <%x:%u>",evt.s.seq.type,evt.found_lower,evt.found_upper,evt.port.node,evt.port.ref);
			break;
	default:

			syslog(LOG_ERR, "Unkown event = %i", evt.event);
			return ACS_APGCC_FAILURE;
	}	

	return ACS_APGCC_SUCCESS;
}

