
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
 * @file apos_ha_devmon_drbdrecovery.cpp
 *
 * @brief
 * 	 
 * This class is reponsible for initiating recovery of peer 
 * disk in case of inconsistency or not uptodate of data
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_devmon_drbdrecovery.h"

//-----------------------------------------------------------------------------
HA_DEVMON_DRBDRecovery::HA_DEVMON_DRBDRecovery():
  m_globalInstance(HA_DEVMON_Global::instance()),
  m_drbdObj(0),
  m_drbdRecoveryReactor(0),
  m_reactor(0),
  m_timerid(-1)
	
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
HA_DEVMON_DRBDRecovery::~HA_DEVMON_DRBDRecovery()
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::init()
{
	HA_TRACE_ENTER();
	int rCode=0;
	/* initialize drbd manager class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_drbdObj, HA_DEVMON_DRBDMgr());
		if (0 == this->m_drbdObj) {
			HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - MEMORY PROBLEM: Failed to allocate HA_DEVMON_DRBDMgr", __func__);
			rCode=-1;
		}else {
			if (this->m_drbdObj->init()<0) {
				HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - MEMORY PROBLEM: Failed to allocate HA_DEVMON_DRBDMgr", __func__);
				rCode=-1;
			}
		}
	}
	if (rCode == 0) {
		ACE_NEW_NORETURN(m_reactor, ACE_Reactor());
		if (0 == m_reactor) {
			HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - MEMORY PROBLEM: Failed to allocate ACE_Reactor", __func__);
			rCode=-1;
		}
	}
	if (rCode == 0) {
		ACE_NEW_NORETURN(m_drbdRecoveryReactor, APOS_HA_ReactorRunner(this->m_reactor, DRBDRECOVERY_MAIN_REACTOR));
		if (0 == m_drbdRecoveryReactor) {
			HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - MEMORY PROBLEM: Failed to allocate APOS_HA_DevMon_ReactorRunner", __func__);
			rCode=-1;
		}else {
			rCode= m_drbdRecoveryReactor->open();
			if (rCode != 0) {
				HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - Reactor open failed", __func__);
				rCode=-1;
			}
		}
    }
	if (rCode == 0) {
		const ACE_Time_Value schedule_time(m_globalInstance->Config()->getConfig().queryInterval/APOS_HA_ONESEC_IN_MILLI, 0);
		m_timerid = this->m_reactor->schedule_timer(this, 0, schedule_time);
		if (m_timerid < 0) {
			HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - Unable to schedule timer.", __func__);
			rCode=-1;
		}
	}
		
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::open()
{
	HA_TRACE_ENTER();
	int rCode=0;
	if (this->activate(THR_NEW_LWP|THR_JOINABLE) < 0) {
		HA_LG_ER("%s() - Failed to start main svc thread.", __func__);
		rCode=-1;
	}	
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::svc()
{
	HA_TRACE_ENTER();
	ACE_Message_Block* mb = NULL;
	bool running = true;
	bool errorDetected=false;
	if (!errorDetected) {	
		if (this->init() < 0){
			HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() - init FAILED", __func__);
			errorDetected=true;
		}	
    }

	if (errorDetected) {
		HA_LG_ER("HA_DEVMON_DRBDRecovery:%s() -errorDetected=true : compRestart triggered ",__func__);
		if (m_globalInstance->haMode()){
			// Report to AMF that we want to restart of ourselves
			m_globalInstance->compRestart();
		}
		exit (EXIT_FAILURE);
	}	

	HA_TRACE_1("HA_DEVMON_DRBDRecovery:- Thread running");
	while (running){
		try {
			if (this->getq(mb) < 0){
				HA_LG_ER("HA_DEVMON_DRBDRecovery: getq() failed");
				break;
			}
			// Check msg type
			switch(mb->msg_type()){
				case CLOSE:
					HA_TRACE("HA_DEVMON_DRBDRecovery: CLOSE Received");
					mb->release();
					running=false;
					break;
				case TIMEOUT:
					HA_TRACE("HA_DEVMON_DRBDRecovery: TIMEOUT Received");
					mb->release();
					//monitor the data disk.
					if (this->healthCheck() == 0) {
						HA_TRACE("HA_DEVMON_DRBDRecovery:%s Health Check", __func__);
					}
					break;
				default:
					HA_LG_IN("WARNING:HA_DEVMON_DRBDRecovery - not handled message received: %i", mb->msg_type());
					mb->release();
					running=false;
					break;
			}
		}
		catch(...){
			HA_LG_ER("HA_DEVMON_DRBDRecovery: EXCEPTION!");
		}
	}
	HA_TRACE_LEAVE();
	return 0;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::close(u_long) 
{
	HA_TRACE_ENTER();
	if (this->m_reactor && (this->m_reactor->cancel_timer(m_timerid) != 1)) {
		HA_LG_ER("HA_DEVMON_DRBDRecovery:%s(u_long): error in cancel_timer", __func__);
	}

	// check that we're really shutting down.
	if (!m_globalInstance->shutdown_ordered()) {
		HA_LG_ER("HA_DEVMON_DRBDRecovery:%s(u_long): Abnormal shutdown of HA_DEVMON_DRBDRecovery", __func__);
		exit(EXIT_FAILURE);
	}
	if (this->m_drbdRecoveryReactor) {
		this->m_drbdRecoveryReactor->stop();
		this->m_drbdRecoveryReactor->wait();
		delete this->m_drbdRecoveryReactor;
		this->m_drbdRecoveryReactor=0;
	}
	if (this->m_reactor) {
			delete this->m_reactor;
			this->m_reactor=0;
	}
	if (this->m_drbdObj) {
		delete this->m_drbdObj;
		this->m_drbdObj=0;
	}
	HA_TRACE_LEAVE();
	return 0;
}	

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::close()
{
	HA_TRACE_ENTER();

	ACE_Message_Block* mb = 0;
	ACE_NEW_NORETURN( mb, ACE_Message_Block());

	int rCode=0;
	if (0 == mb) {
		HA_LG_ER("%s() Failed to create mb object", __func__);
		rCode=-1;
	}

	if (rCode != -1) {
		mb->msg_type(CLOSE);
		if (this->putq(mb) < 0){
			HA_LG_ER("%s() Fail to post DRBDRECOVERY_CLOSE to ourself", __func__);
			mb->release();
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}	

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::healthCheck()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	if (m_drbdObj->isdegraded()!=0) {
		if(m_drbdObj->recovery()!=0) {
			HA_LG_ER("%s(): Recovery failed with errCode: %d", __func__, rCode);
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//------------------------------------------------------------------------------------
int HA_DEVMON_DRBDRecovery::handle_timeout(const ACE_Time_Value&, const void* )
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	ACE_Message_Block* mb = 0;
	ACE_NEW_NORETURN(mb, ACE_Message_Block());
	if (mb != 0) {
		mb->msg_type(TIMEOUT);
		if (this->putq(mb) < 0) {
			mb->release();
		}
	}

	// re-schedule the time
	const ACE_Time_Value schedule_time(m_globalInstance->Config()->getConfig().queryInterval/APOS_HA_ONESEC_IN_MILLI,0);
	m_timerid = this->m_reactor->schedule_timer(this, 0, schedule_time);
	if (m_timerid < 0) {
		HA_LG_ER("WARNING:HA_DEVMON_DRBDRecovery -unable to start timer");
		rCode=-1;
	}
	return rCode;
}
//----------------------------------------------------------------------
