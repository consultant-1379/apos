#include "apos_ha_fagent_class.h"

HAClass::HAClass(const char* daemon_name):APOS_HA_DevMon_AmfClass(daemon_name){
	passiveToActive=0;
	m_admClassObj=0;
}

HAClass::~HAClass(){
	// to be sure.
	this->shutdownApp(); 
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState){

	(void) previousHAState;
	return this->activateApp();
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState) {

	(void) previousHAState;
	return this->passifyApp();
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState) {

	(void) previousHAState;
	return this->shutdownApp();
}

ACS_APGCC_ReturnType HAClass::performComponentHealthCheck(void)
{

        /* Application has received health check callback from AMF. Check the
         * sanity of the application and reply to AMF that you are ok.
         */
        syslog(LOG_INFO, "My Application Component received healthcheck query!!!");

        return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performComponentTerminateJobs(void){

	return this->shutdownApp();
}

ACS_APGCC_ReturnType HAClass::performComponentRemoveJobs(void){

	return this->shutdownApp();
}

ACS_APGCC_ReturnType HAClass::performApplicationShutdownJobs(){

	return this->shutdownApp();	
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState) {

	(void) previousHAState;
	return this->shutdownApp();
}


ACS_APGCC_ReturnType HAClass::activateApp() {

        ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
        if ( 0 != this->m_admClassObj) {
		if (passiveToActive){
			syslog(LOG_INFO, "ha-class: passive->active transition. stop passive work before becomming active");
			this->m_admClassObj->passiveToActive=1;
			passiveToActive=0;
		} 
		else {
			syslog(LOG_INFO, "ha-class: application is already active");
			rCode = ACS_APGCC_SUCCESS;
		}
                
	} else {	        
        	ACE_NEW_NORETURN(this->m_admClassObj, admClass());
		if (0 == this->m_admClassObj) {
			syslog(LOG_ERR, "ha-class: failed to create the instance");
		}
	}

	if ( 0 != this->m_admClassObj) {
     		int res = this->m_admClassObj->start(this); // This will start active functionality. Will not return until myCLass is running
	       	if (res < 0) {
	       		// Failed to start
	               	delete this->m_admClassObj;
	               	this->m_admClassObj = 0;
	        } else {
	                syslog(LOG_INFO, "ha-class: application is now activated by HA");
			rCode = ACS_APGCC_SUCCESS;
		}
	}
        return rCode;
}

ACS_APGCC_ReturnType HAClass::shutdownApp(){

	if ( 0 != this->m_admClassObj){
		syslog(LOG_INFO, "ha-class: Ordering App to shutdown");
		this->m_admClassObj->stop(); // This will initiate the application shutdown and will not return until application is stopped completely.

		syslog(LOG_INFO, "ha-class: Waiting for App to shutdown...");
		this->m_admClassObj->wait();

		syslog(LOG_INFO, "ha-class: Deleting App instance...");
		delete this->m_admClassObj;
		this->m_admClassObj=0;
	}
	else
		syslog(LOG_INFO, "ha-class: shutdownApp already done");
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType HAClass::passifyApp() {

	ACS_APGCC_ReturnType rCode = ACS_APGCC_SUCCESS;
	passiveToActive=1;

	return rCode;
}



