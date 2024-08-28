#ifndef APOS_HA_FAGENT_ADM_H
#define APOS_HA_FAGENT_ADM_H

#include "unistd.h"
#include "syslog.h"
#include <ace/Task_T.h>
#include <ace/OS.h>
#include "ACS_APGCC_ApplicationManager.h"
#include "apos_ha_devmon_amfclass.h"

#define CMD_LEN 100 /* includes buff len*/
#define HA_BASE_CMD "/opt/ap/apos/bin/apos_ha_operations"
#define APOS_BASE_CMD "/opt/ap/apos/bin/apos_operations"
#define DISK_MGMT_CMD "/usr/bin/raidmgmt"
#define DISK_MGMT_CMD_LEN 50 /* includes buff len */

class HAClass;

class admClass: public ACE_Task<ACE_SYNCH> {

   private:
	HAClass* m_haObj;
        ACS_APGCC_BOOL IsRAIDConfigured;
        ACS_APGCC_BOOL IsMIPConfigured;
        ACS_APGCC_BOOL Is_Agent_Stanby;
        ACS_APGCC_BOOL Is_State_Assgned;
	ACS_APGCC_BOOL handleRdeAgentGracefullDownJobsDone;
	
	int open(HAClass* haObj);
	int open(int argc, char* argv[]);
	void InitiateFailover(ACS_APGCC_AMF_RecommendedRecoveryT recommendedRecovery);
	ACS_APGCC_ReturnType handleRdeAgentGracefullDownJobs();
	void reboot_local_node();
	ACS_APGCC_ReturnType launchCommand(char *command_string);
	ACS_APGCC_ReturnType mountRAIDandActivateMIPs();
	ACS_APGCC_ReturnType umountRAIDandDeactivateMIPs();	
   public:
	
	admClass();
	~admClass(){};
	int passiveToActive;

	int start(HAClass* haObj );
	void stop();
	virtual int svc();
}; 

#endif /* APOS_HA_FAGENT_ADM_H */

