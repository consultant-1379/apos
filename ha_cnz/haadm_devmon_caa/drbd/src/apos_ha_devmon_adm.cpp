/*****************************************************************************
**
** COPYRIGHT Ericsson Telecom AB 2013
**
** The copyright of the computer program herein is the property of
** Ericsson Telecom AB. The program may be used and/or copied only with the
** written permission from Ericsson Telecom AB or in the accordance with the
** terms and conditions stipulated in the agreement/contract under which the
** program has been supplied.
**
** ----------------------------------------------------------------------*//**
*
** @file apos_ha_devmon.cpp
**
** @brief
** This is the main class to be run in DEVMON. It is an active object that is
** started by calling start() and then stopped by calling stop().
** The thread is run in svc().
**
** @author Malangsha Shaik (xmalsha)
**
** -------------------------------------------------------------------------*/

#include "apos_ha_devmon_adm.h"

//--------------------------------------------------------------------------
HA_DEVMON_Adm::HA_DEVMON_Adm():
  m_globalInstance(HA_DEVMON_Global::instance()),
  m_haObj(0),
  m_dMonObj(0),
  m_dRcvyObj(0)
{
	HA_TRACE("%s(): Constructor", __func__);
}

//--------------------------------------------------------------------------
HA_DEVMON_Adm::~HA_DEVMON_Adm()
{
	HA_TRACE_ENTER();
	if (m_dMonObj != 0) {
		delete m_dMonObj;
		m_dMonObj =0;
	}
	if (m_dRcvyObj != 0) {
		delete m_dRcvyObj;
		m_dRcvyObj =0;
	}
	// Very important to deactivate global instances
	m_globalInstance->deactivate();
	// reset the flags
	m_globalInstance->shutdown_ordered(false);
	m_globalInstance->haMode(false);
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::start(devmonHAClass* haObj)
{
	HA_TRACE_ENTER();
	if (0 == haObj) {
		HA_TRACE_1("HA_DEVMON_Adm:%s() NULL haObj Found", __func__);
		return -1;
	}
	/* set global ha Obj handler */
	m_globalInstance->setHaMgr(haObj);
	m_globalInstance->haMode(true);
	m_haObj=haObj;
	HA_TRACE_1("HA_DEVMON_Adm: %s() active invoked", __func__);
	HA_TRACE_LEAVE();
	return this->start(0,0);
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::start(int argc, char* argv[])
{
	(void)argc;
	(void)argv;
	HA_TRACE_ENTER();
	int status = this->sig_shutdown_.register_handler(SIGINT, this);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm: %s() register_handler(SIGINT,this) failed..",__func__);
		return -1;
	}
	status = this->sig_shutdown_.register_handler(SIGTERM, this);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm: %s() register_handler(SIGTERM,this) failed.",__func__);
		return -1;
	}
	status = this->sig_shutdown_.register_handler(SIGHUP, this);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm: %s() register_handler(SIGHUP,this) failed.",__func__);
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
void HA_DEVMON_Adm::stop()
{
	HA_TRACE_ENTER();
	ACE_Message_Block* mb=0;
	ACE_NEW_NORETURN(mb, ACE_Message_Block());
	if (mb == 0){
		HA_TRACE("HA_DEVMON_Adm:Failed create message SHUTDOWN");
	}else {
		mb->msg_type(SHUTDOWN);
		if (this->putq(mb) < 0) {
			mb->release();
			mb=0;
			HA_TRACE("HA_DEVMON_Adm:Failed to send msg SHUTDOWN");
		}else {
			HA_TRACE("HA_DEVMON_Adm:SHUTDOWN Ordered Internally");
		}
	}
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::handle_signal(int signum, siginfo_t*, ucontext_t *)
{
	HA_TRACE_ENTER();
	switch (signum) {
		case SIGTERM:
			HA_TRACE_3("HA_DEVMON_Adm: - signal SIGTERM caught...");
			break;
		case SIGINT:
			HA_TRACE_3("HA_DEVMON_Adm: - signal SIGINT caught...");
			break;
		case SIGHUP:
			HA_TRACE_3("HA_DEVMON_Adm: - signal SIGHUP caught...");
			break;
		default:
			HA_TRACE_3("HA_DEVMON_Adm: - other signal caught..[%d]", signum);
			break;
	}
	if (signum == SIGHUP) {
		this->readConfig_r();
	}else {
		this->stop();
	}
	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::close(u_long /* flags */)
{
	HA_TRACE_ENTER();
	HA_TRACE("HA_DEVMON_Adm:%s(u_long): nothing to do here", __func__);
	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
void HA_DEVMON_Adm::shutDown_all()
{
	HA_TRACE_ENTER();
	/*
	 * close(u_long) function call exactly meant to release all the resources
	 * acquired by us while we are going down. But in some cases, it is observed
	 * that things kind of got out of control while doing the release. So
	 * having our own shutdown handler is the best way to release all the resources
	 * acquired.
	 * */
	int status = this->sig_shutdown_.remove_handler(SIGHUP);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm:%s() - remove_handler(SIGHUP) failed.", __func__);
	}
	status = this->sig_shutdown_.remove_handler(SIGTERM);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm:%s() - remove_handler(SIGTERM) failed.", __func__);
	}
	status = this->sig_shutdown_.remove_handler(SIGINT);
	if (status < 0) {
		HA_LG_ER("HA_DEVMON_Adm:%s() - remove_handler(SIGINT) failed.", __func__);
	}
	// set shutdown flag for the other threads to know that shutdown is in progress.
	m_globalInstance->shutdown_ordered(true);

	// Close Drbd Monitor Thread
	this->DRBDMon()->close();
	HA_TRACE_1("HA_DEVMON_Adm:%s() waiting for drbd supervision thread to close", __func__);
	this->DRBDMon()->wait();
	HA_TRACE_1("HA_DEVMON_Adm:%s() drbd supervision thread closed", __func__);

	//close Disk Monitor Thread
	this->DRBDRecovery()->close();
	HA_TRACE_1("HA_DEVMON_Adm:%s() waiting for drbd mirroring supervisison thread to close", __func__);
	this->DRBDRecovery()->wait();
	HA_TRACE_1("HA_DEVMON_Adm:%s() drbd mirroring supervisison thread closed", __func__);

	// make sure to close fifo pipe at end
	if (m_globalInstance->fifo_close() < 0) {
		HA_TRACE_1("%s() - fifo close failed", __func__);
	}

	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::svc()
{
	bool errorDetected=false;
	bool done=false;
	int res=0;
	HA_TRACE_ENTER();

	if (m_globalInstance->fifo_open() < 0) {
		HA_LG_ER("%s(): Failed to open fifo piple", __func__);
		errorDetected = true;
	}
	// start drdb supervisor thread
	if (!errorDetected) {
		if (this->DRBDMon()== 0) {
			HA_LG_ER("%s(): Failed to create drbd monitor thread", __func__);
			errorDetected = true;
		}else {
			if (this->DRBDMon()->open()!=0) {
				HA_LG_ER("%s(): Failed to open drbd recovery thread", __func__);
				errorDetected = true;
			}
		}
	}
	// start drbd disk mirror recovery supervisor thread
	if (!errorDetected) {
		if (this->DRBDRecovery()== 0) {
			HA_LG_ER("%s(): Failed to create drbd mirroing recovery thread", __func__);
			errorDetected = true;
		}else {
			if (this->DRBDRecovery()->open()!=0) {
				HA_LG_ER("%s(): Failed to open drbd recovery thread", __func__);
				errorDetected = true;
			}
		}
	}
	/* before starting the thread, check if we have seen any big faults */
	if (errorDetected) {
		HA_LG_ER("%s(): Error detected is true, CompRestart initiated",__func__);
		if (m_globalInstance->haMode()){
			m_globalInstance->compRestart();
		}
		exit (EXIT_FAILURE);
	}
	HA_TRACE("HA_DEVMON_Adm: Thread is running now..");
	ACE_Message_Block* mb=0;
	while (!done){
		res = this->getq(mb);
		if (res < 0)
			break;

		switch( mb->msg_type() ){
			case SHUTDOWN:{
				  HA_TRACE("HA_DEVMON_Adm: received SHUTDOWN");
				  mb->release();
				  mb=0;
				  done=true;
				  shutDown_all();
				  break;
			}
			default:{
				 HA_TRACE_1("HA_DEVMON_Adm:[%d] Unknown message received:", mb->msg_type());
				 mb->release();
				 mb=0;
				 break;
			}
		}
	}
	HA_TRACE_LEAVE();
	return APOS_HA_SUCCESS;
}

//--------------------------------------------------------------------------
HA_DEVMON_DRBDMon* HA_DEVMON_Adm::DRBDMon()
{
	HA_TRACE_ENTER();
	if (this->m_dMonObj == 0) {
	ACE_NEW_NORETURN(this->m_dMonObj, HA_DEVMON_DRBDMon());
	if (0 == this->m_dMonObj) {
		HA_LG_ER("%s() - Memory allocation failed", __func__);
		}
	}
	HA_TRACE_LEAVE();
    return this->m_dMonObj;
			
}

//--------------------------------------------------------------------------
HA_DEVMON_DRBDRecovery* HA_DEVMON_Adm::DRBDRecovery()
{
	HA_TRACE_ENTER();
	if (this->m_dRcvyObj == 0) {
		ACE_NEW_NORETURN(this->m_dRcvyObj, HA_DEVMON_DRBDRecovery());
		if (0 == this->m_dMonObj) {
			HA_LG_ER("%s() - Memory allocation failed", __func__);
		}
	}
	HA_TRACE_LEAVE();
	return this->m_dRcvyObj;
}

//--------------------------------------------------------------------------
int HA_DEVMON_Adm::initClasses() {
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	/* init Config class */
	if (rCode == 0) {
		if (m_globalInstance->Config()->readConfig() < 0) {
			HA_LG_ER("%s(): Failed to read configuration paramters", __func__);
			rCode=-1;
		}
	}
	/* init Util Class */
	if (rCode == 0) {
		if (m_globalInstance->Utils()->init() < 0) {
			HA_LG_ER("%s(): Failed to initialize the Util class", __func__);
			rCode=-1;
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
void HA_DEVMON_Adm::readConfig_r()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	HA_TRACE("Re-reading the disk basked Configuration data");

	m_globalInstance->Config()->dumpConfig();
	if (m_globalInstance->Config()->readConfig() < 0) {
		HA_LG_ER("%s(): Failed to read configuration paramters", __func__);
		rCode=-1;
	}
	if (rCode == 0) {
		HA_LG_IN ("%s(): Reading new configuration data success", __func__);
	}else {
		HA_LG_IN ("%s(): Reading new configuration data failed", __func__);
	}
	HA_TRACE_LEAVE();
}
//--------------------------------------------------------------------------

