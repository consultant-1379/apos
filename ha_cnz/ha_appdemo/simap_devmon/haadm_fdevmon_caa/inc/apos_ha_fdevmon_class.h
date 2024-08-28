#ifndef APOS_HA_FAGENT_CLASS_H
#define APOS_HA_FAGENT_CLASS_H

#include "apos_ha_fdevmon_amfclass.h"
#include "unistd.h"
#include "syslog.h"
#include "apos_ha_fdevmon_adm.h"

class admClass;

class HAClass: public APOS_HA_Devmon_AmfClass {
   private:
	admClass *m_admClassObj;
	ACE_UINT32 passiveToActive;
	ACS_APGCC_ReturnType activateApp();
	ACS_APGCC_ReturnType passifyApp();
	ACS_APGCC_ReturnType shutdownApp();

   public:
	HAClass(const char* daemon_name);
	~HAClass();
	ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState);
	ACS_APGCC_ReturnType performComponentHealthCheck(void);
	ACS_APGCC_ReturnType performComponentTerminateJobs(void);
	ACS_APGCC_ReturnType performComponentRemoveJobs (void);
	ACS_APGCC_ReturnType performApplicationShutdownJobs(void);
}; 

#endif /* APOS_HA_FAGENT_CLASS_H */
