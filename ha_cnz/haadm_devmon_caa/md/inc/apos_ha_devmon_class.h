/*=================================================================== */
/**
   @file   apos_ha_devmon_class.h

   @brief Header file for datadisk monitor process.
          This module contains all the declarations useful to
          HA_DataDiskStatus class.
   @version 1.0.0
*/
/*
   HISTORY
   This section contains reference to problem report and related
   software correction performed inside this module


   PR           DATE      INITIALS    DESCRIPTION
   -----------------------------------------------------------
   N/A       DD/MM/YYYY     NS       Initial Release
==================================================================== */

/*==============================================================================================
                          DIRECTIVE DECLARATION SECTION
================================================================================================ */

#ifndef APG_DATADISK_STATUS_H
#define APG_DATADISK_STATUS_H

/*==============================================================================================
                        INCLUDE DECLARATION SECTION
================================================================================================ */

#include "apos_ha_devmon_amfclass.h"
#include "apos_ha_devmon_appclass.h"
#include "ace/ACE.h"
#include "ACS_APGCC_AmfTypes.h"
#include "unistd.h"
#include "syslog.h"
#include "ace/Task.h"
#include "ace/OS_NS_poll.h"


/*==============================================================================================
                        CLASS DECLARATION SECTION
================================================================================================ */
/* ============================================================================================= */

/**
      @brief     The ApplicationManager class is responsible for providing common APIs for 

		 APG aplications to integrate with Availability Management Framework of CoreMW.
*/
/*=================================================================== */
#define GEP_ONE 1
#define GEP1STRING "GEP1"
#define GEP_TWO 2
#define GEP2STRING "GEP2"
#define GEP_HWTYPE "/opt/ap/apos/conf/apos_hwtype.sh"
#define CMD_LEN 100 /* includes buff len*/
#define RAID_MGMT_CMD "/usr/bin/raidmgmt"
#define AGENT_PID_FILE "/var/run/apg/apos_ha_rdeagentd.pid"
#define NODE_ID_FILE "/etc/opensaf/slot_id"
#define HA_BASE_CMD "/opt/ap/apos/bin/apos_ha_operations"
#define DISK_NAME_LEN 10
#define SIG_UPDATE_DISK SIGRTMIN+1
#define SIG_UPDATE_RAID SIGRTMIN+2
#define TWO_SECONDS_INTERVAL 2
#define FIVE_SECONDS_INTERVAL 5
#define TEN_SECONDS_INTERVAL 10

class DevMonClass:public APOS_HA_DevMon_AmfClass{

/*=====================================================================
	                        PRIVATE DECLARATION SECTION
==================================================================== */

private:

		ACE_INT32 gep_id;
		ACE_INT32 HaAgentPid;
		ACE_INT32 node_id;
		ACS_APGCC_BOOL	Is_RAIDInfoPopulated;

		typedef struct {
			ACE_TCHAR diskname[DISK_NAME_LEN];
			ACS_APGCC_BOOL Is_healthy;
		}APGHA_DataDiskT;
			
	        typedef struct {
			ACS_APGCC_BOOL Is_healthy;
			APGHA_DataDiskT disk;
			ACS_APGCC_BOOL Is_raidHealthy;
		}APGHA_ControllerT;

		typedef struct {
			APGHA_ControllerT PortOne;
			APGHA_ControllerT PortTwo;
		}APGHA_NodeT;

		APGHA_NodeT Node;
	        devmonClass *m_myClassObj;
	        ACE_UINT32 passiveToActive;
		ACS_APGCC_BOOL Is_Debug;
		void InitializeDevmon();
		ACS_APGCC_ReturnType activateApp();
		ACS_APGCC_ReturnType passifyApp();
		ACS_APGCC_ReturnType shutdownApp();
					
		ACS_APGCC_ReturnType populateDiskInfo();
		ACS_APGCC_ReturnType populateRAIDInfo();
		
		ACS_APGCC_ReturnType setGepId();
		ACS_APGCC_ReturnType getHaAgentPid();
		ACS_APGCC_ReturnType getAgentDebugPid();
		ACS_APGCC_ReturnType setNodeId
					(void);
		ACE_INT32	launch_popen
                                	(const char *command_string,
                                 	ACS_APGCC_BOOL &status);
		
		ACS_APGCC_ReturnType updateDatadiskStatus(void);
		ACS_APGCC_ReturnType checkSCSIControllerStatus(ACS_APGCC_BOOL, ACS_APGCC_BOOL&);
		ACS_APGCC_ReturnType checkAvailableDataDisks(ACS_APGCC_BOOL, ACS_APGCC_BOOL&);
		void msec_sleep(ACE_INT32);
	
/*=====================================================================
	                        PUBLIC DECLARATION SECTION
==================================================================== */
public:

	DevMonClass(const char* daemon_name);
	DevMonClass();
	~DevMonClass(){};


	ACS_APGCC_ReturnType Is_Node_Active();
	ACS_APGCC_BOOL Is_Active;
	ACS_APGCC_BOOL populateStruct;

/*====================================================================
                        PUBLIC ATTRIBUTES
==================================================================== */

/*=================================================================== 
		PUBLIC METHOD
=================================================================== */
/*=================================================================== */
   /**
	@brief	This routine performs the tasks specific to ACTIVE state assignment.
	
	@par	None

	@pre	None

	@pre	None

	@param	previousHAState
		previous state of the process

	@return	Returns SUCCESS/FAILURE

	@exception	None
   */

	ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);

/*=================================================================== */
   /**
	@brief	This routine performs the tasks specific to STANDBY state assignment.
	
	@par	None

	@pre	None

	@pre	None

	@param	previousHAState
		previous state of the process

	@return	Returns SUCCESS/FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
/*=================================================================== */
   /**
	@brief	This routine performs the tasks specific to QUIESING state assignment.
	
	@par	None

	@pre	None

	@pre	None

	@param	previousHAState
		previous state of the process

	@return	Returns SUCCESS/FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
/*=================================================================== */
   /**
	@brief	This routine performs the tasks required to confirm health status to AMF.
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performComponentHealthCheck(void);
/*=================================================================== */
   /**
	@brief	This routine performs the cleanup tasks.
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performComponentTerminateJobs(void);
/*=================================================================== */
   /**
	@brief	This routine performs requried tasks when STATE assignment removed.
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performComponentRemoveJobs(void);
/*=================================================================== */
   /**
	@brief	This routine performs the shutdown operations
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performApplicationShutdownJobs(void);
/*=================================================================== */
   /**
	@brief	This routine performs the tasks specific to QUIESED state assignment.
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
/*=================================================================== */
   /**
	@brief	This routine gets the gep ID(GEP1/GEP2)
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */

	ACE_INT32 getGepId (void) const;
/*=================================================================== */
   /**
	@brief	This routine get the node id(NODE1/NODE2)
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	ACE_INT32 getNodeId (void) const;
/*=================================================================== */
   /**
	@brief	This routine is a entry point for dev monitor thread.
	
	@par	None

	@pre	None

	@pre	None

	@param	None

	@return	Returns ACS_APGCC_SUCCESS/ACS_APGCC_FAILURE

	@exception	None
   */
/*=================================================================== */
	void svc_run(void);
/*=================================================================== */

/*=================================================================== */
	ACS_APGCC_ReturnType Initialize(void);
/*=================================================================== */
	ACS_APGCC_ReturnType monitorRAID(ACS_APGCC_BOOL);
/*=================================================================== */
	ACS_APGCC_ReturnType monitorControllersAndDatadisks(ACS_APGCC_BOOL);
/*=================================================================== */

};	// End of DevMonClass 

#endif /* APG_DATADISK_STATUS_H */

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

