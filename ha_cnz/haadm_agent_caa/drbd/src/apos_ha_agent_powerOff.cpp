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
 * @file apos_ha_agent_poweroff.cpp
 *
 * @brief
 *
 * This class is used to handle the power-off scenarios.
 * @author Tanu Aggarwal (xtanagg)
 *
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_powerOff.h"

//-------------------------------------------------------------------------
HA_AGENT_PWROff::HA_AGENT_PWROff():
 m_fd(-1),
 m_map(0),
 m_globalInstance(HA_AGENT_Global::instance())
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_PWROff::~HA_AGENT_PWROff()
{
	HA_TRACE_ENTER();

	if (munmap(m_map, sizeof(HA_AGENT_PersistantInfoT)) == -1) {
		HA_LG_ER("%s(): munmap failed", __func__);
	}
	close(m_fd);

	m_map=0;

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_PWROff::init() 
{
	HA_TRACE_ENTER();
	int rCode=0;

	struct stat buf;
	if (stat(APOS_HA_FILE_AGENT_PSST_INFO, &buf) == 0) {
		m_fd = ::open(APOS_HA_FILE_AGENT_PSST_INFO, O_RDWR,
				S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		if (m_fd < 0) {
			HA_LG_ER("%s(): file: %s open failed", __func__, APOS_HA_FILE_AGENT_PSST_INFO);
			rCode=-1;
		}
		if (rCode == 0) {
			int result = lseek(m_fd, sizeof(HA_AGENT_PersistantInfoT)-1, SEEK_SET);
			if (result == -1) {
				HA_LG_ER("%s(): file: %s lseek failed", __func__, APOS_HA_FILE_AGENT_PSST_INFO);
				rCode=-1;
			}
		}
		if (rCode == 0) {
			int noOfBytes=write(m_fd, "", 1);
			if (noOfBytes != 1) {
				HA_LG_ER("%s(): error in write",__func__);
				rCode=-1;
			}
		}
		if (rCode == 0) {
			m_map = (HA_AGENT_PersistantInfoT *)mmap(0, sizeof(HA_AGENT_PersistantInfoT), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
			if (m_map == MAP_FAILED) {
				HA_LG_ER("%s(): error in mmap", __func__);
				rCode=-1;
			}
		}
	} else {
		m_fd = ::open(APOS_HA_FILE_AGENT_PSST_INFO, O_RDWR | O_CREAT,
				S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		if (m_fd < 0) {
			HA_LG_ER("%s(): file: %s open failed", __func__, APOS_HA_FILE_AGENT_PSST_INFO);
			rCode=-1;
		}

		int result = lseek(m_fd, sizeof(HA_AGENT_PersistantInfoT)-1, SEEK_SET);
		if (result == -1) {
			HA_LG_ER("%s(): file: %s lseek failed", __func__, APOS_HA_FILE_AGENT_PSST_INFO);
			rCode=-1;
		}

		if (rCode == 0) {
			int noOfBytes=write(m_fd, "", 1);
			if (noOfBytes != 1) {
				HA_LG_ER("%s(): error in write",__func__);
				rCode=-1;
			}
		}
			
		if (rCode == 0) {
			m_map = (HA_AGENT_PersistantInfoT*)mmap(0, sizeof(HA_AGENT_PersistantInfoT), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
			if (m_map == MAP_FAILED) {
				HA_LG_ER("%s(): error in mmap", __func__);
				rCode=-1;
			}
		}

		if (rCode == 0) {
			DRBD_InfoT drbdInfo;
			if (this->drbdinfo(drbdInfo) == 0) {
					HA_AGENT_PersistantInfoT persisInfo;
					strcpy( persisInfo.cstate, drbdInfo.cstate);
					persisInfo.rebootCount = 0;
					HA_TRACE_1("HA_AGENT_PWROff:%s() cstate:%s, rebootCount:%d", __func__,
						persisInfo.cstate, persisInfo.rebootCount);
					if (this->write_persis_info(persisInfo) != true) {
						HA_LG_ER("%s(): error in write_persis_info", __func__);
						rCode=-1;
				}
			}
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
bool HA_AGENT_PWROff::get_persis_info(HA_AGENT_PersistantInfoT &persisInfo)
{
	HA_TRACE_ENTER();
	bool rCode=true;

	/* copy the contents of file in cstate */
	strcpy(persisInfo.cstate, m_map->cstate);
	persisInfo.rebootCount = m_map->rebootCount;
    HA_TRACE_1("HA_AGENT_PWROff:%s, cstate:%s , rebootCount:%d from file", __func__, 
				persisInfo.cstate, persisInfo.rebootCount);

	HA_TRACE_LEAVE();
	return rCode;
}	

//-------------------------------------------------------------------------
bool HA_AGENT_PWROff::write_persis_info(const HA_AGENT_PersistantInfoT &persisInfo)
{
	HA_TRACE_ENTER();
	bool rCode=true;

	if (m_map != 0) {
		HA_TRACE_1("HA_AGENT_PWROff:%s() cstate:%s, rebootCount:%d", __func__, 
			persisInfo.cstate, persisInfo.rebootCount);
		memset(m_map, 0, sizeof(HA_AGENT_PersistantInfoT));
		strcpy(m_map->cstate, persisInfo.cstate);
		m_map->rebootCount = persisInfo.rebootCount;
	}
	else {	
		HA_TRACE_1("HA_AGENT_PWROff:%s, m_map zero found", __func__);
	}
	
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_PWROff::drbdinfo(DRBD_InfoT &drbdInfo)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	bool found=true;
	string resource = "drbd1";
	string cstate;
	string dstate;
	string role;

	/*initialize the structure*/
	memset(&drbdInfo, 0, sizeof(DRBD_InfoT));
	
	// Get Connected state
	found = m_globalInstance->Utils()->getConnectedState(resource,cstate);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the connection state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getConnected status for %s success with output =%s ", __func__, resource.c_str(), cstate.c_str());
		strncpy(drbdInfo.cstate, cstate.c_str(), sizeof(drbdInfo.cstate));
		drbdInfo.cstate[sizeof(drbdInfo.cstate) - 1] = 0;			
	}	
	
		

	// Get Local Role
  	found = m_globalInstance->Utils()->getDrbdRole(resource,role, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local role", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDrbdRole(local) status for %s success with output =%s ", __func__, resource.c_str(), role.c_str());
		strncpy(drbdInfo.role, role.c_str(), sizeof(drbdInfo.role));
		drbdInfo.role[sizeof(drbdInfo.role) - 1] = 0;			
	}	
  

	// Get Local Disk State 
  	found = m_globalInstance->Utils()->getDiskState(resource,dstate, true);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the local disk state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDiskState (local) status for %s success with output =%s ", __func__, resource.c_str(), dstate.c_str());
		strncpy(drbdInfo.dstate, dstate.c_str(), sizeof(drbdInfo.dstate));
		drbdInfo.dstate[sizeof(drbdInfo.dstate) - 1] = 0;			
	}	

	if (rCode == -1) {
		HA_LG_ER("%s(): Active DRBD resource (drbd1) is not found", __func__);
		drbdInfo.isConfigured=false;
	}else 
	{
		drbdInfo.isConfigured=true;
	}

    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_PWROff::peerdrbdinfo(DRBD_InfoT &drbdInfo)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	bool found=true;
	string resource = "drbd1";
	string cstate;
	string dstate;
	string role;
	

	/*initialize the structure*/
	memset(&drbdInfo, 0, sizeof(DRBD_InfoT));
	

	// Get Connected state
	found = m_globalInstance->Utils()->getConnectedState(resource,cstate);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the connection state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getConnected status for %s success with output =%s ", __func__, resource.c_str(), cstate.c_str());
		strncpy(drbdInfo.cstate, cstate.c_str(), sizeof(drbdInfo.cstate));
		drbdInfo.cstate[sizeof(drbdInfo.cstate) - 1] = 0;			
	}	
	
  
	// Get Disk Peer Role
  	found = m_globalInstance->Utils()->getDrbdRole(resource,role, false);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the disk peer role", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDrbdRole(disk-peer) status for %s success with output =%s ", __func__, resource.c_str(), role.c_str());
		strncpy(drbdInfo.role, role.c_str(), sizeof(drbdInfo.role));
		drbdInfo.role[sizeof(drbdInfo.role) - 1] = 0;			
	}	

	// Get Peer-Disk State 
  	found = m_globalInstance->Utils()->getDiskState(resource,dstate, false);
	if (!found) {
			HA_LG_ER("%s(): ERROR fetching the peer disk state", __func__);
			rCode = -1;
	}else {
		HA_TRACE_1("%s(): getDiskState (peer-disk) status for %s success with output =%s ", __func__, resource.c_str(), dstate.c_str());
		strncpy(drbdInfo.dstate, dstate.c_str(), sizeof(drbdInfo.dstate));
		drbdInfo.dstate[sizeof(drbdInfo.dstate) - 1] = 0;			
	}	
	
	
	if (rCode == -1) {
		HA_LG_ER("%s(): Active DRBD resource (drbd1) is not found", __func__);
		drbdInfo.isConfigured=false;
	}else 
	{
		drbdInfo.isConfigured=true;
		HA_TRACE("%s()- conn:[%s], peer:[%s], pdsk:[%s]:, isConfigured:[%d]", __func__, drbdInfo.cstate, drbdInfo.role, drbdInfo.dstate, drbdInfo.isConfigured);
	}
	
	
	 HA_TRACE_LEAVE();


    return rCode;
}
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

