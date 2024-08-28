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
 * @file apos_ha_agent_types.h
 *
 * @brief
 * 
 * This file defines all the enums, structures and macros
 * used by the other classes in AGENT.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ****************************************************************************/
#ifndef APOS_HA_AGENT_TYPES_H
#define APOS_HA_AGENT_TYPES_H

#include <string.h>
#include <ACS_APGCC_AmfTypes.h>

//==========================================================================
// Boolean delcaration
//==========================================================================

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

//==========================================================================
// constant delcaration
//==========================================================================
/* --*-- File Section --*-- */ 
#define APOS_HA_FILE_NODE_ID 				"/etc/cluster/nodes/this/id"
#define APOS_HA_FILE_CNFG 					"/opt/ap/apos/conf/apos_ha_agentd.conf"
#define APOS_HA_FILE_PROC_DRBD				"/proc/drbd"
#define APOS_HA_FILE_LOCK					"/opt/ap/apos/bin/.agent.lock"
#define APOS_HA_FILE_AGENT_PSST_INFO		"/opt/ap/apos/bin/.agent.persistent.info"
#define APOS_HA_FILE_RC						"/var/log/.haagentrcf"

/* --*-- Command Section --*-- */
#define APOS_HA_CMD_APOS_OPERATIONS 		"/opt/ap/apos/bin/apos_operations"
#define APOS_HA_CMD_HA_OPERATIONS 			"/opt/ap/apos/bin/apos_ha_operations"
#define APOS_HA_CMD_DRBDMGR 				"/opt/ap/apos/bin/raidmgr"
#define APOS_HA_CMD_LEN						100 

/* --*-- General Section --*-- */
#define APOS_HA_DEVMON_2_AGENT_PIPE 		"/var/run/ap/fifo_devmon2agent"
#define APOS_HA_AGENT_AEH_FIFO 				"/var/run/ap/acs_aehfifo"
#define APOS_HA_OPERSTATE_ENABLED 			1
#define APOS_HA_SLEEP_TMOUT         		10
#define APOS_HA_ONESEC_IN_MILLI 			1000 /* 1 sec = 1000 milli*/
#define APOS_HA_ONESEC_IN_MICRO				1000000 /* 1 sec = 1000000 micro */
#define APOS_HA_ONEMILLISEC_IN_MICRO		1000 /* 1 milli sec = 1000 micro */
#define APOS_HA_AGENT_LOG_FILE				"agentd.log" 
#define APOS_HA_AGENT_PING_PACKET_SIZE		64
#define APOS_HA_AGENT_PING_RECV_TIMEOUT		1
#define APOS_HA_AXEFUNCTIONS_OBJ_DN			"axeFunctionsId=1"
#define APOS_HA_NODE_ARCHITECTURE_ATTR_NAME	"apgShelfArchitecture"

/* --*-- Config Defaults --*-- */
#define APOS_HA_DFLT_TRCE_CATGY   			0x1 /* enable only first level trace */
#define APOS_HA_DFLT_TRCE_DIR 				"/var/log/acs/tra/logging/"  /* referred from config file.*/
#define APOS_HA_DFLT_X_TIMES				3
#define APOS_HA_DFLT_Y_MSECS				1000 /* in milli secs */
#define APOS_HA_DFLT_REBOOT_TMOUT  			3000 /* in milli secs */
#define APOS_HA_DFLT_IP_ADDR				"0.0.0.0"
#define	APOS_HA_DFLT_IP_INTF				"eth0"
#define	APOS_HA_DFLT_IP_COUNT				0
#define	APOS_HA_DFLT_CALLBACK_TMOUT			90000  	/* in milli secs 	*/
#define	APOS_HA_DFLT_REBOOT_COUNT			3  		/* number of reboots*/
#define APOS_HA_DFLT_DRBD_SUPERVISION_INTVL	2000	/* in milli secs 	*/

/* --*-- Command Options --*-- */
#define APOS_HA_CMD_ASSEMBLE_OPTS			" --assemble --mount &>/dev/null"
#define APOS_HA_CMD_ASSEMBLE_FORCE_OPTS		" --assemble --mount --force &>/dev/null"
#define APOS_HA_CMD_DISABLE_OPTS			" --disable --unmount &>/dev/null"
#define APOS_HA_CMD_ACTIVATE_OPTS			" --activate --force &>/dev/null"
#define APOS_HA_CMD_DEACTIVATE_OPTS			" --deactivate --force &>/dev/null"
#define APOS_HA_CMD_ACTIVATE_MIP_OPTS		" --activate-mips &>/dev/null"
#define APOS_HA_CMD_DEACTIVATE_MIP_OPTS		" --deactivate-mips &>/dev/null"
#define APOS_HA_CMD_GET_MIP_INFO_OPTS		" --mip-info"

/* --*-- Signal Section --*-- */
#define EVENT_REBUILD 						ACE_SIGRTMIN+1

//==========================================================================
// char constant delcaration
//==========================================================================
const char* const app_name					= "apos_ha_rdeagentd";

//==========================================================================
//	typedef declarations 
//==========================================================================

typedef enum {
	APOS_HA_SUCCESS=0,
	APOS_HA_FAILURE=1
} APOS_HA_ReturnType;

typedef enum {
	AGENT_SHUTDOWN=0,
	ROLEMGR_CLOSE=1,
	DRBDMON_TIMEOUT=2,
	DRBDMON_CLOSE=3
} APOS_HA_Msgs;

typedef enum {
    APOS_HA_NODE_ONE=1,
    APOS_HA_NODE_TWO=2
} APOS_HA_Nodes;

typedef enum {
	APOS_HA_NODE_VIRTUAL = 3
} APOS_HA_Node_Architectures;

typedef enum {
	APOS_HA_ADMIN_UNLOCK=1,
	APOS_HA_ADMIN_LOCK=2,
	APOS_HA_ADMIN_LOCK_IN=3
} APOS_HA_AdminStates;

typedef enum {
	DRBD_DISK_HEALTHY=1,
	DRBD_DISK_FAULTY=2,	
	DRBD_ROLE_CHANGE=3,
	DRBD_CONN_ERROR=4
} HA_DEVMON_MsgTypeT;

typedef struct {
	bool	isConfigured;
	ACE_TCHAR cstate[16];
	ACE_TCHAR role[16];
	ACE_TCHAR dstate[16];
	ACE_TCHAR diskinfo[256];
} DRBD_InfoT;

typedef struct {
	HA_DEVMON_MsgTypeT type;	
	ACE_UINT32 size;
	DRBD_InfoT *data;
} HA_DEVMON_MsgT; 

typedef struct {
	ACE_TCHAR** ipAddress;
	ACE_TCHAR** interface;
	ACE_UINT32 size;
} APOS_HA_MipInfoT;

typedef struct {
	ACE_TCHAR cstate[16];
	ACE_UINT32 rebootCount;
} HA_AGENT_PersistantInfoT;

typedef struct {

	ACE_UINT32 xtimes;
	// Actual number of times to try arping/ping

	ACE_UINT32 ysecs;
	// Milli seconds in delay between two ARP/PING requests

	ACE_UINT64 traceMask;
	// Enable tracing dynamically

	ACE_UINT32 rebootTmout;
	// Milling seconds to wait for the node to reboot once issued

	ACE_UINT32 rebootCount;
	// Number of times node should be rebooted in case of invalid connection state

	ACE_TCHAR* traceDir;
	// Change traceDir dynamically

	ACE_UINT32 callbackTmout;
	// Command execution timeout

	ACE_UINT32 drbdSupervisionIntvl;
	// Milli seconds after which data disk is to be supervised for connection state

	APOS_HA_MipInfoT mipInfo;
	// IP Address and interface information for set of IPs
	// to which arping/ping request should be sent

} HA_AGENT_ConfigT;

#endif
//==========================================================================
