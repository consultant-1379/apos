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
 * @file apos_ha_devmon_drbdmon.cpp
 *
 * @brief
 * 	 
 * This class is responsible for monitoring of drbd resource
 * and sending information to agent
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_devmon_drbdmon.h"

//-----------------------------------------------------------------------------

HA_DEVMON_DRBDMon::HA_DEVMON_DRBDMon():
 m_globalInstance(HA_DEVMON_Global::instance()),
 m_drbdObj(0),
 m_reactorRunner(0),
 m_reactor(0),
 m_sendMsg(false),
 m_timerid(-1)
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
HA_DEVMON_DRBDMon::~HA_DEVMON_DRBDMon()
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::initDRBDMon()
{
	HA_TRACE_ENTER();
    int rCode=0;

	/* initialize drbd monitor class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_drbdObj, HA_DEVMON_DRBDMgr());
		if (0 == this->m_drbdObj) {
			HA_LG_ER("HA_DEVMON_DRBDMon:%s() - MEMORY PROBLEM: Failed to allocate HA_DEVMON_DRBDMgr", __func__);
			rCode=-1;
		} else {
			if (this->m_drbdObj->init() < 0) {
				HA_LG_ER("HA_DEVMON_DRBDMon:%s() - init failed for HA_DEVMON_DRBDMgr", __func__);
				rCode=-1;
			}
		}
	}
	/* create reactor*/
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_reactor, ACE_Reactor());
		if (0 == this->m_reactor) {
			HA_LG_ER("HA_DEVMON_DRBDMon:%s() - MEMORY PROBLEM: Failed to allocate ACE_Reactor", __func__);
			rCode=-1;
		}
	}
	/* create the reactor instance */
	if (rCode == 0) {
		ACE_NEW_NORETURN(m_reactorRunner, APOS_HA_ReactorRunner(this->m_reactor, DRBDMON_MAIN_REACTOR));
		if (0 == m_reactorRunner) {
			HA_LG_ER("HA_DEVMON_DRBDMon:%s() - MEMORY PROBLEM: Failed to allocate APOS_HA_ReactorRunner", __func__);
			rCode=-1;
		}else {
			rCode= m_reactorRunner->open();
			if (rCode != 0) {
				HA_LG_ER("HA_DEVMON_Drbdmon:%s() - Reactor open failed", __func__);	
				rCode=-1;
			}
		}
	}
	if (rCode == 0) {
		const ACE_Time_Value schedule_time(m_globalInstance->Config()->getConfig().queryInterval/APOS_HA_ONESEC_IN_MILLI, 0);
		m_timerid = this->m_reactor->schedule_timer(this, 0, schedule_time);
		if (m_timerid < 0) {
			HA_LG_ER("HA_DEVMON_Drbdmon:%s() - Unable to schedule timer.", __func__);
			rCode=-1;
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::open()
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
int HA_DEVMON_DRBDMon::svc()
{
	ACE_Message_Block* mb = NULL;
	bool running = true;
	bool errorDetected=false;
	HA_TRACE_ENTER();
	if (!errorDetected) {	
		if (this->initDRBDMon() < 0) {
			HA_LG_ER("HA_DEVMON_DRBDMon:%s() - initDRBDMon FAILED", __func__);
			errorDetected=true;
		}	
    }
    /* before starting the thread, check if we have seen any big faults */
	if (errorDetected) {
		HA_LG_ER("HA_DEVMON_DRBDMon:%s()-errorDetected=true : comprestart ", __func__);
		if (m_globalInstance->haMode()){
			// Report to AMF that we want to restart of ourselves
			m_globalInstance->compRestart();
		}
		exit (EXIT_FAILURE);
	}	

    HA_TRACE_1("HA_DEVMON_DRBDMon:- Thread running");
	while (running){
		try {
			if (this->getq(mb) < 0) {
				HA_LG_ER("HA_DEVMON_DRBDMon: getq() failed");
				break;
			}
			// Check msg type
			switch(mb->msg_type()) {
				case CLOSE:
					HA_TRACE("HA_DEVMON_DRBDMon: CLOSE Received");
					mb->release();
					running=false;
					break;
				case TIMEOUT:
					HA_TRACE("HA_DEVMON_DRBDMon: TIMEOUT Received");
					mb->release();
					//monitor drbd
					this->healthCheck();
					break;
				default:
					HA_LG_IN("WARNING:HA_DEVMON_DRBDMon - not handled message received: %i", mb->msg_type());
					mb->release();
					running=false;
					break;
			}
		}
		catch(...){
			HA_LG_ER("HA_DEVMON_DRBDMon: EXCEPTION!");
		}
	}
	HA_TRACE_LEAVE();
	return 0;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::healthCheck() 
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=m_drbdObj->isactive();
	if((rCode==0) && (!m_sendMsg)) {
		//send msg to agent
		if(this->sendMsg()!=0) {
			HA_LG_ER("%s() HA_DEVMON_DRBDMon: SendMsg failed",__func__);
			rCode=-1;
		}
		m_sendMsg=true;
	}
	if((rCode!=0) && (m_sendMsg)) {
		if(this->sendMsg()!=0) {
			HA_LG_ER("%s() HA_DEVMON_DRBDMon: SendMsg failed",__func__);
			rCode=-1;
		}
		m_sendMsg=false;
	}									
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::sendMsg()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	HA_DEVMON_MsgT msgInfo = m_drbdObj->fillMsg();
	rCode=m_globalInstance->write_buffer(&msgInfo);
	if(rCode!=0) {
		HA_LG_ER("%s()HA_DEVMON_DRBDMon: write_buffer failed",__func__);
	}
	m_drbdObj->reset();
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------    
int HA_DEVMON_DRBDMon::close()
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
			HA_LG_ER("%s() Fail to post DRBDMon_CLOSE to ourself", __func__);
			mb->release();
			rCode=-1;
			 }
		 }
	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::close(u_long)
{
	HA_TRACE_ENTER();
	if (this->m_reactor && (this->m_reactor->cancel_timer(m_timerid) != 1)) {
		HA_LG_ER("HA_DEVMON_Drbdmon:%s(u_long): error in cancel_timer", __func__);
	}

	// check that we're really shutting down.
	if (!m_globalInstance->shutdown_ordered()) {
		HA_LG_ER("HA_DEVMON_DRBDMon:%s(u_long): Abnormal shutdown of HA_DEVMON_DRBDMon", __func__);
 		exit(EXIT_FAILURE);
	}

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

	if (this->m_drbdObj) {
		delete this->m_drbdObj;
		this->m_drbdObj=0;
	}
	HA_TRACE_LEAVE();
	return 0;
}

//-------------------------------------------------------------------------------
int HA_DEVMON_DRBDMon::handle_timeout(const ACE_Time_Value&, const void* )
{
	HA_TRACE_ENTER();
	int rCode=0;
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
		HA_LG_ER("WARNING:HA_DEVMON_Drbdmon -unable to start timer");
		rCode=-1;
	}
	return rCode;
}
//-------------------------------------------------------------------------------

