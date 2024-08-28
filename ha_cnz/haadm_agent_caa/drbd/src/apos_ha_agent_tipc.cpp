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
 * @file apos_ha_agent_tipc.cpp
 *
 * @brief
 * 
 * This class handles the tipc communication with other node.
 * 
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_agent_tipc.h"

HA_AGENT_Tipc::HA_AGENT_Tipc():
	sock_sd(0),
	bind_sd(0)
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::create_addr(struct l_tipc_addr &t_addr, ACE_INT32 node_id)
{
	HA_TRACE_ENTER();
	if (node_id == APOS_HA_NODE_ONE){
		t_addr.type=100;
		t_addr.instance=2010;
	}

	if (node_id == APOS_HA_NODE_TWO){
		t_addr.type=100;
		t_addr.instance=2020;
	}
	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::subscribe(struct l_tipc_addr t_addr)
{
	ACE_INT32 rCode=0;
	HA_TRACE_ENTER();

	struct tipc_subscr subscr = {  {(unsigned int)t_addr.type,
					(unsigned int)t_addr.instance,
					(unsigned int)t_addr.instance},
					(unsigned int)TIPC_WAIT_FOREVER,
					(unsigned int)TIPC_SUB_PORTS,
					{}};

	if (send(sock_sd,&subscr,sizeof(subscr),0) != sizeof(subscr)){
		HA_LG_ER("%s(): send subscrption failed", __func__);
		rCode=-1;
	}else {
		HA_LG_IN("%s(): Subscribed to event for <%u, %u, %u>", __func__, 
        (unsigned int)t_addr.type, (unsigned int)t_addr.instance, (unsigned int)t_addr.instance);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::init(ACE_INT32 node_id)
{
	HA_TRACE_ENTER();
	struct sockaddr_tipc topsrv;
	ACE_INT32 rCode=0;

	memset(&topsrv, 0, sizeof(topsrv));
	topsrv.family = AF_TIPC;
	topsrv.addrtype = TIPC_ADDR_NAME;
	topsrv.addr.name.name.type = TIPC_TOP_SRV;
	topsrv.addr.name.name.instance = TIPC_TOP_SRV;

	sock_sd = socket(AF_TIPC, SOCK_SEQPACKET, 0);

	if (sock_sd == -1) {
		HA_LG_ER("%s(): socket error. errno=%d", __func__, errno);
		rCode=-1;
	}
	
	if (rCode == 0) {
		if (connect(sock_sd,(struct sockaddr*)&topsrv,sizeof(topsrv)) < 0){
			HA_LG_ER("%s(): failed to connect to topology server", __func__);
			rCode=-1;
		}	
	}

	if (rCode == 0) {
		if (msg_init(node_id) < 0) {
			HA_LG_ER("%s(): msg_init failed", __func__);
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::msg_init(ACE_INT32 node_id)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	struct sockaddr_tipc sockaddr;
	struct l_tipc_addr t_addr;
	create_addr(t_addr, node_id); 	

	sockaddr.family = AF_TIPC;
	sockaddr.addrtype = TIPC_ADDR_NAMESEQ;
	sockaddr.scope = TIPC_CLUSTER_SCOPE;
	sockaddr.addr.nameseq.type = t_addr.type;
	sockaddr.addr.nameseq.lower = t_addr.instance;
	sockaddr.addr.nameseq.upper = t_addr.instance;

	bind_sd = socket (AF_TIPC, SOCK_RDM, 0);
	if (bind_sd == -1) {
		HA_LG_ER("%s(): socket creation failed. ", __func__ );
		rCode=-1;
	}

	if(rCode == 0) {
		if (0 != bind (bind_sd, (struct sockaddr*)&sockaddr, sizeof(sockaddr))) {
			HA_LG_ER("%s(): bind error", __func__);
			rCode=-1;
		}
	}
	
	if (rCode == 0) {	
		u_int optval_true = 1;
		if (setsockopt(bind_sd, SOL_TIPC, TIPC_DEST_DROPPABLE, &optval_true, sizeof(optval_true) ) != 0 ) {
			HA_LG_ER("%s(): Unable to set socket options.", __func__);
			rCode=-1;
		}
	}

	if (rCode == 0) {
		if (subscribe(t_addr) < 0) {
			HA_LG_ER("%s(): subscription failed", __func__);
			rCode=-1;
		}
	}
    
	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::query_topsrv(ACE_INT32 node_id, ACE_INT32 &Is_Published)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	struct tipc_event evt;
	struct l_tipc_addr t_addr;

	create_addr(t_addr, node_id);	

	struct tipc_subscr subscr = { {	(unsigned int)t_addr.type,
									(unsigned int)t_addr.instance,
									(unsigned int)t_addr.instance},
									0,
									TIPC_SUB_PORTS,
									{}
								};
	
	/* Name subscription: for port availability */
	if (send(sock_sd,&subscr,sizeof(subscr),0) != sizeof(subscr)){
		HA_LG_ER("%s(): failed to send subscription", __func__);
		rCode=-1;
	}

	if (rCode == 0) {
		HA_LG_IN("%s(): Waiting for topology event <%u, %u, %u>",__func__, 
        (unsigned int)t_addr.type, (unsigned int)t_addr.instance, (unsigned int)t_addr.instance);

		/* Now wait for the subscriptions to fire: */
		int sz = recv(sock_sd,&evt,sizeof(evt),0);
	
		if ( (sz == sizeof(evt)) && (evt.event == TIPC_PUBLISHED) && 
            (evt.found_lower == t_addr.instance) ) {
			HA_LG_IN("%s(): <%u> is ALREADY published" ,__func__, (unsigned int)t_addr.instance);
			Is_Published=TRUE;
		}else{
			HA_LG_IN("%s(): <%u> not currently published", __func__, (unsigned int)t_addr.instance);
			Is_Published=FALSE;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
int HA_AGENT_Tipc::topsrv_handler()
{
	HA_TRACE_ENTER();
	struct tipc_event evt;
	ACE_INT32 rCode=0;

	recv(sock_sd, &evt, sizeof(evt), 0);

	switch(evt.event){
		case TIPC_PUBLISHED:
			HA_LG_IN("%s(): Published <%u,%u,%u> port id <%x:%u>", __func__, 
            evt.s.seq.type, evt.found_lower, evt.found_upper, evt.port.node, evt.port.ref);
			break;
		case TIPC_WITHDRAWN:
			HA_LG_IN("%s(): Withdrawn <%u,%u,%u> port id <%x:%u>", __func__, 
            evt.s.seq.type, evt.found_lower, evt.found_upper, evt.port.node, evt.port.ref);
			break;
		case TIPC_SUBSCR_TIMEOUT:
			HA_LG_IN("%s(): Timeout <%u,%u,%u> port id <%x:%u>", __func__, 
            evt.s.seq.type, evt.found_lower, evt.found_upper, evt.port.node, evt.port.ref);
			break;
		default:
			HA_LG_ER("%s(): Unkown event = %i", __func__, evt.event);
			rCode=-1;
	}	

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
bool HA_AGENT_Tipc::tipc_config()
{
	HA_TRACE_ENTER();
	
	HA_TRACE_LEAVE();
	return true;
}
//--------------------------------------------------------------------------

