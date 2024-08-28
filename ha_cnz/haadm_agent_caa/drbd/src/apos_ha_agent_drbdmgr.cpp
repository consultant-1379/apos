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
 * @file apos_ha_agent_drbdmgr.cpp
 *
 * @brief
 *
 * This is the main class that handles drbd configuration for data disks.
 * It is an active object that is started by calling drbdStartJobs()
 * and then stopped by calling drbdStopJobs()
 *
 * @author Malangsha Shaik (xmalsha)
 *
 *  Changelog:
 *  - Fri 30 Aug  2020 -Gnaneswara Seshu (ZBHEGNA)
 *		Added retry to check disk state
 *  - Wed 07 July 2015 - Baratam Swetha (XSWEBAR)
 *		  HT82726 - drbd sync in Standalone Secondary case.	

 -------------------------------------------------------------------------*/

#include "apos_ha_agent_drbdmgr.h"

const int max_retry=300;

//-------------------------------------------------------------------------
HA_AGENT_DRBDMgr::HA_AGENT_DRBDMgr():
  m_globalInstance(HA_AGENT_Global::instance()),
  m_aposOpts(0),
  m_assemble_force(false)
{
	HA_TRACE_ENTER();	
    
    HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_DRBDMgr::~HA_AGENT_DRBDMgr()
{
	HA_TRACE_ENTER();	
    
    HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::init()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::drbdStartJobs()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
    
     /* assemble and mount drbd on /data */
    if (assemble() != 0) {
        HA_LG_ER("%s: assemble and mount drbd failed", __func__);
        rCode=-1;
    }
        
    /* Configure MIP */
    if (rCode == 0) {
        if (setMipAddrs() != 0) {
            HA_LG_ER("%s(): Configure MIPs failed", __func__);
            rCode=-1;    
        }
    } 

	if (rCode == 0) {
        /* launch apos-operations to configure vdirs on /data */
		m_aposOpts=const_cast<ACE_TCHAR*>("--startup &>/dev/null");
        if (aposJobs() != 0) {
            HA_LG_ER("%s(): failed to execute aposJobs", __func__);
            rCode=-1;
        }   
    }

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::drbdStopJobs()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
    
	/* disable MIP and stop servers */
	m_aposOpts=const_cast<ACE_TCHAR*>("--failover active &>/dev/null");
	if (aposJobs() != 0) {
		HA_LG_ER("%s(): failed to execute stopAposJobs", __func__);
		rCode=-1;
	}

    /* disable MIPs*/
    if (rCode == 0) {
		if (usetMipAddrs() != 0) {
			HA_LG_ER("%s(): disable MIPs failed", __func__);
			rCode=-1;
		}
	}
    
    /* disable and unmount drbd */
    if (rCode == 0) {
        if (disable() != 0){
            HA_LG_ER("%s(): disable and un-mount drbd failed", __func__);
            rCode=-1;
        }
    }
    
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::drbdHealth(bool OnStart)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	bool found=true;
	string resource = "drbd1";
	string state;
	string disk_role;

	found = m_globalInstance->Utils()->getDiskState(resource,state, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local disk state", __func__);
	}
	  
	found = m_globalInstance->Utils()->getDrbdRole (resource, disk_role, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local drbd role", __func__);
	}
	  	
	if (OnStart) {
		if ((disk_role.compare("Secondary")!=0) && (disk_role.compare("Primary")!=0)) {
			HA_LG_ER("%s(): DRBD role unhealthy, Expecting:[Primary/Secondary] Got:[%s]", __func__, disk_role.c_str());
			rCode=-1;
		}
	} else {
		if (disk_role.compare("Primary")!=0) {
			HA_LG_ER("%s(): DRBD role unhealthy, Expecting:[Primary] Got:[%s]", __func__, disk_role.c_str());
			rCode=-1;
		}
	}	
        int retry=0;
        while(retry < max_retry){
                if (state.compare("UpToDate")==0){
                        break;
                }
		else{
                	sleep(1);
	                //HA_LG_IN("%s(): DRBD disk unhealthy, Expecting:[UpToDate] Got:[%s],retrying...:%d", __func__, state.c_str(),retry);
        	        m_globalInstance->Utils()->getDiskState(resource,state, true);
                	retry++;
		}
        }
        if(retry >= max_retry && state.compare("UpToDate")!=0){
                HA_LG_ER("%s(): DRBD disk unhealthy, Expecting:[UpToDate] Got:[%s]", __func__, state.c_str());
                rCode=-1;
        }	
	
	if (found == false) {
		HA_LG_ER("%s(): Active DRBD resource (drbd1) is not found", __func__);
		rCode=-1;
	}
	
	HA_TRACE_LEAVE();
	return rCode;
}


//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::assemble()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);

	if (m_assemble_force == true) {
		/* After performing the force assemble, we might end up promoting the SyncTarget
		to Primary with Inconsistent disk. There is a probability of data loss.
		*/
		ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_DRBDMGR APOS_HA_CMD_ASSEMBLE_FORCE_OPTS);
	} else {
		ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_DRBDMGR APOS_HA_CMD_ASSEMBLE_OPTS);
	}
	rCode = m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}else {
		if (m_assemble_force) {
			HA_LG_IN("%s(): assemble with force is successfull. This operation might have caused loss of user data", __func__);
			if (this->m_globalInstance->Utils()->removeRCF() < 0){
				HA_LG_ER("%s():remove Reboot Count File failed", __func__);
			}
			set_assemble_force(false);
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::disable()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);

	m_aposOpts=const_cast<ACE_TCHAR*>("--cleanup &>/dev/null");
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_APOS_OPERATIONS" %s", (ACE_TCHAR*)m_aposOpts);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_DRBDMGR APOS_HA_CMD_DISABLE_OPTS);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	HA_TRACE_LEAVE();
	return rCode;
}
//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::activate()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_DRBDMGR APOS_HA_CMD_ACTIVATE_OPTS);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::aposJobs()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_APOS_OPERATIONS" %s", m_aposOpts);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::setMipAddrs()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_APOS_OPERATIONS APOS_HA_CMD_ACTIVATE_MIP_OPTS);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMgr::usetMipAddrs()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	ACE_TCHAR cmdStr[APOS_HA_CMD_LEN];
	ACE_OS::memset(cmdStr, 0, APOS_HA_CMD_LEN);
	ACE_OS::snprintf(cmdStr, APOS_HA_CMD_LEN, APOS_HA_CMD_APOS_OPERATIONS APOS_HA_CMD_DEACTIVATE_MIP_OPTS);

	rCode =  m_globalInstance->Utils()->_execlp(cmdStr);
	if (rCode != 0) {
		HA_LG_ER("%s(): %s failed with errCode: %d", __func__, cmdStr, rCode);
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
void HA_AGENT_DRBDMgr::set_assemble_force(bool flag)
{
	HA_TRACE_ENTER();
	m_assemble_force=flag;
	HA_TRACE_LEAVE();
}
//-------------------------------------------------------------------------


