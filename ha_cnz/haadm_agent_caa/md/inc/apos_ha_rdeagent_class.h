/*============================================================== */
/**
   @file   "apos_ha_rdeagent_class.h"

   @brief 
          
          
   @version 1.0.0
*/
/*
   HISTORY
   
   


   PR           DATE      INITIALS    DESCRIPTION
   -------------------------------------------------------------
   N/A       DD/MM/YYYY     NS       Initial Release
   ============================================================= */

/*==============================================================
                          DIRECTIVE DECLARATION SECTION
================================================================ */


#ifndef APG_HA_RDEAGENT_H
#define APG_HA_RDEAGENT_H

//#include "apos_ha_rdahooks.h"
#include "ace/ACE.h"
#include <saImmOm.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include "ACS_APGCC_AmfTypes.h"
#include "apos_ha_rdeagent_amfclass.h"
#include "poll.h"
#include "apos_ha_rdeagent_utils.h"
#include "apos_ha_rdeagent_tipc.h"

/*===============================================================
                          DIRECTIVE DECLARATION SECTION
================================================================= */
#define RDA_MAX_CLIENTS  5
#define DEFLT_POLL_INTERVAL  1000 /* in milli secs */
#define DEFLT_X_TIMES 3
#define DEFLT_Y_MSECS 3000 /* in milli secs */	 
#define DEFALT_THREAD_FREQ 3000 /* in milli secs */
#define CMD_LEN 100 /* includes buff len*/
#define CSI_TIMEOUT 20 /* time out in secs */
#define GEP_ONE 1
#define GEP1STRING "GEP1"
#define GEP_TWO 2
#define GEP2STRING "GEP2"
#define GEP_HWTYPE "/opt/ap/apos/conf/apos_hwtype.sh"
#define RDAGNT_CONF_FILE "/opt/ap/apos/conf/apos_ha_rdeagent.conf"
#define SCSI_BASE_CMD "/opt/ap/apos/bin/apos_ha_scsi_operations"
#define HA_BASE_CMD "/opt/ap/apos/bin/apos_ha_operations"
#define APOS_BASE_CMD "/opt/ap/apos/bin/apos_operations"
#define NODE_LOCK_FILE "/var/lock/subsys/node.lock"
#define DISK_MGMT_CMD "/usr/bin/raidmgmt"
#define DISK_MGMT_CMD_LEN 50 /* includes buff len */
#define NODE_ID_FILE "/etc/opensaf/slot_id"
#define STORAGE_FIND_PATH "cat /usr/share/pso/storage-paths/config"
#define DISK_NAME_LEN 10
#define SIG_UPDATE_DISK SIGRTMIN+1
#define SIG_UPDATE_RAID SIGRTMIN+2
#define MAX_ATTEMPTS 3

/*===============================================================
                          CLASS DECLARATION SECTION
================================================================= */
using namespace std;

class APGHA_RDEAgent:public APOS_HA_RdeAgent_AmfClass {

private:
		
	typedef struct {
		ACE_TCHAR diskname[DISK_NAME_LEN];
		ACS_APGCC_BOOL Is_healthy;
		ACS_APGCC_BOOL Is_registered;
		ACS_APGCC_BOOL Is_reserved;
	}APGHA_DataDiskT;	
	
	typedef struct {
		ACS_APGCC_BOOL Is_healthy;
		APGHA_DataDiskT disk;
	}APGHA_ControllerT;	
	
	APGHA_ControllerT PortOne;
	APGHA_ControllerT PortTwo;

	typedef struct {
		APGHA_ControllerT PortOne;
		APGHA_ControllerT PortTwo;
	}APGHA_NodeT;

	APGHA_NodeT NodeA;
	APGHA_NodeT NodeB;

	ACE_INT32 node_id;
	ACE_INT32 gep_id;
	ACS_APGCC_BOOL backPlaneUp;
	ACS_APGCC_BOOL IsMIPConfigured;
        ACS_APGCC_BOOL IsRAIDConfigured;
        ACS_APGCC_BOOL Is_Agent_Stanby;
        ACS_APGCC_BOOL Is_State_Assgned;
	
	/* following three are filled from config file*/
	ACE_UINT64 diskRenewalThreadFreq;
	ACE_UINT64 renewDiskRegCounter;
	ACE_UINT64 Y_Msecs;
	ACE_UINT32 X_Times;

	static const char *role_string[];
	static ACE_INT32 logCounter;

	ACS_APGCC_ReturnType launchCommand
				(char *command_string);
	ACE_INT32	launch_popen
				(const char *command_string,
				 ACS_APGCC_BOOL &status);

	ACS_APGCC_ReturnType checkSCSIControllerStatus
						(void);

	ACS_APGCC_ReturnType checkAvailableDataDisks
						(void);
	ACS_APGCC_ReturnType updateDatadisksWithRaidDisks
							(void);		

	ACS_APGCC_ReturnType registerReachableDataDisks
						(void);

	ACS_APGCC_ReturnType registerDataDisk 
					(ACE_TCHAR* diskname);
	
	ACS_APGCC_ReturnType reserveDatadisk
					(ACE_TCHAR* diskname);

	ACS_APGCC_ReturnType checkDiskPRGenerationCounter
					( ACE_TCHAR* diskname,
				  	  ACS_APGCC_BOOL &counterChange);

	ACS_APGCC_ReturnType releaseDataDiskReservation
					(ACE_TCHAR* diskname);
	
	ACS_APGCC_ReturnType releaseDataDiskRegistrations
					(ACE_TCHAR* diskname);

	ACS_APGCC_ReturnType preemptDataDisk
					(ACE_TCHAR* diskname);

	ACS_APGCC_ReturnType dataDiskReservationAlgo
						(void);


	ACS_APGCC_ReturnType mountRAIDandActivateMIPs
						(ACS_APGCC_BOOL OnStart);
	ACS_APGCC_ReturnType umountRAIDandDeactivateMIPs
						(void);

	ACS_APGCC_ReturnType setNodeId 
				(void);

	ACS_APGCC_ReturnType updateDiskStatusFile
					(void);

	ACS_APGCC_ReturnType setGepId
				(void);

	ACE_TCHAR* gettoken(char *str, unsigned char tok);

	ACS_APGCC_ReturnType releaseBothDatadiskReservations
							(void); 

	ACS_APGCC_ReturnType releaseBothDatadiskRegistrations
							(void);

	ACS_APGCC_BOOL IsActiveStateTransitionAllowed
						(void);	
	ACS_APGCC_ReturnType	updateBothNodeDisknControllerstatus
								(void);
	
	ACS_APGCC_ReturnType updatePortStatus
					(APGHA_NodeT *Node, ACE_UINT32 node_id);
	
	void Initialize_Agent();
	ACS_APGCC_ReturnType ActiveJobsDebug();
	ACS_APGCC_ReturnType StandbyJobsDebug();
	ACS_APGCC_ReturnType ShutdownJobsDebug();

protected:
		
public:

	// Constructor
	APGHA_RDEAgent();
	APGHA_RDEAgent(const char* daemon_name, const char* user_name);
	ACS_APGCC_ReturnType ExecuteDebug();
	// Destructor
	~APGHA_RDEAgent();

	/* FD SET*/
	enum {
        	FD_AMF = 0,	
		FD_RT = 1,
		FD_HUP = 2,
		FD_TERM = 3,
		FD_iTimer = 4,
		FD_TIPC=5,
		FD_INT=6
	};

	struct pollfd fds[7];
	static ACS_APGCC_SEL_OBJ term_sel_obj;
	static ACS_APGCC_SEL_OBJ sigrt_sel_obj;
	static ACS_APGCC_SEL_OBJ sighup_sel_obj;
	static ACS_APGCC_SEL_OBJ sigint_sel_obj;
	static ACS_APGCC_SEL_OBJ iTimer_sel_obj;
	static ACS_APGCC_RDARoleT rdeServerRoleReceived;

	ACS_APGCC_BOOL terminateRdeAgent;
	static ACS_APGCC_BOOL sigterm_received;
	static ACS_APGCC_BOOL sigint_received;
	static ACS_APGCC_BOOL update_datadisk_info;
	static ACS_APGCC_BOOL update_raid_info;
	static ACS_APGCC_BOOL debugEnabled;
	ACS_APGCC_BOOL handleRdeAgentGracefullDownJobsDone;
	ACS_APGCC_BOOL initiateFailover;
	ACS_APGCC_BOOL IsDebug;

	static 	ACS_APGCC_AgentUtils utils;
		ACS_APGCC_AgentMsging tipcObj;

	ACS_APGCC_ReturnType 	InitializeRdeAgentEngine 
						(void);
	ACS_APGCC_ReturnType	Initialize_rdaLib 
					(void);

	ACS_APGCC_ReturnType 	rda_finalize 
					(void); 
	ACS_APGCC_ReturnType	renewDatadiskRegistrations
						(void);
	static void 		sigusr1Handler
						(int sig);
	static void 		sigintHandler
						(int sig);
	static void 		updateDiskStatusHandler
						(int sig);
	static void 		updateRaidStatusHandler
						(int sig);
	static void 		AgentShutdownHandler
					(int sig);

	static void 		sighupHandler
					(int sig);

	static void		iTimerHandler
					(ACE_INT32 sigNum);
	ACS_APGCC_ReturnType iTimerInit
				(void);

	ACS_APGCC_ReturnType readConfig();

	ACE_INT32 		getNodeId
					(void) const;

	ACE_INT32		getGepId
					(void) const;

	void 			reboot_local_node
					(void);

        void    InitiateFailover
                        (ACS_APGCC_AMF_RecommendedRecoveryT);

	ACS_APGCC_ReturnType iTimerTimeoutHandler
					(void);
	void msec_sleep (ACE_INT32 time_in_msec);
	
	ACS_APGCC_ReturnType updateDeviceStatus
					(void);
	ACS_APGCC_ReturnType performStateTransitionToActiveJobs 
					(ACS_APGCC_AMF_HA_StateT PreviousState);
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs 
					(ACS_APGCC_AMF_HA_StateT PreviousState);
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs 
					(ACS_APGCC_AMF_HA_StateT PreviousState);
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs
					(ACS_APGCC_AMF_HA_StateT PreviousState);
	ACS_APGCC_ReturnType performComponentHealthCheck 
					(void) ;
	ACS_APGCC_ReturnType performComponentTerminateJobs
					(void);
	ACS_APGCC_ReturnType performComponentRemoveJobs
					(void);
	ACS_APGCC_ReturnType performApplicationShutdownJobs
					(void);
	ACS_APGCC_ReturnType handleRdeAgentGracefullDownJobs
					(void);
};

#endif /* end APG_HA_RDEAGENT_H*/

//----------------------------------------------------------------------------
//
//  COPYRIGHT Ericsson AB 2010
//
//  The copyright to the computer program(s) herein is the property of
//  ERICSSON AB, Sweden. The programs may be used and/or copied only
//  with the written permission from ERICSSON AB or in accordance with
//  the terms and conditions stipulated in the agreement/contract under
//  which the program(s) have been supplied.
//
//----------------------------------------------------------------------------


