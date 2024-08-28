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
 * @file apos_ha_agent_stbyAdm.cpp
 *
 * @brief
 * This is the main class to be run in AGENT. It is an stanby object that is
 * started by calling start() and then stopped by calling stop().
 * The thread is run in svc().
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ------------------------------------------------------------------------*/

#include "apos_ha_agent_stbyAdm.h"

//--------------------------------------------------------------------------
HA_AGENT_STNBYAdm::HA_AGENT_STNBYAdm():
	m_globalInstance(HA_AGENT_Global::instance()),
	m_haObj(0),
	m_fileObj(0),
	m_DMObj(0),
	ShutdownDone(false)
{
	HA_TRACE("%s(): Constructor", __func__);
}

//--------------------------------------------------------------------------
HA_AGENT_STNBYAdm::~HA_AGENT_STNBYAdm()
{
	HA_TRACE_ENTER();

	// Very important to deactivate global instances
	m_globalInstance->deactivate();
	m_globalInstance->setOldhaState(ACS_APGCC_AMF_HA_STANDBY);
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::start(agentHAClass* haObj)
{
	HA_TRACE_ENTER();

	if (0 == haObj) {
		HA_TRACE_1("HA_AGENT_STNBYAdm:%s() NULL haObj Found", __func__);
		return -1;
	}

	/* set global ha Obj handler */
	m_globalInstance->setHaMgr(haObj);
	m_globalInstance->haMode(true);
	m_haObj=haObj;
	HA_TRACE_1("HA_AGENT_STNBYAdm: %s() active invoked", __func__);

	HA_TRACE_LEAVE();
	return this->start(0,0);
}

//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::start(int argc, char* argv[]) 
{
	(void)argc;
	(void)argv;
	HA_TRACE_ENTER();

	int status = this->sig_shutdown_.register_handler(SIGINT, this);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_STNBYAdm: %s() register_handler(SIGINT,this) failed..",__func__);
		return -1;
	}
	status = this->sig_shutdown_.register_handler(SIGHUP, this);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_STNBYAdm: %s() register_handler(SIGHUP,this) failed.",__func__);
		return -1;
	}
	status = this->sig_shutdown_.register_handler(EVENT_REBUILD, this);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_STNBYAdm: %s() register_handler(EVENT_REBUILD,this) failed.",__func__);
		return -1;
	}	
	/* init required classes */
	if (this->initClasses() < 0) {
		HA_LG_ER("%s(): Failed to initalize the required class instances", __func__);
		return -1;
	}

	/* remove lock files */
	if (this->rmlockfile() < 0) {
		HA_LG_ER("%s(): Error in removing lock-file", __func__);
		return -1;
	}

	HA_TRACE_LEAVE();
	return this->activate( THR_JOINABLE | THR_NEW_LWP );
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
void HA_AGENT_STNBYAdm::stop() 
{
	HA_TRACE_ENTER();
		
	if (this->ShutdownDone){
		HA_TRACE("HA_AGENT_STNBYAdm: Shutdown Already Done");
		return ;	
	}	

    int status = this->sig_shutdown_.remove_handler(SIGHUP);
    if (status < 0) {
        HA_LG_ER("HA_AGENT_STNBYAdm:%s() - remove_handler(SIGHUP) failed.", __func__);
    }
    status = this->sig_shutdown_.remove_handler(SIGINT);
    if (status < 0) {
        HA_LG_ER("HA_AGENT_STNBYAdm:%s() - remove_handler(SIGINT) failed.", __func__);
    }
	status = this->sig_shutdown_.remove_handler(EVENT_REBUILD);
	if (status < 0) {
		HA_LG_ER("HA_AGENT_STNBYAdm:%s() - remove_handler(EVENT_REBUILD) failed.", __func__);
	}	
	
	// Shutdown message
	ACE_Message_Block* mb=0;
	ACE_NEW_NORETURN(mb, ACE_Message_Block());
	if (mb == 0){
		HA_TRACE("HA_AGENT_STNBYAdm:Failed create message AGENT_SHUTDOWN");
	} else {
		mb->msg_type(AGENT_SHUTDOWN);
		if (this->putq(mb) < 0){
			mb->release();
			mb=0;
			HA_TRACE("HA_AGENT_STNBYAdm:Failed to send msg AGENT_SHUTDOWN");
		}else{
			HA_TRACE("HA_AGENT_STNBYAdm:AGENT_SHUTDOWN Ordered Internally");
		}	
	}

	this->ShutdownDone=true;
	HA_TRACE_LEAVE();
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::handle_signal(int signum, siginfo_t*, ucontext_t *) 
{
	HA_TRACE_ENTER();

	if (SIGINT == signum){
		HA_TRACE("HA_AGENT_STNBYAdm: - signal SIGINT caught...");
		this->stop();
	}else if(SIGHUP == signum){
		HA_TRACE("HA_AGENT_STNBYAdm: - signal SIGHUP caught...");
		this->readConfig_r();
	}else if(EVENT_REBUILD == signum){
		HA_TRACE("HA_AGENT_STNBYAdm: - signal EVENT_REBUILD caught...");
		if (this->m_DMObj != 0){
			this->m_DMObj->setRebuildInProgress();
		}	
	}else{
		HA_TRACE_1("HA_AGENT_STNBYAdm: - other signal caught..[%d]", signum);
		this->stop();
	}

	HA_TRACE_LEAVE();
	return 0;	
}

//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::close(u_long /* flags */)
{
	HA_TRACE_ENTER();

	if (0 != m_fileObj) {
		delete m_fileObj;
		m_fileObj=0;
	}	

	if (0 != this->m_DMObj) {
		this->m_DMObj->close();
		this->m_DMObj->wait();
		delete this->m_DMObj;
		this->m_DMObj=0;
	}

	m_globalInstance->setTasksDone(false);
	HA_TRACE_LEAVE();
	return 0;
}

//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::svc() 
{
	bool errorDetected=false;
	bool done=false;
	int res=0;
	HA_TRACE_ENTER();

	/* start, inititate, perform any passive tasks here. */
	/* init DrbdMon class */

	ACE_NEW_NORETURN(this->m_DMObj, HA_AGENT_DRBDMon());
	if (0 == this->m_DMObj) {
		HA_LG_ER("HA_AGENT_STNBYAdm:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_DRBDMon", __func__);
		errorDetected=true;
	} else {
		if (this->m_DMObj->open() != 0) {
			HA_LG_ER("HA_AGENT_STNBYAdm:%s() - Open failed for HA_AGENT_DRBDMon", __func__);
			errorDetected=true;
		}
	}
	if (!errorDetected) {
		HA_AGENT_PersistantInfoT pInfo;
		if (m_globalInstance->PWROff()->get_persis_info(pInfo) == true) {
			if (strcmp(pInfo.cstate, "StartingSyncS") == 0 	|| 
				strcmp(pInfo.cstate, "SyncSource") 	  == 0 	||
				strcmp(pInfo.cstate, "PausedSyncS")   == 0   ) {
				/*DRBD1 resource state was in SyncSource, HA_AGENT can not be 
				STANDBY on SyncSource. So, lets take the STANDBY role first, 
				and wait for the Active HA_AGENT to trigger a Failover to become
				active on this node.
				*/
				HA_LG_ER("HA_AGENT_RoleMgr:%s() Old DRBD Connection state: [%s].", __func__, pInfo.cstate);
			}
		}
		pInfo.rebootCount=0;
		if (m_globalInstance->PWROff()->write_persis_info(pInfo) == false ) {
   			HA_LG_ER("HA_AGENT_RoleMgr:%s() failure in updating persistant file.", __func__);
		}
	}
	if (!errorDetected) {
		if (this->m_globalInstance->Utils()->removeRCF() < 0){
			HA_LG_ER("%s():remove Reboot Count File failed", __func__);
		}
	}
	if (errorDetected) {
		if (m_globalInstance->haMode()){
			m_globalInstance->compRestart();
		} else {
			exit (EXIT_FAILURE);
		}
	}

	/* inform Global class that standby jobs are done */
	m_globalInstance->setTasksDone(true);

	HA_LG_IN("HA AGENT Role: STANDBY");
	HA_TRACE("HA_AGENT_STNBYAdm: Thread is running now..");
	ACE_Message_Block* mb=0;
	while (!done){
		res = this->getq(mb);
		if (res < 0)
			break;
		
		switch( mb->msg_type() ){
			case AGENT_SHUTDOWN: {
				HA_TRACE("HA_AGENT_STNBYAdm: received AGENT_SHUTDOWN");
				mb->release();					   
				mb=0;
				done=true;
				break;
			}

			default: {
				HA_TRACE_1("HA_AGENT_STNBYAdm:[%d] Unknown message received:", mb->msg_type());
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
int HA_AGENT_STNBYAdm::initClasses() {
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	/* initialize HA_AGENT_LFile class */
    if (rCode == 0) {
        ACE_NEW_NORETURN(this->m_fileObj, HA_AGENT_LFile());
        if (0 == this->m_fileObj) {
            HA_LG_ER("HA_AGENT_STNBYAdm:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_LFile", __func__);
            rCode=-1;
        }
    }

	/* init Config class and readConfig */
    if (rCode == 0) {
        if (m_globalInstance->Config()->readConfig() < 0) {
            HA_LG_ER("%s(): Failed to read configuration paramters", __func__);
            rCode=-1;
        }
    }

	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------
int HA_AGENT_STNBYAdm::rmlockfile() {
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	if (m_fileObj->LFileExist()) {
        m_fileObj->RMLFile();
    }
	
	HA_TRACE_LEAVE();
	return rCode;
}
//--------------------------------------------------------------------------
void HA_AGENT_STNBYAdm::readConfig_r()
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
