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
 * @file apos_ha_agent_rolemngr.h
 *
 * @brief
 * 	 
 * This class is resposible for AGENT 
 * functionality on active node
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_rolemngr.h"

//-----------------------------------------------------------------------------
HA_AGENT_RoleMgr::HA_AGENT_RoleMgr():
 m_globalInstance(HA_AGENT_Global::instance()),
 m_regHndlr(false),
 m_arpObj(0),
 m_pingObj(0),
 m_ndiscObj(0),
 m_drbdObj(0),
 m_fileObj(0),
 m_immObj(0),
 m_DMObj(0),
 m_reactorRunner(0),
 m_handle(ACE_INVALID_HANDLE),
 m_startJobsDone(false),
 m_isVirtual(false)
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
HA_AGENT_RoleMgr::~HA_AGENT_RoleMgr()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::p_open()
{
	HA_TRACE_ENTER();
	ACE_INT32 fd;
    ACE_INT32 rCode=0;
    
	rCode = mkfifo(APOS_HA_DEVMON_2_AGENT_PIPE, 0666);
	int err = ACE_OS::last_error();
	if (rCode != 0 ) {
		if (err != EEXIST ) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s mkfifo failed", __func__);
			rCode=-1;
		} else {
			HA_TRACE_2("HA_AGENT_RoleMgr:%s fifo found", __func__);
			rCode=0;
		}
	}

	if (rCode == 0) {
		fd = ACE_OS::open(APOS_HA_DEVMON_2_AGENT_PIPE, O_RDWR);
		if (fd == -1) {
			HA_LG_ER("HA_AGENT_RoleMgr: Error Creating: [%s]", APOS_HA_DEVMON_2_AGENT_PIPE);
			rCode=-1;
		}else{
			setHandle((ACE_HANDLE)fd);
		}
	}
         
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::p_close()
{
	HA_TRACE_ENTER();
    ACE_INT32 fd;
    ACE_INT32 rCode=0;
    
	fd = ::close(m_handle);
	if (fd == -1) {
		HA_LG_ER("HA_AGENT_RoleMgr: Error in close:[%s]", APOS_HA_DEVMON_2_AGENT_PIPE);
        rCode=-1;
	}else{
        setHandle(ACE_INVALID_HANDLE); 
    }
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
inline
void HA_AGENT_RoleMgr::setHandle(ACE_HANDLE p_handle)
{
    this->m_handle = p_handle;
}

//-----------------------------------------------------------------------------
inline
ACE_HANDLE HA_AGENT_RoleMgr::get_handle(void) const 
{
    HA_TRACE_4("Handle: %d", this->m_handle);
    return this->m_handle;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::initRoleMgr()
{
	HA_TRACE_ENTER();
    int rCode=0;

    /* open fifo pipe */
	if (this->p_open() < 0){
		HA_LG_ER("%s() - PIPE Open Failed", __func__);
		rCode=-1;
	}	

	/* allocate memory to the reactor object */
	if (rCode == 0) {
		ACE_NEW_NORETURN(m_reactorRunner, APOS_HA_ReactorRunner(m_globalInstance->reactor(), MAIN_REACTOR));
		if (0 == m_reactorRunner) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() -MEMORY PROBLEM: Failed to allocate APOS_HA_ReactorRunner", __func__);
			rCode=-1;
		} else {
			rCode= m_reactorRunner->open();
			if (rCode != 0) {
				HA_LG_ER("HA_AGENT_RoleMgr:%s() - Reactor open failed", __func__);
				rCode=-1;
			}
		}
	}

    /* register pipe handler to receive events from DevMon */
	if (rCode == 0) {
		int status = m_globalInstance->reactor()->register_handler(this, ACE_Event_Handler::READ_MASK);
		if (status < 0) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - register_handler(this, ACE_Event_Handler::READ_MASK) Failed", __func__);
			rCode=-1;
		} else	{
			m_regHndlr=true;
		}	
	} 

	/* initialize drbd class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_drbdObj, HA_AGENT_DRBDMgr());
		if (0 == this->m_drbdObj) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_DRBDMgr", __func__);
			rCode=-1;	
		}
    }

	/* initialize HA_AGENT_ImmOm class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_immObj, HA_AGENT_ImmOm());
		if (0 == this->m_immObj) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_immOm", __func__);
			rCode=-1;
		}
		else
			m_isVirtual = this->m_immObj->isVirtualNode();
	}


	if(m_isVirtual)
	{
		/* initialize ping class */
		if (rCode == 0) {
			ACE_NEW_NORETURN(this->m_pingObj, HA_AGENT_Ping());
			if (0 == this->m_pingObj) {
				HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_Ping", __func__);
				rCode=-1;
			}
		}
	}
	else
	{
		/* initialize arp class */
		if (rCode == 0) {
			ACE_NEW_NORETURN(this->m_arpObj, HA_AGENT_Arping());
			if (0 == this->m_arpObj) {
				HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_Arping", __func__);
				rCode=-1;
			}
		}
	}

	/* initialize ndisc class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_ndiscObj, HA_AGENT_ndisc());
		if (0 == this->m_ndiscObj) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_ndisc", __func__);
			rCode=-1;	
		} 
  }

	/* initialize HA_AGENT_LFile class */
	if (rCode == 0) {
		ACE_NEW_NORETURN(this->m_fileObj, HA_AGENT_LFile());
		if (0 == this->m_immObj) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_LFile", __func__);
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::open()
{
	HA_TRACE_ENTER();
	int rCode=0;

    int status = this->sig_shutdown_.register_handler(SIGALRM, this);
    if (status < 0) {
        HA_LG_ER("HA_AGENT_Adm: %s() register_handler(SIGALRM,this) failed..",__func__);
        rCode=-1;
    }

	if (rCode != -1) {
		if (this->activate(THR_NEW_LWP|THR_JOINABLE) < 0) {
			HA_LG_ER("%s() - Failed to start main svc thread.", __func__);
			rCode=-1;
		}	
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::svc()
{
	ACE_Message_Block* mb = NULL;
	bool running = true;
	bool errorDetected=false;

	HA_TRACE_ENTER();

	if (!errorDetected) {	
		if (this->initRoleMgr() < 0){
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - initRoleMgr FAILED", __func__);
			errorDetected=true;
		}	
    }
    
    /* perform health check on local node */
    if (!errorDetected) {
        if (this->healthCheck() < 0){
            HA_LG_ER("HA_AGENT_RoleMgr:%s() - healthCheck failed", __func__);
            errorDetected=true;
        }
    }    

    /* Execute splitbrain algo*/
	if (!errorDetected) {
        if (this->splitBrainAlgo() < 0) {
            HA_LG_ER("HA_AGENT_RoleMgr:%s() - splitBrainAlgo failed", __func__);
            errorDetected=true;
        }   
    }
	
    /* Mount DRBD(/data) and Configure MIP*/
    if (!errorDetected) {
        if (this->StartJobs() < 0) {
            HA_LG_ER("HA_AGENT_RoleMgr:%s() - StartJobs failed", __func__);
            errorDetected=true;
        }
    }   

	/* initialize HA_AGENT_DRBDMon class */
	if (!errorDetected) {
		ACE_NEW_NORETURN(this->m_DMObj, HA_AGENT_DRBDMon());	
		if (0 == this->m_DMObj) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - MEMORY PROBLEM: Failed to allocate HA_AGENT_DRBDMon", __func__);
			errorDetected=true;
		}	else {
			int rCode = this->m_DMObj->open();
			if (rCode != 0) {
				HA_LG_ER("HA_AGENT_RoleMgr:%s() - HA_AGENT_DRBDMon open failed.", __func__);
				errorDetected=true;
			}
		}
	}
    
    /* before starting the thread, check if we have seen any big faults */
	if (errorDetected) {
		if (m_globalInstance->haMode()){
			m_globalInstance->compRestart();
		} else {
			exit (EXIT_FAILURE);
		}
	}	

	/* inform Global class that rolemngr jobs are done */
	m_globalInstance->setTasksDone(true);

	HA_LG_IN("HA AGENT Role: ACTIVE");
    HA_TRACE_1("HA_AGENT_RoleMgr:- Thread running");

    // nothing to do now, wait for a call back from AMF to close ourself.
	while (running){
		try {
			if (this->getq(mb) < 0){
				HA_LG_ER("HA_AGENT_RoleMgr: getq() failed");
				break;
			}

			// Check msg type
			switch(mb->msg_type()){
				case ROLEMGR_CLOSE:
						HA_TRACE("HA_AGENT_RoleMgr: ROLEMGR_CLOSE Received");
						mb->release();
						running=false;
						break;

				default:
						HA_LG_IN("WARNING:HA_AGENT_RoleMgr - not handled message received: %i", mb->msg_type());
						mb->release();
						running=false;
						break;
			}
		}

		catch(...){
			HA_LG_ER("HA_AGENT_RoleMgr: EXCEPTION!");
		}
		
	}
	shutDown_all();

	HA_TRACE_LEAVE();
	return 0;
}

//-----------------------------------------------------------------------------
void HA_AGENT_RoleMgr::shutDown_all()
{
	HA_TRACE_ENTER();	

	if (this->m_startJobsDone) {
		if (this->StopJobs() < 0) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() - StopJobs failed", __func__);
			/* It is not healhty to keep the node up if stop jobs fails 
			   CMW is anyway going to take the same recovery action if we
			   reply failure to quiesced jobs. lets initiate a quick reset.
			 */
			if (m_globalInstance->haMode()) {
            	// Report to AMF that we want to reset our node
            	m_globalInstance->nodefailOver();
        	}
			exit(EXIT_FAILURE);
		}
	}
	
	/* reset the flags */
	m_globalInstance->setTasksDone(false);
	this->m_startJobsDone=false;
	HA_TRACE_LEAVE();
}


//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::handle_signal(int signum, siginfo_t*, ucontext_t *) 
{
	HA_TRACE_ENTER();
	int rCode=0;
	switch (signum) {
		case SIGALRM:
			HA_TRACE("HA_AGENT_RoleMgr:%s() - signal SIGALRM caught...", __func__);
			if (this->m_globalInstance->Utils()) {
				this->m_globalInstance->Utils()->forceExit();
			}
			break;
		default:
			HA_TRACE_1("HA_AGENT_RoleMgr:%s() - other signal caught..[%d]", __func__, signum);
			break;
	}	

	HA_TRACE_LEAVE();	
	return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::close(u_long) 
{
	HA_TRACE_ENTER();

	// check that we're really shutting down.
	// HA_AGENT_Adm sets this flag to true when in gracefull shutdwon
	if (!m_globalInstance->shutdown_ordered()) {
		HA_LG_ER("HA_AGENT_RoleMgr:%s(u_long): Abnormal shutdown of HA_AGENT_RoleMgr", __func__);
		exit(EXIT_FAILURE);
	}

	int status = this->sig_shutdown_.remove_handler(SIGALRM);
    if (status < 0) {
        HA_LG_ER("HA_AGENT_RoleMgr:%s() - remove_handler(SIGALRM) failed.", __func__);
    }

	if (this->m_drbdObj) {
		delete this->m_drbdObj;
		this->m_drbdObj=0;
	}

	if (this->m_arpObj) {
		delete this->m_arpObj;
		this->m_arpObj=0;
	}

	if (this->m_pingObj) {
		delete this->m_pingObj;
		this->m_pingObj=0;
	}

	if (this->m_ndiscObj) {
		delete this->m_ndiscObj;
		this->m_ndiscObj=0;
	}

	if (this->m_immObj) {
		delete this->m_immObj;
		this->m_immObj=0;
	}

	if (this->m_fileObj) {
		delete this->m_fileObj;
		this->m_fileObj=0;
	}	

	if (this->m_DMObj) {
		this->m_DMObj->close();
		this->m_DMObj->wait();
		delete this->m_DMObj;
		this->m_DMObj=0;
	}

	if (this->m_reactorRunner) {
		this->m_reactorRunner->stop();
		this->m_reactorRunner->wait();
		delete this->m_reactorRunner;
		this->m_reactorRunner=0;
	}

	// close the pipe fd
	this->p_close();

	HA_TRACE_LEAVE();
	return 0;
}	

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::close()
{
	HA_TRACE_ENTER();

	ACE_Message_Block* mb = 0;
	ACE_NEW_NORETURN( mb, ACE_Message_Block());

	if (m_regHndlr) {
		int status = m_globalInstance->reactor()->remove_handler(this, ACE_Event_Handler::ALL_EVENTS_MASK | ACE_Event_Handler::DONT_CALL);
		if (status < 0)
			HA_LG_ER("%s: remove_handler() called failed...", __func__);
		else
			m_regHndlr=false;
	}		

	int rCode=0;
	if (0 == mb) {
		HA_LG_ER("%s() Failed to create mb object", __func__);
        rCode=-1;
	}

	if (rCode != -1) {
		mb->msg_type(ROLEMGR_CLOSE);
		if (this->putq(mb) < 0){
			HA_LG_ER("%s() Fail to post ROLEMGR_CLOSE to ourself", __func__);
            mb->release();
			rCode=-1;
		}
	}

	HA_TRACE_LEAVE();
	return rCode;
}	

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::handle_input(ACE_HANDLE fd)
{
	HA_TRACE_ENTER();
	/* as we have only one fd to wait on, we can as well
	   get this fd from get_handle() */
	ACE_UNUSED_ARG(fd);
	this->dispatch();
	HA_TRACE_LEAVE();
	return 0;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::handle_close(ACE_HANDLE, ACE_Reactor_Mask mask)
{
	HA_TRACE_ENTER();
	ACE_UNUSED_ARG(mask);

	if (m_regHndlr) {
		int status = m_globalInstance->reactor()->remove_handler(this, ACE_Event_Handler::ALL_EVENTS_MASK | ACE_Event_Handler::DONT_CALL);
		if (status < 0)
			HA_LG_ER("%s: remove_handler() called failed...", __func__);
		else
			m_regHndlr=false;
	}		
	HA_TRACE_LEAVE();
	return 0;
}
//-----------------------------------------------------------------------------
void HA_AGENT_RoleMgr::printMsg(HA_DEVMON_MsgT* msg)
{
	HA_TRACE_ENTER();

	HA_TRACE("Message received from DevMon:---->");
	HA_TRACE("==================================");
	HA_TRACE("msg->type: [%d]", msg->type);
	HA_TRACE("msg->size: [%d]",msg->size);
	HA_TRACE("msg->data->isConfigured:[%d]", msg->data->isConfigured);
	HA_TRACE("msg->data->cstate:[%s]", msg->data->cstate);
	HA_TRACE("msg->data->role:[%s]", msg->data->role);
	HA_TRACE("msg->data->dstate:[%s]", msg->data->dstate);
	HA_TRACE("msg->data->diskinfo:[%s]", msg->data->diskinfo);
	HA_TRACE("==================================");

	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::processMsg(HA_DEVMON_MsgT* msg)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

	switch ((HA_DEVMON_MsgTypeT)msg->type) {
		case DRBD_DISK_HEALTHY: {
			/* process disk healthy */
			HA_TRACE("HA_AGENT_RoleMgr:%s() Disk Healthy", __func__);	
			break;
		}

		case DRBD_DISK_FAULTY: {
			/* process disk healthy */
			HA_TRACE("HA_AGENT_RoleMgr:%s() Disk Faulty", __func__);	
			break;
		}

		case DRBD_ROLE_CHANGE: {
			/* process disk healthy */
			HA_TRACE("HA_AGENT_RoleMgr:%s() Disk role change", __func__);	
			// check if there is real role change or just the devmon
			// is lying.
			bool OnStart=false;
			if (m_drbdObj->drbdHealth(OnStart) < 0) {
				if (m_globalInstance->haMode()) {
        			// Report to AMF to initiage failvoer process.
           			m_globalInstance->nodefailOver();
				}
				// --noha case
           		exit(EXIT_FAILURE);
			} else {
					HA_TRACE("HA_AGENT_RoleMgr:%s() No Role change Observed, Ignoring the request", __func__);
			}
			break;
		}	

		case DRBD_CONN_ERROR: {
			/* process disk healthy */
			HA_TRACE("HA_AGENT_RoleMgr:%s() DRBD_CONN_ERROR", __func__);	
			break;
		}
		
		default: {
			/* Invalid type */
			HA_TRACE("HA_AGENT_RoleMgr:%s() Invalid msg", __func__);	
			break;
		}	
	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
void HA_AGENT_RoleMgr::dispatch()
{
	HA_TRACE_ENTER();
	HA_DEVMON_MsgT *msg=0;

	ACE_NEW_NORETURN(msg, HA_DEVMON_MsgT);
	if (0 == msg) {
		HA_LG_ER("HA_AGENT_RoleMgr:%s() MEMORY PROBLEM (msg)", __func__);
		return;
	}
	ACE_OS::memset(msg, 0, sizeof(HA_DEVMON_MsgT));
	if (readMsg(msg) < 0) {
		HA_LG_ER("HA_AGENT_RoleMgr:%s() Failed to read Message from DevMon", __func__);
	} else {
		printMsg(msg);
		if (processMsg(msg) < 0) {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() Failed to process message", __func__);
		}	
	}
	delete msg->data;
	delete msg;
	msg=0;
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::healthCheck() 
{
    HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

	if (rCode == 0) {
		HA_AGENT_PersistantInfoT pInfo;
		memset(&pInfo,0,sizeof(HA_AGENT_PersistantInfoT));
		if (m_globalInstance->PWROff()->get_persis_info(pInfo) == true) {
			if (strcmp(pInfo.cstate, "StartingSyncT") == 0 || 
				strcmp(pInfo.cstate, "SyncTarget") 	  == 0 ||
				strcmp(pInfo.cstate, "PausedSyncT")   == 0 ) {
				/* We are trying to become active on the node which 
				has in-consistent data. We reboot ourself to avoid the 
				data loss to the count equal to configured Count and take
				the active role if still is needed with an account to loss
				of data to avoid APG out of service situation.
				*/
				if (pInfo.rebootCount >= m_globalInstance->Config()->getConfig().rebootCount) {
					if (this->m_globalInstance->Utils()->APEvent() < 0) {
						HA_LG_ER("HA_AGENT_RoleMgr:%s() failure to write APEvent()", __func__);
					}
				} else {
					if (this->m_globalInstance->Utils()->createRCF() < 0) {
						HA_LG_ER("HA_AGENT_RoleMgr:%s() failure to createRCF()", __func__);
					}
				}

				pInfo.rebootCount++;
				HA_LG_IN("HA_AGENT_RoleMgr:%s() Persistant File->Connection State:[%s]", __func__, pInfo.cstate);
				HA_LG_IN("HA_AGENT_RoleMgr:%s() Persistant File->Reboot Count:[%d]", __func__, pInfo.rebootCount);

				if (m_globalInstance->PWROff()->write_persis_info(pInfo) == false ) {
					HA_LG_ER("HA_AGENT_RoleMgr:%s() failure in updating persistant file.", __func__);
					rCode=-1;
				}
				if (m_globalInstance->haMode()) {
					HA_LG_ER("HA_AGENT_RoleMgr:%s() WARNING:HA AGENT trying to become ACTIVE on Inconsistent Disk, this might lead to data loss", __func__);
					HA_LG_ER("HA_AGENT_RoleMgr:%s() Initiating nodefailOver", __func__);
					m_globalInstance->nodefailOver();
				}

				// exit in case of no-ha mode or nodefailOver fails
				exit(EXIT_FAILURE);
			} else {
				if (pInfo.rebootCount > 0) {
					pInfo.rebootCount=0;
					if (m_globalInstance->PWROff()->write_persis_info(pInfo) == false ) {
						HA_LG_ER("HA_AGENT_RoleMgr:%s() failure in updating persistant file.", __func__);
					}
				}
				if (rCode == 0) {
					bool OnStart=true; 
					if (m_drbdObj->drbdHealth(OnStart) < 0) {
						HA_LG_ER("HA_AGENT_RoleMgr:%s() healthCheck failed", __func__);
						rCode=-1;
					}
				}
				// remove reboot count file now.
               	if (this->m_globalInstance->Utils()->removeRCF() < 0) {
               		HA_LG_ER("HA_AGENT_RoleMgr:%s() failure in removeRCF()", __func__);
				}
			}
		} else {
			HA_LG_ER("HA_AGENT_RoleMgr:%s() get_persis_info() failed", __func__);
			rCode=-1;
		}
	}
    
    // any other health monitor.
    HA_TRACE_LEAVE();
    return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::splitBrainAlgo()
{
  HA_TRACE_ENTER();
	bool arping=false;

    /* Level One */
	if (m_immObj->peerNodeLockd() == true) {
		/* It is safe to assume that, if the peer node is locked,
		   we are out of split brain condition and take the active
		   role safely.
		*/
		HA_LG_IN("HA_AGENT_RoleMgr:%s() PEER Node Disabled/Locked, taking the active role", __func__);
	} else { 
		if (m_globalInstance->haMode()) {
			if ( m_globalInstance->getOldhaState() == ACS_APGCC_AMF_HA_UNDEFINED && !m_fileObj->LFileExist()) {
				HA_LG_IN("HA_AGENT_RoleMgr:%s() AGENT OldRole: UNDEFINED", __func__);
			} else { arping=true; }
		} else { arping=true; } 	
	}

	if (arping) {
		bool isSplitBrainDetected=false;
		/*	send an arp rquest to 
				- primary_sc-a
				- primary_sc-b
				- nbi address (ipv4 and ipv6)
			 If there is no response for either of the requests, then there 
			 is no active node exist in the cluster.
		*/
		for( unsigned int cntr=0; cntr < m_globalInstance->Config()->getConfig().mipInfo.size; cntr++)
		{
//		  if (this->m_globalInstance->Utils()->isIPv4(m_globalInstance->Config()->getConfig().mipInfo.ipAddress[cntr])) {
			 int res = strcmp((m_globalInstance->Config()->getConfig().mipInfo.interface[cntr]), "eth1");
			 HA_LG_IN("%s(): interface compare result is %d .", __func__ , res);
			  if(m_isVirtual)	// use PING in VIRTUAL environmet
			  {
				if (res !=0) //Skipping PING if is public interface
				{
				  if ((m_pingObj->ping(m_globalInstance->Config()->getConfig().mipInfo.ipAddress[cntr],
						  m_globalInstance->Config()->getConfig().mipInfo.interface[cntr]) == true)) {
					  isSplitBrainDetected=true;
					  break;
				  }
				}
			  }
			  else			// use ARP in NATIVE environment
			  {
				  if (m_arpObj->arping(m_globalInstance->Config()->getConfig().mipInfo.ipAddress[cntr],
						  m_globalInstance->Config()->getConfig().mipInfo.interface[cntr]) == true ) {
					  isSplitBrainDetected=true;
					  break;
				  }
			  }

/*			} else if(this->m_globalInstance->Utils()->isIPv6(m_globalInstance->Config()->getConfig().mipInfo.ipAddress[cntr])) {
			  if (m_ndiscObj->ndisc(m_globalInstance->Config()->getConfig().mipInfo.ipAddress[cntr],
			       m_globalInstance->Config()->getConfig().mipInfo.interface[cntr]) == true ) {
			    isSplitBrainDetected=true;
			    break;
			  }  
		  }	  */
		}
		if (isSplitBrainDetected) {
			/* response received for arping request on MIP, this means we have
			active node up and running in the cluster and our back-plane
			is broken. Requesting CMW(AMF) to restart ourself or to 
			perform a node failover might not help. The best we could do
			is to ask CMW for a reboot. 
			*/
			HA_LG_ER("HA_AGENT_RoleMgr:%s() Split-Brain detected, Found an Active node in the cluster, initiating nodefailOver", __func__); 
			/* create the lock file before we go for reset */
			if (m_fileObj->LFile() < 0) {
				HA_LG_ER("HA_AGENT_RoleMgr:%s() Failed to create lock-file", __func__);
			}
			if (m_globalInstance->haMode()) {
				// Report to AMF that we want to restart of ourselves
				m_globalInstance->nodefailOver();
				/* we should not have come this far, in case if we are here, 
				--noha exit will take care of exiting the daemon
				*/
			}
			/* In case if we are started on --noha mode*/
			HA_LG_ER("HA_AGENT_RoleMgr:%s() Exiting...", __func__);
			exit(EXIT_FAILURE);
		}
	}
	/* arp request not received, we can take the active role,
	remove the traces of the lock-file */
	if (m_fileObj->LFileExist()) {	
 		m_fileObj->RMLFile();	
	}	
    HA_TRACE_LEAVE();
    return 0;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::StartJobs()
{
    HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
    
    if (m_drbdObj->drbdStartJobs() < 0) {
        HA_LG_ER("HA_AGENT_RoleMgr:%s() drbdStartJobs failed", __func__);
        rCode=-1;
    }  
    
    // any other jobs need to be performed along with drbd.
    
	if (rCode != -1) {
		this->m_startJobsDone=true;
	}

    HA_TRACE_LEAVE();
    return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::StopJobs()
{
    HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
    
    if (m_drbdObj->drbdStopJobs() < 0) {
        HA_LG_ER("HA_AGENT_RoleMgr:%s() drbdStopJobs failed", __func__);
        rCode=-1;
    }  
    
    // any other jobs need to be stopped along with drbd.
    HA_TRACE_LEAVE();
    return rCode;
}

//-----------------------------------------------------------------------------
int HA_AGENT_RoleMgr::readMsg(HA_DEVMON_MsgT *msg)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0, nbytes=0;
	char buffer[1024]={0};

	nbytes = ACE_OS::read(this->get_handle(), buffer, sizeof(buffer));
	if (nbytes < 0) {
		HA_LG_ER("HA_AGENT_RoleMgr:%s() error occured while in read()", __func__);
		rCode=-1;
	} else if (nbytes == 0) {
		HA_LG_ER("HA_AGENT_RoleMgr:%s() peer closed connection in read()", __func__);
		rCode=-1;
	}
	if (rCode == 0) {
		char *p_src = buffer;
		mempcpy(&msg->type, p_src, sizeof(HA_DEVMON_MsgTypeT));
		p_src+=sizeof(HA_DEVMON_MsgTypeT);
		mempcpy(&msg->size, p_src, sizeof(ACE_UINT32));
		p_src+=sizeof(ACE_UINT32);
		msg->data = new DRBD_InfoT();
		mempcpy(msg->data, p_src, sizeof(DRBD_InfoT));
		p_src+=sizeof(DRBD_InfoT);
	}

	HA_TRACE_LEAVE();
	return rCode;
}
//-----------------------------------------------------------------------------

