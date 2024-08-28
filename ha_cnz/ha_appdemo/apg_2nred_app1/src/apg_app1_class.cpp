#include "apg_app1_class.h"

HAClass::HAClass(const char* daemon_name, const char* user):ACS_APGCC_ApplicationManager(daemon_name, user){
	log.Open("APPNAME");
	m_myClassObj=0;
}

HAClass::~HAClass(){
	// to be sure.
	this->passifyApp(); 
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
	return this->passifyApp();
}


ACS_APGCC_ReturnType HAClass::performComponentTerminateJobs(void){

	return this->passifyApp();
}

ACS_APGCC_ReturnType HAClass::performComponentRemoveJobs(void){

	return this->passifyApp();
}

ACS_APGCC_ReturnType HAClass::performApplicationShutdownJobs(){

	return this->passifyApp();	
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState) {

	(void) previousHAState;
	return this->passifyApp();
}


ACS_APGCC_ReturnType HAClass::activateApp() {

        ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;

        if ( 0 != this->m_myClassObj) {
		log.Write("ha-class: application is already active", LOG_LEVEL_INFO);
		rCode = ACS_APGCC_SUCCESS;
                
	} else {	        
        	ACE_NEW_NORETURN(this->m_myClassObj, myClass());
		if (0 == this->m_myClassObj) {
			syslog(LOG_ERR, "ha-class: failed to create the instance");
			log.Write("ha-class: failed to create the instance", LOG_LEVEL_ERROR);
		} else {		

        	  	int res = this->m_myClassObj->start(this); // This will start active functionality. Will not return until myCLass is running
                	if (res < 0) {
                        	// Failed to start
                        	delete this->m_myClassObj;
                        	this->m_myClassObj = 0;
                	} else {
                        	log.Write("ha-class: application is now activated by HA", LOG_LEVEL_INFO);
				rCode = ACS_APGCC_SUCCESS;
			}
		}
        }
        return rCode;
}


ACS_APGCC_ReturnType HAClass::passifyApp() {

	ACS_APGCC_ReturnType result = ACS_APGCC_FAILURE;

	if (0 == this->m_myClassObj) {
		log.Write("ha-class: application is already passive", LOG_LEVEL_INFO);
		result = ACS_APGCC_SUCCESS;
	} else {
		// Passify functionality
		log.Write("ha-class: Ordering App to be passive ...", LOG_LEVEL_INFO);
		this->m_myClassObj->stop();

		log.Write("ha-class: Waiting for App to become passive...", LOG_LEVEL_INFO);
		this->m_myClassObj->wait();

		log.Write( "ha-class: Deleting App instance...", LOG_LEVEL_INFO);

		delete this->m_myClassObj;
		this->m_myClassObj = 0;

		log.Write("ha-class: App is now passivated by HA", LOG_LEVEL_INFO);
		result = ACS_APGCC_SUCCESS;
	}
	return result;
}


ACS_APGCC_ReturnType HAClass::performComponentHealthCheck(void) {

	/* Application has received health check callback from AMF. Check the
	 * sanity of the application and reply to AMF that you are ok.
	 *  
	 */

	return ACS_APGCC_SUCCESS;
}

