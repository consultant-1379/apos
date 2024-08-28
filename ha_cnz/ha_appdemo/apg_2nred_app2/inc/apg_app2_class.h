#ifndef APG_APP2_CLASS_H
#define APG_APP2_CLASS_H

#include "ACS_APGCC_ApplicationManager.h"
#include "unistd.h"
#include "syslog.h"
#include "apg_app2_appclass.h"
#include "ACS_TRA_Logging.h"

class HAClass: public ACS_APGCC_ApplicationManager {

   private:

	myClass *m_myClassObj;
	ACE_UINT32 passiveToActive;
	ACS_APGCC_ReturnType activateApp();
	ACS_APGCC_ReturnType passifyApp();
	ACS_APGCC_ReturnType shutdownApp();

   public:
	HAClass(const char* daemon_name, const char* user);
	~HAClass();
	ACS_TRA_Logging log;
	ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performComponentHealthCheck(void);
	ACS_APGCC_ReturnType performComponentTerminateJobs(void);
	ACS_APGCC_ReturnType performComponentRemoveJobs (void);
	ACS_APGCC_ReturnType performApplicationShutdownJobs(void);
}; 

#endif /* APG_APP2_CLASS_H */
