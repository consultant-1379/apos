#include "apg_app2_class.h"

HAClass::HAClass(const char* daemon_name, const char* user):ACS_APGCC_ApplicationManager(daemon_name, user){
	passiveToActive=0;
	log.Open("APPNAME");
	m_myClassObj=0;
}

HAClass::~HAClass(){
	// to be sure.
	this->shutdownApp(); 
	log.Close();
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
        if ( 0 != this->m_myClassObj) {
		if (passiveToActive){
			log.Write("ha-class: passive->active transition. stop passive work before becomming active", LOG_LEVEL_INFO);
			this->m_myClassObj->stop();
			this->m_myClassObj->wait();
			passiveToActive=0;
		} 
		else {
			log.Write("ha-class: application is already active", LOG_LEVEL_INFO);
			rCode = ACS_APGCC_SUCCESS;
		}
                
	} else {	        
        	ACE_NEW_NORETURN(this->m_myClassObj, myClass());
		if (0 == this->m_myClassObj) {
			log.Write("ha-class: failed to create the instance", LOG_LEVEL_ERROR);		
			syslog(LOG_ERR, "ha-class: failed to create the instance");
		}
	}

	if ( 0 != this->m_myClassObj) {
     		int res = this->m_myClassObj->active(this); // This will start active functionality. Will not return until myCLass is running
	       	if (res < 0) {
	       		// Failed to start
	               	delete this->m_myClassObj;
	               	this->m_myClassObj = 0;
	        } else {
	                log.Write("ha-class: application is now activated by HA", LOG_LEVEL_INFO);
			rCode = ACS_APGCC_SUCCESS;
		}
	}
        return rCode;
}

ACS_APGCC_ReturnType HAClass::shutdownApp(){

	if ( 0 != this->m_myClassObj){
		log.Write("ha-class: Ordering App to shutdown", LOG_LEVEL_INFO);
		this->m_myClassObj->stop(); // This will initiate the application shutdown and will not return until application is stopped completely.

		log.Write("ha-class: Waiting for App to shutdown...", LOG_LEVEL_INFO);
		this->m_myClassObj->wait();

		log.Write( "ha-class: Deleting App instance...", LOG_LEVEL_INFO);
		delete this->m_myClassObj;
		this->m_myClassObj=0;
	}
	else
		log.Write("ha-class: shutdownApp already done", LOG_LEVEL_INFO);
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType HAClass::passifyApp() {

	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	passiveToActive=1;
	
	if (0 != this->m_myClassObj) {
		log.Write("ha-class: application is already passive", LOG_LEVEL_INFO);
		rCode = ACS_APGCC_SUCCESS;
	} else {
		ACE_NEW_NORETURN(this->m_myClassObj, myClass());
		if (0 == this->m_myClassObj) {
			syslog(LOG_ERR, "ha-class: failed to create the instance");
			log.Write("ha-class: failed to create the instance", LOG_LEVEL_ERROR);
		}
		else {
			int res = this->m_myClassObj->passive(this); // This will start passive functionality and will not return until myCLass is running
			if (res < 0) {
				// Failed to start
				delete this->m_myClassObj;
				this->m_myClassObj = 0;
			} else {
				log.Write("ha-class: App is now passivated by HA", LOG_LEVEL_INFO);
				rCode = ACS_APGCC_SUCCESS;
			}
		}	
	}
	return rCode;
}


ACS_APGCC_ReturnType HAClass::performComponentHealthCheck(void) {

	/* Application has received health check callback from AMF. Check the
	 * sanity of the application and reply to AMF that you are ok.
	 *  
	 */

	return ACS_APGCC_SUCCESS;
}

