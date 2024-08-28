#ifndef APOS_HA_AGENT_TIPC_H
#define APOS_HA_AGENT_TIPC_H

#include "errno.h"
#include "sys/ioctl.h"
#include "linux/tipc.h"
#include <sys/types.h>
#include <sys/socket.h>
#include "syslog.h"
#include "poll.h"
#include <string.h>
#include <stdio.h>
#include "ace/ACE.h"

#include "ACS_APGCC_AmfTypes.h"

class ACS_APGCC_AgentMsging {

	private:
		int sock_sd;
		int bind_sd;

		struct l_tipc_addr {
			unsigned long type;
			unsigned long instance;
		};
		
		ACS_APGCC_ReturnType _create_tipc_address(struct l_tipc_addr &t_addr, ACE_INT32 node_id);
		ACS_APGCC_ReturnType tipc_subscribe(struct l_tipc_addr t_addr);

	public:

		ACS_APGCC_AgentMsging();
		~ACS_APGCC_AgentMsging(){};

		inline int getFd() { 
			return this->sock_sd;
		};

		ACS_APGCC_ReturnType tipc_initialize(ACE_INT32 node_id);
		ACS_APGCC_ReturnType tipc_msg_intialize(ACE_INT32 node_id);
		ACS_APGCC_ReturnType query_tipc_topserver(ACE_INT32 node_id, ACS_APGCC_BOOL &Is_Published);
		ACS_APGCC_ReturnType topserver_handler();

};
#endif //APOS_HA_AGENT_TIPC_H
