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
 * @file apos_ha_agent_hamanger.cpp
 *
 * @brief
 *
 * This class handles all the HA callbacks.
 *
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/
#include "apos_ha_agent_hamanager.h"

//-----------------------------------------------------------------------------
agentHAClass::agentHAClass(const char* daemon_name, const char* user):APOS_HA_RdeAgent_AmfClass(daemon_name, user)
{
	HA_TRACE_ENTER();
	m_actvAdmObj=0;
    m_stbyAdmObj=0;
    m_globalInstance = HA_AGENT_Global::instance();
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------
agentHAClass::~agentHAClass()
{
	HA_TRACE_ENTER();
	// to be sure.
	this->stopApp(); 
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	HA_TRACE_ENTER();
	m_globalInstance->setOldhaState(previousHAState);
	return this->activateApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	m_globalInstance->setOldhaState(previousHAState);
	return this->passifyApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->stopApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performComponentTerminateJobs(void)
{
	HA_TRACE_ENTER();
	return this->stopApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performComponentRemoveJobs(void)
{
	HA_TRACE_ENTER();
	return this->stopApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performApplicationShutdownJobs()
{
	HA_TRACE_ENTER();
	return this->stopApp();	
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->stopApp();
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::activateApp() 
{
	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	ACE_Guard<ACE_Thread_Mutex> guard(this->m_admLock);
	HA_TRACE_ENTER();
    
    /* Check state transition from stndby->active happend, if so
       stop passive threads and start active one's
    */
    if (0 != this->m_stbyAdmObj) {
        this->stopStndby();
		/* set oldhastate to standby to let active know */
		m_globalInstance->setOldhaState(ACS_APGCC_AMF_HA_STANDBY);
    } 

   	if (0 != this->m_actvAdmObj) {
		HA_TRACE("ha-class: application is already active");
		rCode = ACS_APGCC_SUCCESS;
	} else {	        
		ACE_NEW_NORETURN(this->m_actvAdmObj, HA_AGENT_ACTVAdm());
		if (0 == this->m_actvAdmObj) {
			HA_LG_ER("ha-class: failed to create the instance");
		} else {		
       		int res = this->m_actvAdmObj->start(this); // This will start active functionality. 
           	if (res < 0) {
           		// Failed to start
               	delete this->m_actvAdmObj;
               	this->m_actvAdmObj = 0;
        	} else {
				if (0 != m_globalInstance->waitOntask()) {
                    HA_LG_ER("%s() timeout", __func__);
                } else {
                    HA_TRACE_1("%s() ----------------------------", __func__);
                    HA_TRACE_1("%s() AGENT is now activated by HA", __func__);
                    HA_TRACE_1("%s() ----------------------------", __func__);
                    rCode = ACS_APGCC_SUCCESS;
                }
			}
		}
  	}

	HA_TRACE_LEAVE();
    return rCode;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::passifyApp() 
{
	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	ACE_Guard<ACE_Thread_Mutex> guard(this->m_admLock);
	HA_TRACE_ENTER();

	if (0 != this->m_stbyAdmObj) {
		HA_TRACE("ha-class: application is already standby");
		rCode = ACS_APGCC_SUCCESS;
	} else {	        
		ACE_NEW_NORETURN(this->m_stbyAdmObj, HA_AGENT_STNBYAdm());
		if (0 == this->m_stbyAdmObj) {
			HA_LG_ER("ha-class: failed to create the instance");
		} else {		
       		int res = this->m_stbyAdmObj->start(this); // This will start standby functionality. 
           	if (res < 0) {
           		// Failed to start
               	delete this->m_stbyAdmObj;
               	this->m_stbyAdmObj = 0;
        	} else {
				if (0 != m_globalInstance->waitOntask()) {
                    HA_LG_ER("%s(): timeout", __func__);
                } else {
                    HA_TRACE_1("%s() ----------------------------", __func__);
                    HA_TRACE_1("%s() AGENT is now passified by HA", __func__);
                    HA_TRACE_1("%s() ----------------------------", __func__);
                    rCode = ACS_APGCC_SUCCESS;
                } 
			}
		}
  	}

	HA_TRACE_LEAVE();
	return rCode;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::stopApp(void) 
{
	HA_TRACE_ENTER();

	ACE_Guard<ACE_Thread_Mutex> guard(this->m_admLock);
    this->stopActv();
    this->stopStndby();
    
	HA_TRACE_LEAVE();
	return ACS_APGCC_SUCCESS;
}
//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::stopActv(void) 
{
	HA_TRACE_ENTER();

	if (0 != m_actvAdmObj) {
        HA_TRACE("ha-class: Ordering Active App to terminate...");
        this->m_actvAdmObj->stop();
        
        HA_TRACE("ha-class: Waiting for Active App to terminate...");
		this->m_actvAdmObj->wait();
        
        HA_TRACE( "ha-class: Deleting Active App instance...");
		delete this->m_actvAdmObj;
		this->m_actvAdmObj = 0;
    }

	HA_TRACE_LEAVE();
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::stopStndby(void) 
{
	HA_TRACE_ENTER();

	if (0 != m_stbyAdmObj) {
        HA_TRACE("ha-class: Ordering Standby App to terminate...");
        this->m_stbyAdmObj->stop();
        
        HA_TRACE("ha-class: Waiting for Standby App to terminate...");
		this->m_stbyAdmObj->wait();
        
        HA_TRACE( "ha-class: Deleting Standby App instance...");
		delete this->m_stbyAdmObj;
		this->m_stbyAdmObj = 0;
    }

	HA_TRACE_LEAVE();
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType agentHAClass::performComponentHealthCheck(void) 
{
	HA_TRACE_ENTER();

	HA_TRACE_2("ha-class: health-check callback received");

	HA_TRACE_LEAVE();
	return ACS_APGCC_SUCCESS;
}
//-----------------------------------------------------------------------------

