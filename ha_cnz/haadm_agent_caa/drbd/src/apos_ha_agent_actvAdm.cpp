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
 * @file apos_ha_agent_actvAdm.cpp
 *
 * @brief
 * This is the main class to be run in AGENT. It is an active object that is
 * started by calling start() and then stopped by calling stop().
 * The thread is run in svc().
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ------------------------------------------------------------------------*/

#include "apos_ha_agent_actvAdm.h"

//--------------------------------------------------------------------------
HA_AGENT_ACTVAdm::HA_AGENT_ACTVAdm():
	m_globalInstance(HA_AGENT_Global::instance()),
	m_haObj(0)
{
	HA_TRACE_2("%s(): Constructor", __func__);
}

//--------------------------------------------------------------------------
HA_AGENT_ACTVAdm::~HA_AGENT_ACTVAdm()
{
	HA_TRACE_ENTER();

	// Very important to deactivate global instances
	m_globalInstance->deactivate();
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::start(agentHAClass* haObj)
{
	HA_TRACE_ENTER();

	if (0 == haObj) {
		HA_TRACE_1("HA_AGENT_ACTVAdm:%s() NULL haObj Found", __func__);
		return -1;
	}

	/* set global ha Obj handler */
	m_globalInstance->setHaMgr(haObj);
	m_globalInstance->haMode(true);
	m_haObj=haObj;
	HA_TRACE_1("HA_AGENT_ACTVAdm: %s() active invoked", __func__);

	HA_TRACE_LEAVE();
	return this->start(0,0);
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::start(int argc, char* argv[]) 
{
	(void)argc;
	(void)argv;
	HA_TRACE_ENTER();

	int status = this->sig_shutdown_.register_handler(SIGINT, this);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_ACTVAdm: %s() register_handler(SIGINT,this) failed..",__func__);
		return -1;
	}

	status = this->sig_shutdown_.register_handler(SIGHUP, this);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_ACTVAdm: %s() register_handler(SIGHUP,this) failed.",__func__);
		return -1;
	}
    
    /* init required classes */
	if (this->initClasses() < 0) {
		HA_LG_ER("%s(): Failed to initalize the required class instances", __func__);
		return -1;
	}

	HA_TRACE_LEAVE();
	return this->activate( THR_JOINABLE | THR_NEW_LWP );
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
void HA_AGENT_ACTVAdm::stop() 
{
	HA_TRACE_ENTER();
		
	// Shutdown message
	ACE_Message_Block* mb=0;
	ACE_NEW_NORETURN(mb, ACE_Message_Block());
	if (mb == 0){
		HA_TRACE("HA_AGENT_ACTVAdm:Failed create message AGENT_SHUTDOWN");
	} else {
		mb->msg_type(AGENT_SHUTDOWN);
		if (this->putq(mb) < 0){
			mb->release();
			mb=0;
			HA_TRACE("HA_AGENT_ACTVAdm:Failed to send msg AGENT_SHUTDOWN");
		}else{
			HA_TRACE("HA_AGENT_ACTVAdm:AGENT_SHUTDOWN Ordered Internally");
		}	
	}

	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::handle_signal(int signum, siginfo_t*, ucontext_t *) 
{
	HA_TRACE_ENTER();

	switch (signum) {
		case SIGINT:
			HA_TRACE("HA_AGENT_ACTVAdm: - signal SIGINT caught...");
			break;
		case SIGHUP:	
			HA_TRACE("HA_AGENT_ACTVAdm: - signal SIGHUP caught...");
			break;
		default:
			HA_TRACE_1("HA_AGENT_ACTVAdm: - other signal caught..[%d]", signum);
			break;
	}

	if (signum == SIGHUP) {
		this->readConfig_r();
	} else {
		this->stop();
	}	

	HA_TRACE_LEAVE();
	return 0;	
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::close(u_long /* flags */)
{
	HA_TRACE_ENTER();

	HA_TRACE_1("HA_AGENT_ACTVAdm:%s(u_long): nothing to do here", __func__);

	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
void HA_AGENT_ACTVAdm::shutDown_all()
{
	HA_TRACE_ENTER();
	/*
		close(u_long) function call exactly meant to release all the resources
		acquired by us while we are going down. But in some cases, it is observed 
		that things kind of got out of control while doing the release. So 
		having our own shutdown handler is the best	way to release all the resources
		acquired.
	*/
	int status = this->sig_shutdown_.remove_handler(SIGHUP);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_ACTVAdm:%s() - remove_handler(SIGHUP) failed.", __func__);
	}

	status = this->sig_shutdown_.remove_handler(SIGINT);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_ACTVAdm:%s() - remove_handler(SIGINT) failed.", __func__);
	}

	// set shutdown flag for the other threads to know that shutdown is in progress.
	m_globalInstance->shutdown_ordered(true);

	// Close Role Manager Thread
	m_globalInstance->roleMgr()->close();
	HA_TRACE_1("HA_AGENT_ACTVAdm:%s() waiting for Role Manager thread to close", __func__);
	m_globalInstance->roleMgr()->wait();
	HA_TRACE_1("HA_AGENT_ACTVAdm:%s() Role Manager thread has closed", __func__);

	// Close other remaining threads if we have any
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::svc() 
{
	bool errorDetected=false;
	bool done=false;
	int res=0;
	HA_TRACE_ENTER();
	
	// Create Split Brain handler / Node Role Manager (Dispatcher)
	if (this->startRoleMgr() < 0) {
		HA_LG_ER("%s(): Failed to create Node Role Manager Instance", __func__);
		errorDetected = true;
	}

	/* before starting the thread, check if we have seen any big faults */
	if (errorDetected) {
		if (m_globalInstance->haMode()){
			m_globalInstance->compRestart();
		} else {
			exit (EXIT_FAILURE);
		}
	}

	HA_TRACE("HA_AGENT_ACTVAdm: Thread is running now..");

	ACE_Message_Block* mb=0;
	while (!done){
		res = this->getq(mb);
		if (res < 0)
			break;
		
		switch( mb->msg_type() ){
			case AGENT_SHUTDOWN: {
				HA_TRACE("HA_AGENT_ACTVAdm: received AGENT_SHUTDOWN");
				mb->release();					   
				mb=0;
				done=true;
				break;
			}

			default: {
				HA_TRACE_1("HA_AGENT_ACTVAdm:[%d] Unknown message received:", mb->msg_type());
				mb->release();
       			mb=0;
				break;
			}	
		}		
	}
	shutDown_all();

	HA_TRACE_LEAVE();
	return APOS_HA_SUCCESS;
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::startRoleMgr() {
	HA_TRACE_ENTER();
	// Create and activate the instance of Role Manager
	if (HA_AGENT_Global::instance()->roleMgr()->open() < 0) {
		return -1;
	}

	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_ACTVAdm::initClasses() 
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	/* init Util Class */
	if (rCode == 0) {
		if (m_globalInstance->Utils()->init() < 0) {
			HA_LG_ER("%s(): Failed to initialize the Util class", __func__);
		}
	}
	
	/* init Config class and readConfig */
	if (rCode == 0) {
		if (m_globalInstance->Config()->readConfig() < 0) {
			HA_LG_ER("%s(): Failed to read configuration paramters", __func__);
			rCode=-1;
		}
	}

	/* read MIP info */
	if (rCode == 0) {
		if (m_globalInstance->Config()->readMips() < 0) {
			HA_LG_ER("%s(): Failed to read MIPs", __func__);
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
void HA_AGENT_ACTVAdm::readConfig_r() 
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	HA_TRACE("Re-reading the disk basked Configuration data");

	/* dumping the existing configuration first */
	m_globalInstance->Config()->dumpConfig();

	if (m_globalInstance->Config()->readConfig() < 0) {
		HA_LG_ER("%s(): Failed to read configuration paramters", __func__);
		rCode=-1;
	}

	if (rCode == 0) {
		HA_LG_IN ("%s(): Reading new configuration data success", __func__);
	}else{	
		HA_LG_IN ("%s(): Reading new configuration data failed", __func__);
	}	

	HA_TRACE_LEAVE();	
}
//--------------------------------------------------------------------------

