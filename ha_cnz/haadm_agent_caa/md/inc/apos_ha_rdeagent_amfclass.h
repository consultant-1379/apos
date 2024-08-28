/*=================================================================== 

   @file   apos_ha_rdeagent_amfclass.h

   @brief Header file for APG Common Class API to Integrate with CoreMW.

          This module contains all the declarations useful to
          ApplicationManager class.
   @version 1.0.0


   HISTORY
   -

   PR           DATE      INITIALS    DESCRIPTION
   -----------------------------------------------------------
   N/A       10/11/2010     XMALSHA       Initial Release
==================================================================== */

/*=====================================================================
                          DIRECTIVE DECLARATION SECTION
==================================================================== */

#ifndef APOS_HA_RDEAGENT_AMFCLASS_H_
#define APOS_HA_RDEAGENT_AMFCLASS_H_

/*====================================================================
                        INCLUDE DECLARATION SECTION
==================================================================== */

#include "ACS_APGCC_AmfTypes.h"
#include "saAmf.h"
#include "saNtf.h"
#include "string.h"

/*===================================================================
                        DIRECTIVE DECLARATION SECTION
===================================================================== */

#define PIDDIR "/var/run/apg"
#define PID_FILE_LEN    50

/*===================================================================
                        CLASS DECLARATION SECTION
===================================================================== */

/* ================================================================== */
/**
      @brief	The apos_ha_rdeagent_amfclass class provides the interfaces to the 
		 APG aplications to integrate with Availability Management Framework of CoreMW.
*/
/*=================================================================== */

class APOS_HA_RdeAgent_AmfClass {

	/*   Friend Class declaration */
	friend class ACS_APGCC_AMFCallbacks;
	
	/*=====================================================================
	                        PRIVATE DECLARATION SECTION
	==================================================================== */

private:

	/*===================================================================
	                        PRIVATE ATTRIBUTE DECLARATION
	==================================================================== */
		SaNameT compName;
		SaAmfHandleT amfHandle ;
		ACS_APGCC_SelObjT SelObj;
		ACS_APGCC_AMF_HA_StateT HAState ;
		ACS_APGCC_AMF_HealthCheckKeyT *hCheckKey;
		ACS_APGCC_BOOL termAppEventReceived;
		const char* daemonName;
		static char __pidfile[PID_FILE_LEN];
		void daemonize(const char* daemon_name, const char* userName);
		ACS_APGCC_ReturnType __create_pidfile(const char* __pidfile); 

		static int shutdownPipeFd[2];

		/* FD SET*/
		enum {
			FD_AMF = 0,
			FD_USR2= 1
		};

	/*=====================================================================
	                        PROTECTED DECLARATION SECTION
	==================================================================== */
		
protected:
	
	/*=====================================================================
	                       PUBLIC DECLARATION SECTION
	==================================================================== */

public:

	
	/*=====================================================================
                        CLASS CONSTRUCTOR
	==================================================================== */

	/*=================================================================== */
	/**
		@brief	Constructor gets called when application creates the object of this class
	
		@par	None

		@pre	None

		@pre	None
	
		@param	None

		@return	None

		@exception	None
	*/
	/*=================================================================== */
		APOS_HA_RdeAgent_AmfClass(){};
	/*=================================================================== */
		APOS_HA_RdeAgent_AmfClass( const char* daemon_name, 
					      const char* userName=const_cast<char *>("root"));

	/*=================================================================== */
	/**
	 	@brief  Constructor gets called when application creates the object of this class

		@par    None

		@pre    None

		@param  daemon_name

		@param  user_name

		@return None

		@exception      None

	*/
	/*=================================================================== 

                        CLASS DESTRUCTOR
	=================================================================== */
	/*=================================================================== */
	/**
		@brief	Destructor
	
		@par	None

		@pre	None

		@pre	None
	
		@param	None

		@return	None

		@exception	None
	*/
	/*=================================================================== */	
			virtual ~APOS_HA_RdeAgent_AmfClass() { };
	/*=================================================================== */
	/**
		@brief	This routine performs the steps required for the applications to register with coremw
	
		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_HealthCheckKeyT
			Health Check key of the applications. This key shall be used in healthcheck callback.

		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.
				
		@exception	None
	*/
	/*=================================================================== */
			ACS_APGCC_ReturnType coreMWInitialize( ); // IN
	/*=================================================================== */
	/**
		@brief	This routine returns the current HA State of the calling application.
	
		@par	None

		@pre	None

		@pre	None
	
		@param	None

		@return	ACS_APGCC_AMF_HA_StateT
			Following states are returned.
			ACS_APGCC_AMF_HA_UNDEFINED 	: This State shall be returned when application calls 
							  this method before initialize and after finalize
			ACS_APGCC_AMF_HA_ACTIVE 	: This State shall be returned If the application is ACTIVE
			ACS_APGCC_AMF_HA_STANDBY	: This State shall be returned If the application is STANDBY
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_AMF_HA_StateT getHAState (void) const ;
	/*=================================================================== */
	/**
		@brief	This routine returns the SelectionObject Handle which application can use to receive 
			the callbacks from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	None

		@return	ACS_APGCC_SelObjT
			Selection Object handle. 
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_SelObjT getSelObj(void) const;
	/*=================================================================== */
	/**
		@brief	This routine is used by the application when it need to report error to CoreMW 
			to take some action on self. 

		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_RecommendedRecoveryT
			For the possible recommended recovery values, look at ACS_APGCC_AmfTypes.h

		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_ReturnType componentReportError ( ACS_APGCC_AMF_RecommendedRecoveryT );
	/*=================================================================== */
	/**
		@brief	This routine is used by the application when it needs to clear error reported 

		@par	None

		@pre	None

		@pre	None
	
		@param	None
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_ReturnType componentClearError ( void );
	/*=================================================================== */
	/**
		@brief	This routine is used by the application when it needs to dispatch the callbacks 
			received from the CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_DispatchFlagsT
			This Flag can be one of following:
			ACS_APGCC_AMF_DISPATCH_ONE : Is used if application decided to dispatch only one callback
			ACS_APGCC_AMF_DISPATCH_ALL : Is used if application decided to dispatch all the callbacks 
						     pending on the handle.	
			ACS_APGCC_AMF_DISPATCH_BLOCKING : Is used if application decided to wait on the callback handle.
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_ReturnType dispatch( ACS_APGCC_AMF_DispatchFlagsT ); // IN
	/*=================================================================== */
	/**
		@brief	This routine is used by the application when it needs to release coreMw registration. 

		@par	None

		@pre	None

		@pre	None
	
		@param	None
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */		
		ACS_APGCC_ReturnType finalize ( void );
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives HAState as ACTIVE from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_HA_StateT
			HAState here is the previous State of the application. This state shall be assigned to 
			"ACS_APGCC_AMF_HA_UNDEFINED" when application registers with the CoreMW for the first time.
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		ACS_APGCC_ReturnType AmfFinalize(void);
	/*=================================================================== */
	/**	@brief  This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives HAState as ACTIVE from CoreMW

		@par    None
	
		@pre    None

		@pre    None

		@param  ACS_APGCC_AMF_HA_StateT
			HAState here is the previous State of the application. This state shall be assigned to
			"ACS_APGCC_AMF_HA_UNDEFINED" when application registers with the CoreMW for the first time.

		@return ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.

		@exception      None
	*/
	/*=================================================================== */
		virtual ACS_APGCC_ReturnType performStateTransitionToActiveJobs   (ACS_APGCC_AMF_HA_StateT  ); //OUT
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives HAState as STANDBY from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_HA_StateT
			HAState here is the previous State of the application. 
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		virtual ACS_APGCC_ReturnType performStateTransitionToPassiveJobs  (ACS_APGCC_AMF_HA_StateT  ) ; // OUT
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives HAState as QUEISING from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	ACS_APGCC_AMF_HA_StateT
			HAState here is the previous State of the application. 
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		virtual ACS_APGCC_ReturnType performStateTransitionToQueisingJobs (ACS_APGCC_AMF_HA_StateT  ); // OUT
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives Health Check callback from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	None
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */
		virtual ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT);
	/*=================================================================== */
	/**
		@brief  This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives Health Check callback from CoreMW

		@par    None
	
		@pre    None

		@pre    None

		@param  None

		@return ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.

		@exception      None
	*/
	/*=================================================================== */
		virtual ACS_APGCC_ReturnType performComponentHealthCheck(void) = 0 ;
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives Terminate callback from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	None
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		virtual ACS_APGCC_ReturnType performComponentTerminateJobs(void);
	/*=================================================================== */
	/**
		@brief	This routine is a virtual method and application shall use to override this method. This route
			is invoked by the by the common class ( this class ) when it receives Component Remove callback from CoreMW

		@par	None

		@pre	None

		@pre	None
	
		@param	None
				
		@return	ACS_APGCC_ReturnType
			On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure. 
				
		@exception	None
	*/
	/*=================================================================== */	
		virtual ACS_APGCC_ReturnType performComponentRemoveJobs   (void);			
	/*=================================================================== */
		ACS_APGCC_HA_ReturnType activate(void);
	/*=================================================================== */
	/**
	 	@brief		This route is entry routine to Activate the HA framework. 

		@par		None

		@pre		None

		@param		None

		@return		ACS_APGCC_HA_ReturnType
	 			On Success ACS_APGCC_HA_SUCCESS is returned.
			        On Failure, ACS_APGCC_HA_FAILURE_CLOSE is returned if the HA Framework is Failed to gracefully close the handles
					    ACS_APGCC_HA_FAILURE is returned on all other failure scenarios.	

		@exception      None
	*/
	/*=================================================================== */
		virtual ACS_APGCC_ReturnType performApplicationShutdownJobs();
	/*=================================================================== */
	/**
	 	@brief		This routine is virtual method, shall be used by applications to perform the shutdown operations gracefully.

		@par		None

		@pre		None

		@param		None

		@return         ACS_APGCC_ReturnType
				On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.

		@exception      None
	*/
	/*=================================================================== */
	 static void registerApplicationShutdownhandler(int sig);
	/*=================================================================== */
	/**
	 	@brief		This routine is used as the SIGUSR2 handler. 

		@par		None

		@param		None

		@return         ACS_APGCC_ReturnType
				On success ACS_APGCC_SUCCESS is returned and ACS_APGCC_FAILURE is retuned on failure.

		@exception      None
	*/
	/*=================================================================== */

} ;

#endif /* end of APOS_HA_RDEAGENT_AMFCLASS_H_ */

//----------------------------------------------------------------------------
//
//  COPYRIGHT Ericsson AB 2010
//
//  The copyright to the computer program(s) herein is the property of
//  ERICSSON AB, Sweden. The programs may be used and/or copied only
//  with the written permission from ERICSSON AB or in accordance with
//  the terms and conditions stipulated in the agreement/contract under
//  which the program(s) have been supplied.
//
//----------------------------------------------------------------------------


