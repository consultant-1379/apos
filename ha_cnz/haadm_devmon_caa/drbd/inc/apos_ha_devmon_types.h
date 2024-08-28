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
 * @file apos_ha_devmon_types.h
 *
 * @brief
 *
 * This file defines all the enums, structures and macros
 * used by the other classes in Devmon
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_DEVMON_TYPES_H
#define APOS_HA_DEVMON_TYPES_H

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

#define APOS_HA_FILE_NODE_ID		"/etc/cluster/nodes/this/id"
#define APOS_HA_DEVMON_FILE_CNFG	"/opt/ap/apos/conf/apos_ha_devmond.conf"
#define APOS_HA_FILE_PROC_DRBD		"/proc/drbd"

/* --*-- General Section --*-- */
#define APOS_HA_CMD_LEN				100 
#define APOS_HA_GEP_ONE 			1
#define APOS_HA_GEP_ONE_STR 		"GEP1"
#define APOS_HA_GEP_TWO 			2
#define APOS_HA_GEP_TWO_STR 		"GEP2"
#define APOS_HA_DEVMON_2_AGENT_PIPE "/var/run/ap/fifo_devmon2agent"
#define APOS_HA_ONESEC_IN_MILLI     1000 /* 1 sec = 1000 milli*/
#define APOS_HA_DEVMON_LOG_FILE     "devmond.log" 

/* --*-- Command Section --*-- */
#define APOS_HA_CMD_HWTYPE 			"/opt/ap/apos/conf/apos_hwtype.sh"
#define APOS_HA_CMD_DDMGR			"/opt/ap/apos/bin/raidmgr"

/* --*-- Config Defaults --*-- */
#define APOS_HA_DFLT_TRCE_CATGY   	0x1 /* enable full trace */
#define APOS_HA_DFLT_TRCE_DIR 		"/var/log/acs/tra/logging/"   /* hardcode for now.*/
#define APOS_HA_DFLT_QUERY_INTERVAL	2000  /* in milli secs */
#define APOS_HA_DFLT_REBOOT_TMOUT   3000  /* in milli secs */
#define APOS_HA_DFLT_CALLBACK_TMOUT 90000 /* in milli secs */

/* --*-- Command Options --*-- */
#define APOS_HA_CMD_RECOVERY_OPTS   " --recover --force &>/dev/null"

//==========================================================================
// char constant delcaration
//==========================================================================
const char* const app_name			= "apos_ha_devmond";

//==========================================================================
//	typedef declarations 
//==========================================================================

typedef enum {
	APOS_HA_SUCCESS=0,
	APOS_HA_FAILURE=1
}APOS_HA_ReturnType;

typedef enum {
	SHUTDOWN=0,
	DRBDMON_CLOSE=1,
	DEVMON_TIMEOUT=2,
	CLOSE=3,
	TIMEOUT=4	
} HA_DEVMON_ShutdownTypes;

typedef enum {
    APOS_HA_NODE_ONE=1,
    APOS_HA_NODE_TWO=2
}APOS_HA_Nodes;

typedef enum {
    DRBD_DISK_HEALTHY=1,
    DRBD_DISK_FAULTY=2,
    DRBD_ROLE_CHANGE=3,
    DRBD_CONN_ERROR=4
} HA_DEVMON_MsgTypeT;

typedef struct {
	bool isConfigured;
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

	ACE_UINT64 traceMask;
	// Enable tracing dynamically

	ACE_TCHAR* traceDir;
	// Change traceDir dynamically
    
	ACE_UINT32 rebootTmout;
	// Milling seconds to wait for the node to reboot once issued
    
	ACE_UINT32	queryInterval;
	// quantum of times in secs in which data disk status is queried.

	ACE_UINT32 callbackTmout;
	// Command execution timeout
    
} HA_DEVMON_ConfigT;

#endif
//==========================================================================
