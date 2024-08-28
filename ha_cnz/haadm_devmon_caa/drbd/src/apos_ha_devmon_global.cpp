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
 * @file apos_ha_devmon_global.cpp
 *
 * @brief
 * 
 * A singleton class
 * This class contains all the global declarations used by 
 * other Devmon classes.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 ****************************************************************************/

#include "apos_ha_devmon_global.h"

//-----------------------------------------------------------------------------

Global::Global() :
   m_shutdownOrdered(false),
   m_haMode(false),
   m_dMonObj(0),
   m_dRcvyObj(0),
   m_utilObj(0),
   m_cngObj(0),
   m_haObj(0),
   fifo_fd(ACE_INVALID_HANDLE)
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

	if (this->m_dMonObj) {
		delete this->m_dMonObj;
		this->m_dMonObj=0;
	}

	if (this->m_dRcvyObj) {
		delete this->m_dRcvyObj;
		this->m_dRcvyObj=0;
	}	
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------

void Global::notifyGlobalShutdown()
{
	HA_TRACE("%s(): leaving it for future", __func__);
}

//----------------------------------------------------------------------------

ACE_Reactor* Global::reactor() 
{
   return ACE_Reactor::instance();
}

//----------------------------------------------------------------------------

HA_DEVMON_DRBDMon* Global::drbdMon()
{
	HA_TRACE_ENTER();
	if (0 == this->m_dMonObj) {
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_dMonObj == 0) {
			ACE_NEW_NORETURN(this->m_dMonObj, HA_DEVMON_DRBDMon());
			if (0 == this->m_dMonObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}	
		}
	}
	HA_TRACE_LEAVE();	
	return this->m_dMonObj;
}

//----------------------------------------------------------------------------

HA_DEVMON_DRBDRecovery* Global::drbdRecovery()
{
	HA_TRACE_ENTER();
	if (0 == this->m_dRcvyObj) {
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_dRcvyObj == 0) {
			ACE_NEW_NORETURN(this->m_dRcvyObj, HA_DEVMON_DRBDRecovery());
			if (0 == this->m_dRcvyObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}
		}
	}
	HA_TRACE_LEAVE();
	return this->m_dRcvyObj;
}
				                                                                                     
//----------------------------------------------------------------------------

HA_DEVMON_Utils* Global::Utils()
{
	HA_TRACE_ENTER();
	if (this->m_utilObj == 0) {
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_utilObj == 0) {
			ACE_NEW_NORETURN(this->m_utilObj, HA_DEVMON_Utils());
			if (0 == this->m_utilObj) {
				HA_LG_ER("%s() Memory Allocation Failed", __func__);
			}
		}	
	}
	HA_TRACE_LEAVE();
	return this->m_utilObj;
}

//----------------------------------------------------------------------------

HA_DEVMON_Config* Global::Config()
{
	HA_TRACE_ENTER();
	if (0 == this->m_utilObj) {
		// Serialize access
		ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->thread_lock_);
		if (this->m_cngObj == 0) {
			ACE_NEW_NORETURN(this->m_cngObj, HA_DEVMON_Config());
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

	HA_TRACE_1("%s() Request CMW to restart ourself",__func__);
	if (m_haObj != 0) {
		ACS_APGCC_ReturnType result = m_haObj->componentReportError(ACS_APGCC_COMPONENT_RESTART);
		if (result != ACS_APGCC_SUCCESS) {
			HA_LG_ER("%s() Failed to call CMW, Lets call exit() instead", __func__);
			HA_TRACE_LEAVE();
			exit(EXIT_FAILURE);
		}
	}
	HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------

void Global::nodefailOver()
{
    HA_TRACE_ENTER();

    HA_TRACE("%s() Request CMW to initiate the Failover policy",__func__);
    if (m_haObj != 0) {
        ACS_APGCC_ReturnType result = m_haObj->componentReportError(ACS_APGCC_NODE_FAILOVER);
        if (result != ACS_APGCC_SUCCESS) {
            HA_LG_ER("%s() Failed to call CMW, Lets call reboot() instead", __func__);
        }else {
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

    HA_TRACE("%s() Request CMW to initiate the FailFast policy",__func__);
    if (m_haObj != 0) {
        ACS_APGCC_ReturnType result = m_haObj->componentReportError(ACS_APGCC_NODE_FAILFAST);
        if (result != ACS_APGCC_SUCCESS) {
            HA_LG_ER("%s() Failed to call CMW, Lets call reboot() instead", __func__);
        }else {
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

int Global::fifo_open()
{
	HA_TRACE_ENTER();
	int rCode=0;
	rCode = mkfifo(APOS_HA_DEVMON_2_AGENT_PIPE, 0666);
	int err = ACE_OS::last_error();
	if (rCode != 0 ) {
		if (err != EEXIST ) {
			HA_LG_ER("Global:%s mkfifo failed", __func__);
			rCode=-1;
		}else {
			HA_LG_IN("Global:%s fifo already exists", __func__);
			rCode=0;
		}
	}
	if (rCode == 0) {
		fifo_fd = ACE_OS::open(APOS_HA_DEVMON_2_AGENT_PIPE, O_RDWR|O_NONBLOCK);
		if (fifo_fd == -1) {
			HA_LG_ER("Global: Error Opening fifo: [%s]", APOS_HA_DEVMON_2_AGENT_PIPE);
			rCode=-1;
		}
	}
				 
	HA_TRACE_LEAVE();
	return rCode;
}

//--------------------------------------------------------------------------------

int Global::fifo_close()
{
	HA_TRACE_ENTER();
	ACE_INT32 fd;
	ACE_INT32 rCode=0;
	fd = ::close(fifo_fd);
	if (fd == -1) {
		HA_LG_ER("Global: Error in fifo close:[%s]", APOS_HA_DEVMON_2_AGENT_PIPE);
		rCode=-1;
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//----------------------------------------------------------------------------

int Global :: write_buffer( HA_DEVMON_MsgT const* send )
{
	HA_TRACE_ENTER();
	ACE_Guard<ACE_Recursive_Thread_Mutex> guard(this->write_lock_);
	char buffer[1024] = {0};
	char* dest = buffer;
	memcpy( dest, &send->type, sizeof( HA_DEVMON_MsgTypeT ));
	dest += sizeof(HA_DEVMON_MsgTypeT);
	memcpy( dest, &send->size, sizeof( ACE_UINT32 ));
	dest += sizeof(ACE_UINT32);
	memcpy( dest, send->data, sizeof( DRBD_InfoT ));
	dest += sizeof(DRBD_InfoT); 
	int byteCount = ACE_OS::write( this->fifo_fd, buffer, dest - buffer );
	if ( byteCount != dest - buffer ) {
		HA_LG_ER("Global:%s() error occured while in write()", __func__);
	}
	HA_TRACE_1("%s() - write success, bytes written:[%d]", __func__, byteCount);
	HA_TRACE_LEAVE();
	return byteCount == dest - buffer ? 0 : -1;
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
    }else {
		if (pid < 0) {
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
    if (rCode != 0) {
        /* sleep for some time to allow reboot to happen */
        m_utilObj->msec_sleep(m_cngObj->getConfig().rebootTmout);
	}
    /* we should not have come this far. If we are here for any reason,
       things are in real BAD shape. The only thing we can do after
       this point is RIP. */
    exit(EXIT_FAILURE);
    HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------

