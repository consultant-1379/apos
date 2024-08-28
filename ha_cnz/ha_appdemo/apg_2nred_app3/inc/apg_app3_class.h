#ifndef APG_APP1_CLASS_H
#define APG_APP1_CLASS_H

#include "ACS_APGCC_ApplicationManager.h"
#include "unistd.h"
#include "syslog.h"
#include "ace/Task.h"
#include "ace/OS_NS_poll.h"

class HAClass: public ACS_APGCC_ApplicationManager {

   private:
		
	int readWritePipe[2];
	ACS_APGCC_BOOL Is_terminated;

   public:
	HAClass(const char* daemon_name, const char* username);
	~HAClass(){};
	
	ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performComponentHealthCheck(void);
	ACS_APGCC_ReturnType performComponentTerminateJobs(void);
	ACS_APGCC_ReturnType performComponentRemoveJobs (void);
	ACS_APGCC_ReturnType performApplicationShutdownJobs(void);

	ACS_APGCC_ReturnType svc(void);
}; 

#endif /* APG_APP1_CLASS_H */
