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
 * @file apos_ha_devmon_drbdmgr.cpp
 *
 * @brief
 *
 * This is the main class that handles drbd configuration for data disks.
 * It process the drbd data from proc/drbd file and sends information
 * to DRBDMon and DRBDRecovery files
 * 
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_devmon_drbdmgr.h"

//-------------------------------------------------------------------------
HA_DEVMON_DRBDMgr::HA_DEVMON_DRBDMgr():
  m_globalInstance(HA_DEVMON_Global::instance()),m_cstate(),m_ldisk(),m_role(),m_rdisk(),m_diskinfo()
{
	HA_TRACE_ENTER();
	m_msgInfo.data = 0;
	m_msgInfo.type = DRBD_DISK_HEALTHY;
	m_msgInfo.size = 0;
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_DEVMON_DRBDMgr::~HA_DEVMON_DRBDMgr()
{
	HA_TRACE_ENTER();	
	if ( this->m_msgInfo.data != 0) {
		delete this->m_msgInfo.data;
		this->m_msgInfo.data=0;
	}
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_DEVMON_DRBDMgr::init()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	/* allocate memory for m_msgInfo-data */
	ACE_NEW_NORETURN(this->m_msgInfo.data, DRBD_InfoT);
	if (this->m_msgInfo.data == 0) {
		HA_LG_ER("HA_DEVMON_DRBDMgr: Memory Allocation failed for DRBD_InfoT");
		rCode=-1;
	}
	if (rCode == 0) {
		m_msgInfo.size = sizeof(DRBD_InfoT);
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_DRBDMgr::isdegraded()
{
	HA_TRACE_ENTER();
	int rCode=0;
	bool isConfigured=true;
	if(this->parse_proc_drbd() != 0) {
		 HA_LG_ER("HA_DEVMON_DRBDMgr: failed to process /proc/drbd send info to agent");
		 isConfigured=false;
		 //No need to check for states return as disk not degraded
		 //isactive function will inform to drbdmon which informs to agent about unconfigured state
	}
	if(isConfigured){
		if ((strcmp(m_cstate,"Connected")==0) &&
			(strcmp(m_role,"Primary") == 0)   &&
		   	(strcmp(m_ldisk,"UpToDate") == 0) &&
			((strcmp(m_rdisk,"Inconsistent") == 0) || (strcmp(m_rdisk,"Outdated") == 0))) {
				rCode=1;
		}
		if (((strcmp(m_cstate,"SyncSource")==0) || (strcmp(m_cstate,"SyncTarget")==0))) {
			HA_TRACE("HA_DEVMON_DRBDMgr:In Synchronization State");
		}
	}
	HA_TRACE_LEAVE();	
	return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_DRBDMgr::recovery()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_DDMGR APOS_HA_CMD_RECOVERY_OPTS);
	rCode = m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}else {
		HA_TRACE("HA_DEVMON_DRBDMgr: Recovery Successful");
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//----------------------------------------------------------------------
int HA_DEVMON_DRBDMgr::isactive()
{
	HA_TRACE_ENTER();
	int rCode=1;
	bool isConfigured=true;
	memset(m_msgInfo.data,0,sizeof(DRBD_InfoT));
	if(this->parse_proc_drbd()!= 0) {
		HA_LG_ER("HA_DEVMON_DRBDMgr: failed to process /proc/drbd");
		isConfigured=false;
		(((DRBD_InfoT*)(m_msgInfo.data))->isConfigured)=false;
	}
	if(isConfigured) {
		if (((strcmp(m_ldisk,"Consistent") != 0) && (strcmp(m_ldisk,"UpToDate") != 0)) || (strcmp(m_rdisk,"UpToDate")!=0)) {
				m_msgInfo.type=DRBD_DISK_FAULTY;
				rCode=0;
			}else {
				m_msgInfo.type=DRBD_DISK_HEALTHY;
			}
		if ((strcmp(m_role,"Primary") != 0)) {
			m_msgInfo.type=DRBD_ROLE_CHANGE;
			rCode=0;
		} 
		if ((strcmp(m_cstate,"Connected") !=0 )) {
			m_msgInfo.type=DRBD_CONN_ERROR;
			rCode=0;
		}
		(((DRBD_InfoT*)(m_msgInfo.data))->isConfigured)=true;
		strcpy(((DRBD_InfoT*)(m_msgInfo.data))->cstate,m_cstate);
		strcpy(((DRBD_InfoT*)(m_msgInfo.data))->role,m_role);
		strcpy(((DRBD_InfoT*)(m_msgInfo.data))->dstate,m_ldisk);
		strcpy(((DRBD_InfoT*)(m_msgInfo.data))->diskinfo,m_diskinfo);
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
HA_DEVMON_MsgT& HA_DEVMON_DRBDMgr::fillMsg()
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
	return (m_msgInfo);
}

//-------------------------------------------------------------------------
int HA_DEVMON_DRBDMgr::parse_proc_drbd()
{
	HA_TRACE_ENTER();
	int rCode=0;
	bool found=true;
	string resource = "drbd1";
	string cstate;
	string dstate;
	string role;
	
	// Get connection state
	found = m_globalInstance->Utils()->getConnectedState(resource,cstate);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the connection state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getConnected status for %s success with output =%s ", __func__, resource.c_str(), cstate.c_str());
		strncpy(m_cstate, cstate.c_str(), sizeof(m_cstate));
		m_cstate[sizeof(m_cstate) - 1] = 0;			
	}		
	
    // Get local Role
  	found = m_globalInstance->Utils()->getDrbdRole(resource,role, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local role", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDrbdRole(local) status for %s success with output =%s ", __func__, resource.c_str(), role.c_str());
		strncpy(m_role, role.c_str(), sizeof(m_role));
		m_role[sizeof(m_role) - 1] = 0;			
	}

	// Get local disk state  
  	found = m_globalInstance->Utils()->getDiskState(resource,dstate, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local disk state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDiskState (local) status for %s success with output =%s ", __func__, resource.c_str(), dstate.c_str());
		strncpy(m_ldisk, dstate.c_str(), sizeof(m_ldisk));
		m_ldisk[sizeof(m_ldisk) - 1] = 0;			
	}	
	
	// Get Peer-Disk State 
  	found = m_globalInstance->Utils()->getDiskState(resource,dstate, false);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the peer disk state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDiskState (peer-disk) status for %s success with output =%s ", __func__, resource.c_str(), dstate.c_str());
		strncpy(m_rdisk, dstate.c_str(), sizeof(m_rdisk));
		m_rdisk[sizeof(m_rdisk) - 1] = 0;			
	}
	
	if (rCode == -1) {
		HA_LG_ER("%s(): drbd1 not found failed", __func__);		
	}
		
	HA_TRACE_LEAVE();
	return rCode;
}
//-------------------------------------------------------------------------

void HA_DEVMON_DRBDMgr :: reset()
{
	HA_TRACE_ENTER();
	HA_TRACE(" HA_DEVMON_DRBDMgr:Resetting the class level values");
	int counter=0;
	for(counter=0;counter<15;counter++){
		m_cstate[counter]='\0';
		m_role[counter]='\0';
		m_rdisk[counter]='\0';
		m_ldisk[counter]='\0';
	}
	for(counter=0;counter<255;counter++){
		m_diskinfo[counter]='\0';
		}
	HA_TRACE_LEAVE();
}
//------------------------------------------------------------------------------
