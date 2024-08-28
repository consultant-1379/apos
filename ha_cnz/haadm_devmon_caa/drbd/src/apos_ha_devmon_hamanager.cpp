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
 * @file apos_ha_devmon_hamanger.cpp
 *
 * @brief
 * 
 * This class handles all HA callback functions
 *
 * @author Malangsha Shaik (xmalsha)
 *****************************************************************************/

#include "apos_ha_devmon_hamanager.h"

//-----------------------------------------------------------------------------

devmonHAClass::devmonHAClass(const char* daemon_name, const char* user):APOS_HA_Devmon_AmfClass(daemon_name, user)
{
	HA_TRACE_ENTER();
	m_admObj=0;
	HA_TRACE_LEAVE();
}

//-----------------------------------------------------------------------------

devmonHAClass::~devmonHAClass()
{
	HA_TRACE_ENTER();
	// to be sure.
	this->passifyApp(); 
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->activateApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->passifyApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->passifyApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performComponentTerminateJobs(void)
{
	HA_TRACE_ENTER();
	return this->passifyApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performComponentRemoveJobs(void)
{
	HA_TRACE_ENTER();
	return this->passifyApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performApplicationShutdownJobs()
{
	HA_TRACE_ENTER();
	return this->passifyApp();	
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState) 
{
	HA_TRACE_ENTER();
	(void) previousHAState;
	return this->passifyApp();
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::activateApp() 
{
	HA_TRACE_ENTER();
	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	ACE_Guard<ACE_Thread_Mutex> guard(this->m_admLock);

   	if ( 0 != this->m_admObj) {
		HA_TRACE("ha-class: application is already active");
		rCode = ACS_APGCC_SUCCESS;
	}else {	        
		ACE_NEW_NORETURN(this->m_admObj, HA_DEVMON_Adm());
		if (0 == this->m_admObj) {
			HA_LG_ER("ha-class: failed to create the instance");
		}else {		
       		int res = this->m_admObj->start(this); // This will start active functionality. 
           	if (res < 0) {
           		// Failed to start
               	delete this->m_admObj;
               	this->m_admObj = 0;
        	}else {
           		HA_TRACE_1("%s() ----------------------------", __func__);
           		HA_TRACE_1("%s() DEVMON is now activated by HA", __func__);
           		HA_TRACE_1("%s() ----------------------------", __func__);
				rCode = ACS_APGCC_SUCCESS;
			}
		}
  	}

	HA_TRACE_LEAVE();
    return rCode;
}

//-----------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::passifyApp() 
{
	HA_TRACE_ENTER();
	ACS_APGCC_ReturnType result = ACS_APGCC_FAILURE;
	ACE_Guard<ACE_Thread_Mutex> guard(this->m_admLock);

	if (0 == this->m_admObj) {
		result = ACS_APGCC_SUCCESS;
	}else {
		HA_TRACE("ha-class: Ordering Active App to terminate...");
		this->m_admObj->stop();

		HA_TRACE("ha-class: Waiting for Active App to terminate...");
		this->m_admObj->wait();

		HA_TRACE( "ha-class: Deleting Active App instance...");
		delete this->m_admObj;
		this->m_admObj = 0;
		HA_TRACE("ha-class: App is now passivated by HA"); 
		result = ACS_APGCC_SUCCESS;
	}
	
	HA_TRACE_LEAVE();
	return result;
}

//-------------------------------------------------------------------------

ACS_APGCC_ReturnType devmonHAClass::performComponentHealthCheck(void) 
{
	HA_TRACE_ENTER();

	HA_TRACE("ha-class: health-check callback received");

	HA_TRACE_LEAVE();
	return ACS_APGCC_SUCCESS;
}
//-----------------------------------------------------------------------------
