 /* COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_agent_global.cpp
 *
 * @brief
 * 
 * This class makes sure all the class objects are singleton.
 *
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ****************************************************************************/

#include "apos_ha_agent_global.h"

ACE_Recursive_Thread_Mutex Global::varLock_;

//-----------------------------------------------------------------------------
Global::Global() :
   m_shutdownOrdered(false),
   m_haMode(false),
   m_tasksDone(false),
   m_compRestart(false),
   m_oldhaState(ACS_APGCC_AMF_HA_UNDEFINED),
   m_rMgrObj(0),
   m_utilObj(0),
   m_pwrOffObj(0),
   m_cngObj(0),
   m_haObj(0)
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}


//-----------------------------------------------------------------------------
Global::~Global()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
void Global::deactivate()
{
	HA_TRACE_ENTER();

	if (this->m_cngObj) {
		delete this->m_cngObj;
		this->m_cngObj=0;
	}	

	if (this->m_utilObj) {
		delete this->m_utilObj;
		this->m_utilObj=0;
	}	

	if (this->m_pwrOffObj) {
		delete this->m_pwrOffObj;
		this->m_pwrOffObj=0;
	}

	if (this->m_rMgrObj){
		delete this->m_rMgrObj;
		this->m_rMgrObj=0;
	}	

	/* reset all the counter */
	this->reset();

	HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------
ACE_Reactor* Global::reactor() 
{
   return ACE_Reactor::instance();
}

//----------------------------------------------------------------------------
HA_AGENT_RoleMgr* Global::roleMgr()
{
	HA_TRACE_ENTER();
	if (this->m_rMgrObj == 0)
	{
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_rMgrObj == 0) {
			ACE_NEW_NORETURN(this->m_rMgrObj, HA_AGENT_RoleMgr());
			if (0 == this->m_rMgrObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}	
		}
	}
		
	HA_TRACE_LEAVE();	
	return this->m_rMgrObj;
}

//----------------------------------------------------------------------------
HA_AGENT_Utils* Global::Utils()
{
	HA_TRACE_ENTER();
	if (this->m_utilObj == 0)
	{
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_utilObj == 0) {
			ACE_NEW_NORETURN(this->m_utilObj, HA_AGENT_Utils());
			if (0 == this->m_utilObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}
		}	
	}
	
	HA_TRACE_LEAVE();
	return this->m_utilObj;
}

//----------------------------------------------------------------------------
HA_AGENT_PWROff* Global::PWROff()
{
	HA_TRACE_ENTER();
	if (this->m_pwrOffObj == 0)
	{
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_pwrOffObj == 0) {
			ACE_NEW_NORETURN(this->m_pwrOffObj, HA_AGENT_PWROff());
			if (0 == this->m_pwrOffObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			} else {
				if (this->m_pwrOffObj->init() != 0) {
					HA_LG_ER("%s() init failed for HA_AGENT_PWROff", __func__);
				}
			}
		}	
	}

	HA_TRACE_LEAVE();
	return this->m_pwrOffObj;
}

//----------------------------------------------------------------------------
HA_AGENT_Config* Global::Config()
{
	HA_TRACE_ENTER();
	if (this->m_cngObj == 0)
	{
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_cngObj == 0) {
			ACE_NEW_NORETURN(this->m_cngObj, HA_AGENT_Config());
			if (0 == this->m_cngObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}
		}	
	}

	HA_TRACE_LEAVE();
	return this->m_cngObj;
}

//----------------------------------------------------------------------------
void Global::compRestart()
{
	HA_TRACE_ENTER();
	if (this->m_rMgrObj != 0) {
		HA_TRACE("%s(): Shutdown activities BEGIN:", __func__);
		this->m_rMgrObj->shutDown_all();
		HA_TRACE("%s(): Shutdown activities END:", __func__);
	}	

	HA_TRACE_1("%s() Request CMW to restart ourself",__func__);
	m_compRestart=true;
    HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------
void Global::nodefailOver()
{
	HA_TRACE_ENTER();
	if (this->m_rMgrObj != 0) {
		HA_TRACE("%s(): Shutdown activities BEGIN:", __func__);
		this->m_rMgrObj->shutDown_all();
		HA_TRACE("%s(): Shutdown activities END:", __func__);
	}	

	HA_TRACE("%s() Request CMW to initiate the Failover policy",__func__);
	if (m_haObj != 0) {
		ACS_APGCC_ReturnType result = m_haObj->componentReportError(ACS_APGCC_NODE_FAILOVER);
		if (result != ACS_APGCC_SUCCESS) {
            HA_LG_ER("%s() Failed to call CMW, Lets call reboot() instead", __func__);    
		} else {
            m_utilObj->msec_sleep(m_cngObj->getConfig().rebootTmout);
            /* We shall not be here, after the node failover. If we come this far for 
               any reason then rest in peace.
            */
        }
    }
    this->reboot();
	HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------
void Global::nodefailFast()
{
	HA_TRACE_ENTER();

	if (this->m_rMgrObj != 0) {
		HA_TRACE("%s(): Shutdown activities BEGIN:", __func__);
		this->m_rMgrObj->shutDown_all();
		HA_TRACE("%s(): Shutdown activities END:", __func__);
	}	

	HA_TRACE("%s() Request CMW to initiate the FailFast policy",__func__);
	if (m_haObj != 0) {
		ACS_APGCC_ReturnType result = m_haObj->componentReportError(ACS_APGCC_NODE_FAILFAST);
		if (result != ACS_APGCC_SUCCESS) {
            HA_LG_ER("%s() Failed to call CMW, Lets call reboot() instead", __func__);    
		} else {	
            m_utilObj->msec_sleep(m_cngObj->getConfig().rebootTmout);
            /* We shall not be here, after the node failfast. If we come this far for 
               any reason then rest in peace.
            */
        }
    }
    this->reboot();
	HA_TRACE_LEAVE();   
}

//----------------------------------------------------------------------------
void Global::reset()
{
	HA_TRACE_ENTER();
	this->m_shutdownOrdered=false;
	this->m_haMode=false;
	this->m_oldhaState=ACS_APGCC_AMF_HA_UNDEFINED;
	this->m_tasksDone=false;
	this->m_compRestart=false;
	HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------
void Global::reboot()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;

    int status;
    pid_t pid = fork();
    if (pid == 0) {
        if(execlp("sh","sh", "-c", "/sbin/reboot", (char *) NULL) == -1) {
            HA_LG_ER("Global:%s() Fatal error fork() failed. %d", __func__, errno);
            rCode=-1;
        }
    } else { if (pid < 0) {
                HA_LG_ER("Global:%s() Fatal error fork() failed. %d", __func__, errno);
                rCode=-1;
            }
    }

    if (rCode != -1) {
        waitpid(pid, &status, 0);

    	if (status != 0) {
        	rCode=-1;
        	HA_LG_ER("Global:%s() CMD Failed, rCode:[%d]", __func__, status);
    	}	
	}

	if (rCode != 0)
		/* sleep for some time to allow reboot to happen */
		m_utilObj->msec_sleep(m_cngObj->getConfig().rebootTmout);

	/* we should not have come this far. If we are here for any reason, 
	   things are in real BAD shape. The only thing we can do after 
	   this point is RIP. */
	exit(EXIT_FAILURE);

    HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------
int Global::waitOntask()
{
	HA_TRACE_ENTER();
	ACE_UINT32 ticks=0;
    ACE_INT32 rCode=0;
    
    /* as callback timeout is configured in seconds, */
	ACE_UINT32 timeout=m_cngObj->getConfig().callbackTmout;
    HA_TRACE("%s(): Waiting for the RoleMgr thead to Join:", __func__);

	while (!this->m_tasksDone && !this->m_compRestart && ticks++ <= (timeout/APOS_HA_ONESEC_IN_MILLI))
	{
		m_utilObj->msec_sleep(APOS_HA_ONESEC_IN_MILLI);
		HA_TRACE_2("this->m_tasksDone:[%d] ticks:[%d]", this->m_tasksDone, ticks);
	}
    
    if (!this->m_tasksDone || this->m_compRestart)
        rCode=-1;
        
	HA_TRACE_LEAVE();
    return rCode;
}
//----------------------------------------------------------------------------
ACS_APGCC_AMF_HA_StateT Global::getHAState()
{
    ACS_APGCC_AMF_HA_StateT role=ACS_APGCC_AMF_HA_UNDEFINED;
    if (m_haObj != 0){
        role=m_haObj->getHAState();
    }
    return role;
}
//----------------------------------------------------------------------------

