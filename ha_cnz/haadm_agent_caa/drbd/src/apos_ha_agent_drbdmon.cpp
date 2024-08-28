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
 * @file apos_ha_agent_drbdmon.cpp
 *
 * @brief
 *
 * This class is used to monitor drbd1.
 * @author Tanu Aggarwal (xtanagg)
 *
 *  Changelog:
 *  - Wed 07 July 2015 - Baratam Swetha (XSWEBAR)
 *                HT82726 - drbd sync in Standalone Secondary case. 
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_drbdmon.h"

//-------------------------------------------------------------------------
HA_AGENT_DRBDMon::HA_AGENT_DRBDMon():
 m_globalInstance(HA_AGENT_Global::instance()),
 m_reactorRunner(0),
 m_reactor(0),
 m_timerid(-1),
 m_rebuildInProgress(false)
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_DRBDMon::~HA_AGENT_DRBDMon()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMon::open()
{
	HA_TRACE_ENTER();
	int rCode=0;

	/* start the thread */
	if (rCode == 0) {
		if (this->activate(THR_NEW_LWP|THR_JOINABLE) < 0) {
			HA_LG_ER("%s() - Failed to start main svc thread.", __func__);
			rCode=-1;
		}
	}
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMon::init() 
{
	HA_TRACE_ENTER();
	int rCode=0;

	/* create a ACE Reactor*/
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_reactor, ACE_Reactor());
		if (0 == this->m_reactor) {
			HA_LG_ER("HA_AGENT_DRBDMon:%s() - MEMORY PROBLEM: Failed to allocate ACE_Reactor", __func__);
			rCode=-1;
		}
	}

	/* create the reactor instance */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_reactorRunner, APOS_HA_ReactorRunner(this->m_reactor, DRBDMON_REACTOR));
		if (0 == this->m_reactorRunner) {
			HA_LG_ER("HA_AGENT_DRBDMon:%s() - MEMORY PROBLEM: Failed to allocate APOS_HA_ReactorRunner", __func__);
			rCode=-1;
		} else {
			rCode= this->m_reactorRunner->open();
			if (rCode != 0) {
				HA_LG_ER("HA_AGENT_DRBDMon:%s() - Reactor open failed", __func__);
				rCode=-1;
			}
		}
	}

	/* schedule the timer */
	if (rCode == 0) {
		const ACE_Time_Value schedule_time(m_globalInstance->Config()->getConfig().drbdSupervisionIntvl/APOS_HA_ONESEC_IN_MILLI, 0);
		m_timerid = this->m_reactor->schedule_timer(this, 0, schedule_time);
		if (m_timerid < 0) {
			HA_LG_ER("HA_AGENT_DRBDMon:%s() - Unable to schedule timer.", __func__);
			rCode=-1;
		 }
    }
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_DRBDMon::svc()
{
	HA_TRACE_ENTER();
	int rCode=0;
	ACE_Message_Block* mb = NULL;
	bool running = true;
	bool errorDetected=false;

	if (!errorDetected) {
		if (this->init() < 0) {
			HA_LG_ER("HA_AGENT_DRBDMon:%s() - init	FAILED", __func__);
			errorDetected=true;
			rCode=-1;
		}
	}

	/* before starting the thread, check if we have seen any big faults */
	if (errorDetected) {
		HA_LG_ER("HA_AGENT_DRBDMon :%s()-errorDetected=true : comprestart ", __func__);
		if (m_globalInstance->haMode()){
			// Report to AMF that we want to restart of ourself
			m_globalInstance->compRestart();
		}
		exit (EXIT_FAILURE);
	}

	HA_TRACE_1("HA_AGENT_DRBDMon:- Thread running");
	while (running) {
		try {
			if (this->getq(mb) < 0) {
				HA_LG_ER("HA_AGENT_DRBDMon: getq() failed");
				break;
			}
			// Check msg type
			switch(mb->msg_type()) {
				case DRBDMON_CLOSE:
					HA_TRACE("HA_AGENT_DRBDMon: DRBDMON_CLOSE Received");
					mb->release();
					running=false;
					break;
				case DRBDMON_TIMEOUT:
					HA_TRACE_1("HA_AGENT_DRBDMon: DRBDMON_TIMEOUT Received");
					mb->release();
					HA_TRACE_5("HA_AGENT_DRBDMon:%s() superviseDRBD:[%d]", __func__, m_rebuildInProgress);
					if (!m_rebuildInProgress){
						if (this->superviseDRBD() != 0) {
							HA_LG_IN("HA_AGENT_DRBDMon:%s() superviseDRBD failed.", __func__);
						}	
					}
					break;
				default:
					HA_LG_IN("WARNING:HA_AGENT_DRBDMon:- not handled message received: %i", mb->msg_type());
					mb->release();
					running=false;
					break;
			}
		}
		catch(...){
			HA_LG_ER("HA_AGENT_DRBDMon: EXCEPTION!");
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_DRBDMon::close()
{
    HA_TRACE_ENTER();

    if (this->m_reactor->cancel_timer(m_timerid) != 1) {
        HA_LG_ER("HA_AGENT_DRBDMon:%s(u_long): error in cancel_timer", __func__);
    }

    ACE_Message_Block* mb = 0;
    ACE_NEW_NORETURN( mb, ACE_Message_Block());
    int rCode=0;
    if (0 == mb) {
         HA_LG_ER("%s() Failed to create mb object", __func__);
         rCode=-1;
    }
    if (rCode != -1) {
        mb->msg_type(DRBDMON_CLOSE);
        if (this->putq(mb) < 0){
            HA_LG_ER("%s() Fail to post DRBDMON_CLOSE to ourself", __func__);
            mb->release();
            rCode=-1;
		 }
	}
    HA_TRACE_LEAVE();
    return rCode;
}

//--------------------------------------------------------------------------------
int HA_AGENT_DRBDMon::close(u_long)
{
    HA_TRACE_ENTER();

    if (this->m_reactorRunner) {
        this->m_reactorRunner->stop();
        this->m_reactorRunner->wait();
        delete this->m_reactorRunner;
        this->m_reactorRunner=0;
    }
    if (this->m_reactor) {
        delete this->m_reactor;
        this->m_reactor=0;
    }

    HA_TRACE_LEAVE();
    return 0;
}

//-------------------------------------------------------------------------------
int HA_AGENT_DRBDMon::handle_timeout(const ACE_Time_Value&, const void* )
{
    HA_TRACE_ENTER();
    int rCode=0;
    ACE_Message_Block* mb = 0;
    ACE_NEW_NORETURN(mb, ACE_Message_Block());
    if (mb != 0) {
        mb->msg_type(DRBDMON_TIMEOUT);
        if (this->putq(mb) < 0) {
            mb->release();
        }
    }
    // re-schedule the time
    const ACE_Time_Value schedule_time(m_globalInstance->Config()->getConfig().drbdSupervisionIntvl/APOS_HA_ONESEC_IN_MILLI,0);
    m_timerid = this->m_reactor->schedule_timer(this, 0, schedule_time);
    if (m_timerid < 0) {
        HA_LG_ER("WARNING:HA_AGENT_DRBDMon -unable to start timer");
        rCode=-1;
    }
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------------
int HA_AGENT_DRBDMon::superviseDRBD()
{
    HA_TRACE_ENTER();
    int rCode=0;
	DRBD_InfoT drbdInfo;
	DRBD_InfoT peerdrbdInfo;
	memset(&drbdInfo, 0, sizeof(DRBD_InfoT));
	memset(&peerdrbdInfo, 0, sizeof(DRBD_InfoT));
	if (this->m_globalInstance->PWROff()->drbdinfo(drbdInfo) == 0||
	   	this->m_globalInstance->PWROff()->peerdrbdinfo(peerdrbdInfo) == 0) {
		if (drbdInfo.isConfigured == false) {
			if (m_globalInstance->haMode()) {
				/* Node can not be up without drbd. Report to AMF that 
					we are looking to reset the node
				*/	
				m_globalInstance->nodefailOver();
				/* we should not have come this far, in case if we are here,
				--noha exit will take care of exiting the daemon
				*/
			}
			/* In case if we are started on --noha mode*/
			HA_LG_ER("HA_AGENT_DRBDMon:%s() Exiting...", __func__);
			exit(EXIT_FAILURE);
		}else if ((this->m_globalInstance->getHAState() == ACS_APGCC_AMF_HA_STANDBY) && 
					((strcmp(drbdInfo.cstate, "Connected") != 0) && 
					(strcmp(drbdInfo.cstate, "SyncTarget") != 0) && 
					(strcmp(drbdInfo.cstate, "PausedSyncT") !=0) && 
					(strcmp(drbdInfo.cstate, "StartingSyncT") != 0)) && 
					(strcmp(peerdrbdInfo.role, "Unknown") == 0 &&
					(strcmp(peerdrbdInfo.dstate,"DUnknown") == 0))) {
						HA_TRACE("%s()- conn:[%s], role:[%s], disk:[%s]:", __func__, drbdInfo.cstate, drbdInfo.role, drbdInfo.dstate);
							/* There is a race condition between first node going down and
							* second node taking up the active role. If we fall in to this
							* state; we should let rolemgr thread initiate failover. Maximum
							* time we wait for the thread synchronization is 60 seconds.
							*/
							m_globalInstance->Utils()->msec_sleep(60000);
							HA_LG_ER("HA_AGENT_DRBDMon:%s()- Inconsistent local and peer DRBD states, initiating nodefailOver", __func__);	
							if (m_globalInstance->haMode()) {
						 	/* Node can not be up with inconsistent drbd. Report to AMF that
						 		we are looking to reset the node
							*/
								m_globalInstance->nodefailOver();
							/* we should not have come this far, in case if we are here,
							--noha exit will take care of exiting the daemon
							*/
							}	
					 	/* In case if we are started on --noha mode*/
					 	HA_LG_ER("HA_AGENT_DRBDMon:%s() Exiting...", __func__);
					 	exit(EXIT_FAILURE);
		}else if ((this->m_globalInstance->getHAState() == ACS_APGCC_AMF_HA_STANDBY) &&
					(strcmp(drbdInfo.cstate, "StandAlone") == 0) && 
					(strcmp(drbdInfo.role, "Secondary") == 0)){
					ACE_UINT32 Counter = 1;
					ACE_UINT32 MAX_ATTEMPTS = 3;
					HA_AGENT_DRBDMgr dMgrObj;

						
					while(Counter != MAX_ATTEMPTS){ 
					HA_LG_IN("HA_AGENT_DRBDMon:%d() - Detected StandAlone connection state on STANDBY node, Attempt [%s] to establish connection with ACTIVE node", Counter, __func__);
					if (dMgrObj.activate() == 0) break;
					m_globalInstance->Utils()->msec_sleep(1000); // 1 sec
					Counter++;
					}	
					if (Counter > MAX_ATTEMPTS){
						if (m_globalInstance->haMode()){
							/* Node can not be up with inconsistent drbd. Report to AMF that
							 * we are looking to reset the node
							 */
							m_globalInstance->nodefailOver();
							/* we should not have come this far, in case if we are here,
							 * --noha exit will take care of exiting the daemon
							 */
							/* In case if we are started on --noha mode*/
							HA_LG_ER("HA_AGENT_DRBDMon:%s() Exiting...", __func__);
							exit(EXIT_FAILURE);
						}		
					}		
		}else{
			HA_TRACE_5("superviseDRBD: HASTATE[%d] CSTATE[%s] ROLE[%s] DSTATE[%s]", 
						m_globalInstance->getHAState(), drbdInfo.cstate, drbdInfo.role, drbdInfo.dstate);
			HA_AGENT_PersistantInfoT pInfo;
			if (this->m_globalInstance->PWROff()->get_persis_info(pInfo) == false) {
				HA_LG_ER("HA_AGENT_DRBDMon:%s Error in writing persistent info in file", __func__);
				rCode=-1;
			} 
			if (rCode == 0) {
				if (strcmp(drbdInfo.cstate, "WFConnection") != 0) {
					strcpy(pInfo.cstate, drbdInfo.cstate);
					if (this->m_globalInstance->PWROff()->write_persis_info(pInfo) == false) {
						HA_LG_ER("HA_AGENT_DRBDMon:%s Error in writing persistent info in file", __func__);
					}	
				}
			}	
		}
	} else {
		rCode=-1;
	}

    HA_TRACE_LEAVE();
    return rCode;
}
//-------------------------------------------------------------------------------

