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
 * @file apos_ha_devmon_amfclass.cpp
 *
 * @brief
 * 
 * The thread is run in svc().
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <sys/file.h>
#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/file.h>
#include <pwd.h>
#include <sys/stat.h>
#include <ace/OS_NS_poll.h>
#include <syslog.h>
#include "apos_ha_devmon_amfclass.h"

#define m_SET_AMF_VERSION(amfVersion) \
{ \
	amfVersion.releaseCode='B'; \
	amfVersion.majorVersion=0x01; \
	amfVersion.minorVersion=0x01 ; \
};


using namespace std;

static APOS_HA_Devmon_AmfClass* appMngrObj =NULL;

/*===================================================================
                        CLASS DECLARATION SECTION
===================================================================== */
/* ================================================================== */
/**
      @brief	The ACS_APGCC_AMFCallbacks class is the internal class, will be 
		used by ACS_APGCC_ApplicationManger common class. This class only 
		defines CoreMW static callbacks.	 
*/
/*=================================================================== */		

class ACS_APGCC_AMFCallbacks {
	
   private:
        
	static void coremw_csi_set_callback (
		SaInvocationT ,
		const SaNameT* ,
		SaAmfHAStateT  ,
		SaAmfCSIDescriptorT
	);
												
	static void coremw_csi_remove_callback(
		SaInvocationT,
		const SaNameT*,
		const SaNameT*,
		SaAmfCSIFlagsT
	);

	static void coremw_csi_terminate_callback(
		SaInvocationT,
		const SaNameT*
	);
													
	static void coremw_healthcheck_callback(
		SaInvocationT,
		const SaNameT*,
		SaAmfHealthcheckKeyT*
	);

   public:
		
	ACS_APGCC_AMFCallbacks() {};
	~ACS_APGCC_AMFCallbacks() {}; 
	/*=================================================================== */
	/**
	@brief	This routine initializes with AMF of CoreMW
	
	@param	APOS_HA_Devmon_AmfClass
			Application Manager Common Class Object.

	@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.
			
	@exception	None
	*/
	/*=================================================================== */
	ACS_APGCC_ReturnType safAMFInitialize ( APOS_HA_Devmon_AmfClass *);
		
};	
		

ACS_APGCC_ReturnType ACS_APGCC_AMFCallbacks::safAMFInitialize(APOS_HA_Devmon_AmfClass *obj){

	SaVersionT version;
	SaAmfCallbacksT callbacks;
	SaAisErrorT errorCode;
	
	/** Set AMF version here **/
	m_SET_AMF_VERSION(version);

	/* Initialize callback structure */
	memset(&callbacks, 0, sizeof(SaAmfCallbacksT) );
	
	/** Fill in the callback structure **/
	callbacks.saAmfCSISetCallback				=	ACS_APGCC_AMFCallbacks::coremw_csi_set_callback ;
	callbacks.saAmfCSIRemoveCallback			=	ACS_APGCC_AMFCallbacks::coremw_csi_remove_callback ;
	callbacks.saAmfHealthcheckCallback			=	ACS_APGCC_AMFCallbacks::coremw_healthcheck_callback ;
	callbacks.saAmfComponentTerminateCallback	=	ACS_APGCC_AMFCallbacks::coremw_csi_terminate_callback ;
	
	/** Initalize application with CoreMW Framework **/
		
	errorCode = saAmfInitialize(&obj->amfHandle,&callbacks,&version);
								
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "ACS_APGCC_AMFCallbacks:safAMFInitialize FAILED with ERROR CODE: %d", errorCode);
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO, "ACS_APGCC_AMFCallbacks:amfHandle:[%x]", (unsigned int)obj->amfHandle);
		
	appMngrObj = obj;    /* Assign object to use in callbacks */
		
	return ACS_APGCC_SUCCESS;

} /* end safAMFInitialize */

/*=================================================================== 
   ROUTINE: coremw_csi_set_callback
=================================================================== */
void ACS_APGCC_AMFCallbacks::coremw_csi_set_callback (	SaInvocationT p_Inv,
                                                        const SaNameT *p_compName,
                                                        SaAmfHAStateT p_HAState,
                                                        SaAmfCSIDescriptorT p_csiDesc )
{
	ACS_APGCC_ErrorT errorCode = ACS_APGCC_SUCCESS;
	SaAisErrorT errCode ;
	SaAisErrorT error = SA_AIS_OK;
	ACS_APGCC_AMF_HA_StateT previousHAState= ACS_APGCC_AMF_HA_UNDEFINED;

	/* To surpress warnings */
	(void)p_compName;
	(void)p_csiDesc;

	syslog(LOG_INFO, "ACS_APGCC_AMFCallbacks::coremw_csi_set_callback: ha_state[%d]",p_HAState);
		
        /** Assign current HAState to previousHAState**/
	previousHAState = appMngrObj->HAState;

        /** Store the received HAState **/
	appMngrObj->HAState = (ACS_APGCC_AMF_HA_StateT)p_HAState;

	if (p_HAState == SA_AMF_HA_ACTIVE) {
		errorCode = appMngrObj->performStateTransitionToActiveJobs(previousHAState) ;
	}								
					
	if (p_HAState == SA_AMF_HA_STANDBY) {
		errorCode = appMngrObj->performStateTransitionToPassiveJobs(previousHAState) ;
	}
		
	if (p_HAState == SA_AMF_HA_QUIESCED) {
		errorCode = appMngrObj->performStateTransitionToQuiescedJobs(previousHAState);
	}
		
	if (p_HAState == SA_AMF_HA_QUIESCING) {
		errCode =  saAmfResponse(appMngrObj->amfHandle,p_Inv,error);
		errorCode = appMngrObj->performStateTransitionToQueisingJobs(previousHAState);

		if (errorCode!=ACS_APGCC_SUCCESS)
			error=SA_AIS_ERR_FAILED_OPERATION;
		errCode =  saAmfCSIQuiescingComplete (appMngrObj->amfHandle,p_Inv,error);
		
		if ( SA_AIS_OK != errCode ){ 
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coremw_csi_set_callback:saAmfCSIQuiescingComplete FAILED");
			appMngrObj->HAState = previousHAState;
		}
		/* All success - return from here*/
		return;
	}
	if (errorCode!=ACS_APGCC_SUCCESS) {
		error=SA_AIS_ERR_FAILED_OPERATION;
	}
	errCode =  saAmfResponse(appMngrObj->amfHandle,p_Inv,error);
			
	if ( SA_AIS_OK != errCode ) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coremw_csi_set_callback:saAmfResponse FAILED");
		appMngrObj->HAState = previousHAState;
		return ;
	}
		
		
}

/*=================================================================== 
   ROUTINE: coremw_csi_remove_callback
=================================================================== */

void ACS_APGCC_AMFCallbacks::coremw_csi_remove_callback (SaInvocationT p_Inv,
							const SaNameT *p_compName, 
							const SaNameT *p_csiName,
							SaAmfCSIFlagsT p_Flag)
{
																
	ACS_APGCC_ErrorT errorCode ;
	SaAisErrorT errCode ;
	SaAisErrorT error = SA_AIS_OK;

	/* To surpress warnings */
	(void)p_compName;
	(void)p_csiName;
	(void)p_Flag;
		
	syslog(LOG_INFO, "ACS_APGCC_AMFCallbacks::coremw_csi_remove_callback:" );

	/** Set our HAState to undefined now **/
	appMngrObj->HAState = ACS_APGCC_AMF_HA_UNDEFINED ;
	
	/** Call remove method now **/	
	errorCode = appMngrObj->performComponentRemoveJobs ( );		
	if ( ACS_APGCC_SUCCESS != errorCode) {	
		error = SA_AIS_ERR_FAILED_OPERATION;
	}
		
	errCode =  saAmfResponse(appMngrObj->amfHandle,p_Inv,error);
	if (SA_AIS_OK != errCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coremw_csi_remove_callback:saAmfResponse FAILED");
		return;
	}			
} 

/*=================================================================== 
   ROUTINE: coremw_csi_terminate_callback
=================================================================== */

void ACS_APGCC_AMFCallbacks::coremw_csi_terminate_callback( SaInvocationT p_Inv,
							const SaNameT *p_compName)
{  
																	
	ACS_APGCC_ErrorT errorCode ;
	SaAisErrorT errCode ;
	SaAisErrorT error = SA_AIS_OK;

	(void)p_compName;
		
	/** Set our HAState to undefined now **/
	appMngrObj->HAState = ACS_APGCC_AMF_HA_UNDEFINED ;		
	
	/** Call terminate method now **/	
	errorCode =	appMngrObj->performComponentTerminateJobs( );		
	if (ACS_APGCC_SUCCESS != errorCode) {
		error = SA_AIS_ERR_FAILED_OPERATION;
	}
		
	errCode =  saAmfResponse(appMngrObj->amfHandle,p_Inv,error);
	if (SA_AIS_OK != errCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coremw_csi_terminate_callback:saAmfResponse FAILED");
		return ;
	}	
	/* set the termination flag to true to terminate the daemon */
	appMngrObj->termAppEventReceived = TRUE;
		
}	


/*=================================================================== 
   ROUTINE: coremw_healthcheck_callback
=================================================================== */

void ACS_APGCC_AMFCallbacks::coremw_healthcheck_callback(SaInvocationT p_Inv,
								const SaNameT *p_compName,
								SaAmfHealthcheckKeyT *p_hCheckKey)
{
																
	ACS_APGCC_ErrorT errorCode ;
	SaAisErrorT errCode ;
	SaAisErrorT error = SA_AIS_OK;
	
	(void)p_compName;
		
	/** Do healthcheck now **/
	
	if ( strcmp( (char*)p_hCheckKey->key, (char*)appMngrObj->hCheckKey->key) != 0 ){
		syslog(LOG_ERR, "Healtch Check Key Mismatch Received");
		return;	
	}	
		
	errorCode = appMngrObj->performComponentHealthCheck ( );
		
	if (  ACS_APGCC_FAILURE != errorCode) {							
		errCode =  saAmfResponse(appMngrObj->amfHandle,p_Inv,error);
		if (SA_AIS_OK != errCode) {
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coremw_healthcheck_callback:saAmfResponse FAILED");
		}		
	}
}

/*=================================================================== 
			APOS_HA_Devmon_AmfClass CLASS IMPLEMENTATION
=================================================================== */

int APOS_HA_Devmon_AmfClass::shutdownPipeFd[2];
char APOS_HA_Devmon_AmfClass::__pidfile[PID_FILE_LEN];

/*=================================================================== 
   ROUTINE: APOS_HA_Devmon_AmfClass  - Constructor 
=================================================================== */		
APOS_HA_Devmon_AmfClass::APOS_HA_Devmon_AmfClass(const char* daemon_name,
	       						   const char* user_name): 
	/* call daemonize to make the application daemon */
	compName((const SaNameT&)""),
	amfHandle(0),
	SelObj(0),
	HAState(ACS_APGCC_AMF_HA_UNDEFINED),
	hCheckKey(NULL),
	termAppEventReceived(false),
	daemonName(daemon_name)
{
	daemonize(daemon_name, user_name);
}

/*=================================================================== 
   ROUTINE:  coreMWInitialize
=================================================================== */	

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::coreMWInitialize( )
{

	SaAisErrorT errorCode;
	SaAmfHealthcheckInvocationT hCheckInv;
	SaAmfRecommendedRecoveryT rRecovery;
	ACS_APGCC_AMFCallbacks obj;

	/* Register for shutdown signal handler */
	if ((signal(SIGUSR2, registerApplicationShutdownhandler)) == SIG_ERR) {
		syslog(LOG_ERR, "registerApplicationShutdownhandler FAILED");
		return ACS_APGCC_FAILURE;	
	}
				
	/* call AMF initialize */
	obj.safAMFInitialize( this );

	/** Call saAmfSelectionObjectGet to get the operating system handle. 
	* This handle will be used by applicatio to wait on the callbacks **/
	errorCode = saAmfSelectionObjectGet(this->amfHandle,&this->SelObj);
							
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfSelectionObjectGet FAILED");
		return ACS_APGCC_FAILURE;
	}
		
	/** Call saAmfCompNameGet to get the name of the component **/
	errorCode = saAmfComponentNameGet(this->amfHandle,&this->compName ) ;
					
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfCompNameGet FAILED");
		return ACS_APGCC_FAILURE;
	}
		

	/** Call saAmfComponentRegister to register with your component **/
	errorCode = saAmfComponentRegister(this->amfHandle,&this->compName,0);
										
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:componentRegister FAILED");
		return ACS_APGCC_FAILURE;
	}							
		
	/** Start the application healthcheck now **/
	
	hCheckInv   = SA_AMF_HEALTHCHECK_AMF_INVOKED;
	rRecovery   = SA_AMF_COMPONENT_RESTART;

	/* Form the unique health check key */
	this->hCheckKey = new ACS_APGCC_AMF_HealthCheckKeyT;
	int dlen = strlen(this->daemonName);
	memcpy(hCheckKey->key, this->daemonName, dlen);
	strcpy((char*)hCheckKey->key + dlen, "_hck");
	this->hCheckKey->keyLen = strlen((char*)hCheckKey->key) ;
	
	errorCode = saAmfHealthcheckStart(this->amfHandle,
					  &this->compName,
					  (SaAmfHealthcheckKeyT *)this->hCheckKey,
					  hCheckInv, 
					  rRecovery );
										
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:Application healthcheckStart FAILED");
		return ACS_APGCC_FAILURE;
	}							

	return ACS_APGCC_SUCCESS;
		
}

/*=================================================================== 
   ROUTINE:  getHAState
=================================================================== */	

ACS_APGCC_AMF_HA_StateT APOS_HA_Devmon_AmfClass::getHAState(void) const 
{

	return this->HAState;
}

/*=================================================================== 
   ROUTINE:  getSelObj
=================================================================== */

ACS_APGCC_SelObjT APOS_HA_Devmon_AmfClass::getSelObj(void) const 
{

	return this->SelObj;
}

/*=================================================================== 
   ROUTINE:  componentReportError
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::componentReportError(ACS_APGCC_AMF_RecommendedRecoveryT rRecovery) 
{ 
	SaAisErrorT errorCode;
	SaTimeT saTime = 0;
		
	errorCode = saAmfComponentErrorReport(this->amfHandle,
						&this->compName,
						saTime,
						(SaAmfRecommendedRecoveryT) rRecovery,
						SA_NTF_IDENTIFIER_UNUSED );
												
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfComponentErrorReport FAILED");
		return  ACS_APGCC_FAILURE ;
	}
		
	return ACS_APGCC_SUCCESS;
} 

/*=================================================================== 
   ROUTINE:  componentClearError
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::componentClearError( )
{

	SaAisErrorT errorCode;
	errorCode = saAmfComponentErrorClear(this->amfHandle,
						&this->compName,
						SA_NTF_IDENTIFIER_UNUSED );
												
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfComponentErrorClear FAILED");
		return ACS_APGCC_FAILURE ;
	}

	return ACS_APGCC_SUCCESS ;
}

/*=================================================================== 
   ROUTINE:  dispatch
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::dispatch(ACS_APGCC_AMF_DispatchFlagsT p_dFlag)
{ 

	SaAisErrorT errorCode;
		
	errorCode = saAmfDispatch(this->amfHandle,
				  (SaDispatchFlagsT)p_dFlag );
										
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfDispatch FAILEd");
		return ACS_APGCC_FAILURE ;
	}
		
	return ACS_APGCC_SUCCESS ;
}

/*=================================================================== 
   ROUTINE:  finalize
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::finalize( )
{

	SaAisErrorT errorCode;
	errorCode = saAmfHealthcheckStop( this->amfHandle,
					  &this->compName,
					  (SaAmfHealthcheckKeyT*) this->hCheckKey);

	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfHealthcheckStop FAILED");
		return ACS_APGCC_FAILURE ;
	}

	/* free the allocated memory for health checck key */
	if(this->hCheckKey)
	{
		delete this->hCheckKey;
		this->hCheckKey = 0;
	}
	
	errorCode = saAmfComponentUnregister(this->amfHandle,
						&this->compName,
						0) ;
																
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfComponentUnregister FAILED");
		return ACS_APGCC_FAILURE ;
	}
	
	errorCode =  saAmfFinalize(this->amfHandle);
		
	if (SA_AIS_OK != errorCode) {							
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfFinalize FAILED");
		return ACS_APGCC_FAILURE ;
	}
		
	return ACS_APGCC_SUCCESS;

}

/*===================================================================
	ROUTINE:  finalize
=================================================================== */
ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::AmfFinalize()
{

	SaAisErrorT errorCode;

	/* free the allocated memory for health checck key */
	if(this->hCheckKey)
	{
		delete this->hCheckKey;
		this->hCheckKey = 0;
	}
	errorCode =  saAmfFinalize( this->amfHandle );
		
	if (SA_AIS_OK != errorCode) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:saAmfFinalize FAILED");
		return ACS_APGCC_FAILURE ;
	}

	return ACS_APGCC_SUCCESS;

}

/*=================================================================== 
   ROUTINE:  performStateTransitionToActiveJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performStateTransitionToActiveJobs (ACS_APGCC_AMF_HA_StateT prevousHaState)
{ 

	(void)prevousHaState;
	return ACS_APGCC_SUCCESS;
}

/*=================================================================== 
   ROUTINE:  performStateTransitionToPassiveJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performStateTransitionToPassiveJobs (ACS_APGCC_AMF_HA_StateT prevousHaState) 
{
	(void)prevousHaState;
	return ACS_APGCC_SUCCESS;
}

/*=================================================================== 
   ROUTINE:  performStateTransitionToQueisingJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT prevousHaState)
{
	
	(void)prevousHaState;
	return ACS_APGCC_SUCCESS;
}

/*===================================================================
   ROUTINE:  performStateTransitionToQuiesedJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT prevousHaState)
{

	(void)prevousHaState;
	return ACS_APGCC_SUCCESS;
}

/*=================================================================== 
   ROUTINE:  performComponentTerminateJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performComponentTerminateJobs( )
{

	return ACS_APGCC_SUCCESS;
}

/*=================================================================== 
   ROUTINE:  performComponentRemoveJobs
=================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performComponentRemoveJobs( )
{

	return ACS_APGCC_SUCCESS;
}

/*===================================================================
  ROUTINE: activate
===================================================================== */

ACS_APGCC_HA_ReturnType APOS_HA_Devmon_AmfClass::activate()
{

	struct pollfd fds[2];
	nfds_t nfds = 2;
	ACE_INT32 retval;
	ACS_APGCC_BOOL Is_haStarted = TRUE;

	/* Initialize CoreMW Framework */
	if (coreMWInitialize() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:coreMWInitialize FAILED");
		return ACS_APGCC_HA_FAILURE;
	}


	/* create the pipe for shutdown handler */
	if ( (pipe(shutdownPipeFd)) < 0) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:pipe creation FAILED");
		return ACS_APGCC_HA_FAILURE;
	}
	
	if ( (fcntl(shutdownPipeFd[0], F_SETFL, O_NONBLOCK)) < 0) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass: pipe fcntl on readn");
		return ACS_APGCC_HA_FAILURE;
	}

	if ( (fcntl(shutdownPipeFd[1], F_SETFL, O_NONBLOCK)) < 0) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass: pipe fcntl on writen");
		return ACS_APGCC_HA_FAILURE;
	}

	fds[FD_AMF].fd = getSelObj();
	fds[FD_AMF].events = POLLIN;

	fds[FD_USR2].fd = shutdownPipeFd[0];
	fds[FD_USR2].events = POLLIN;

	while (Is_haStarted){
		retval = ACE_OS::poll(fds, nfds, 0) ;
		if(retval == -1){
			if (errno == EINTR){
				continue;
			}
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:poll FAILED [%s]",strerror(errno)); 
			Is_haStarted = FALSE;
			continue;
		}
		
		if(retval == 0){
			/*  timeout happens on select*/
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:timeout happend on poll");
			continue;
		}
		
		if ( fds[FD_AMF].revents & POLLIN){
			if (dispatch(ACS_APGCC_AMF_DISPATCH_ALL) != ACS_APGCC_SUCCESS){
				syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:dispatch FAILED");
				Is_haStarted = FALSE;
				continue;
			}
		
			if(this->termAppEventReceived == TRUE){
				Is_haStarted = FALSE;
				continue;
			}
		}
		if (fds[FD_USR2].revents & POLLIN){
			if (performApplicationShutdownJobs() != ACS_APGCC_SUCCESS){
				syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:performApplicationShutdownJobs FAILED");
			}
			Is_haStarted = FALSE;
		}

	} 

	/* close pipe fds first*/
	close(shutdownPipeFd[0]);
	close(shutdownPipeFd[1]);

	if (this->termAppEventReceived == TRUE){
		if (AmfFinalize() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:AmfFinalize FAILED");
			return ACS_APGCC_HA_FAILURE_CLOSE;
		}
	}
	else {
		if (finalize() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass:AmfFinalize FAILED");
			return ACS_APGCC_HA_FAILURE_CLOSE;
		}
	}

	return ACS_APGCC_HA_SUCCESS;
}


/*===================================================================
   ROUTINE:performApplicationShutdownJobs

===================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::performApplicationShutdownJobs()
{

	return ACS_APGCC_SUCCESS;
}

/*===================================================================
   ROUTINE: registerApplicationShutdownhandler
===================================================================== */
void APOS_HA_Devmon_AmfClass::registerApplicationShutdownhandler(int sig)
{
	(void)sig;

	syslog(LOG_INFO, "APOS_HA_Devmon_AmfClass::Shutting down the application.( USR2)");
	appMngrObj->performApplicationShutdownJobs();

}

/*===================================================================
   ROUTINE: daemonize
===================================================================== */

void APOS_HA_Devmon_AmfClass::daemonize(const char* daemon_name, const char* userName)
{

	pid_t pid, sid;

/* Already a daemon */
	if (getppid() == 1){
	   	return;
	}

	/* Drop user if there is one, and we were run as root */
	if ( getuid() == 0 || geteuid() == 0 ) {
		struct passwd *pw = getpwnam(userName);
		if ( pw ) {
			syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::Setting user to [%s]",userName );
			setuid( pw->pw_uid );
		}
	}

	/* Fork off the parent process */
	pid = fork();
	if (pid < 0) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::Fork daemon failed, pid=%d (%s)", pid, strerror(errno));
		exit(EXIT_FAILURE);
	}

	/* If we got a good PID, then we can exit the parent process */
	if (pid > 0)  {
	exit(EXIT_SUCCESS);
	}

	/* Create a new SID for the child process */
	sid = setsid();
	if (sid < 0) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::Create new session failed, sid=%d (%s)", sid, strerror(errno));
		exit(EXIT_FAILURE);
	}

	/* Redirect standard files to /dev/null */
	if (freopen("/dev/null", "r", stdin) == NULL){
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::freopen stdin failed - %s", strerror(errno));
	}
	if (freopen("/dev/null", "w", stdout) == NULL) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::freopen stdout failed - %s", strerror(errno));
	}
	if (freopen("/dev/null", "w", stderr) == NULL) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::freopen stderr failed - %s", strerror(errno));
	}

	/* Change the file mode mask to 0644 */
	umask(022);

	/*
	* Change the current working directory.  This prevents the current
	* directory from being locked; hence not being able to remove it.
	*/
	if (chdir("/") < 0) {
	syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::unable to change directory, dir=%s (%s)", "/", strerror(errno));
	exit(EXIT_FAILURE);
	}
	

	snprintf(__pidfile, sizeof(__pidfile),  PIDDIR"/%s.pid", daemon_name);
	/* Create the process PID file */
	if (__create_pidfile(__pidfile) != ACS_APGCC_SUCCESS){
	exit(EXIT_FAILURE);
	}
	/* Cancel certain signals */
	signal(SIGCHLD, SIG_DFL);       /* A child process dies */
	signal(SIGTSTP, SIG_IGN);       /* Various TTY signals */
	signal(SIGTTOU, SIG_IGN);
	signal(SIGTTIN, SIG_IGN);
	signal(SIGHUP,  SIG_DFL);        /* Ignore hangup signal */
	signal(SIGTERM, SIG_DFL);       /* Die on SIGTERM */
}


/*===================================================================
   ROUTINE: __create_pidfile
===================================================================== */

ACS_APGCC_ReturnType APOS_HA_Devmon_AmfClass::__create_pidfile(const char* pidfile)
{

	FILE *file = NULL;
	int fd, pid;

	/* open the file and associate a stream with it */
	if ( ((fd = open(pidfile, O_RDWR|O_CREAT, 0644)) == -1)|| ((file = fdopen(fd, "r+")) == NULL) ) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::Open failed, pidfile:[%s], err:[%s]", pidfile, strerror(errno));
		return ACS_APGCC_FAILURE;
	} 

	/* Lock the file */
	if (flock(fd, LOCK_EX|LOCK_NB) == -1) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::flock failed, pidfile:[%s], err:[%s]", pidfile, strerror(errno));
		fclose(file);
		return ACS_APGCC_FAILURE;
	}

	pid = getpid();
	if (!fprintf(file,"%d\n", pid)) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::fprintf failed, pidfile:[%s], err:[%s]", pidfile, strerror(errno));
		fclose(file);
		return ACS_APGCC_FAILURE;
	}
	fflush(file);

	if (flock(fd, LOCK_UN) == -1) {
		syslog(LOG_ERR, "APOS_HA_Devmon_AmfClass::flock failed, pidfile:[%s], err:[%s]", pidfile, strerror(errno));
		fclose(file);
		return ACS_APGCC_FAILURE;
	}
	fclose(file);

	return ACS_APGCC_SUCCESS;

}

