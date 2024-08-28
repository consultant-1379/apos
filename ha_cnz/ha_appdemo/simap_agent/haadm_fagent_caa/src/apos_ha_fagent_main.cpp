#include <stdio.h>
#include <syslog.h>
#include "apos_ha_fagent_class.h"

ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) {

	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	(void) argc;
	(void) argv;
	
	int rCode=0;
	HAClass *haObj;
	
	ACE_NEW_NORETURN(haObj, HAClass("apos_ha_rdeagentd")); 
	if (!haObj) {
		syslog(LOG_ERR, "ha-class: haObj Creation FAILED");
		rCode=-2;
		return rCode;
	}

	syslog(LOG_INFO,"ha-class: starting apos_ha_rdeagentd service.");
	errorCode = haObj->activate(); /* blocking call */

	switch (errorCode) {

		case ACS_APGCC_HA_FAILURE: {
			
			syslog(LOG_ERR, "ha-class: apos_ha_rdeagentd, HA Activation Failed!");
			rCode=-1;
			break;
		}
		case ACS_APGCC_HA_FAILURE_CLOSE: {

			syslog(LOG_ERR, "ha-class: apos_ha_rdeagentd, HA Application Failed to Gracefullly closed!");
			rCode=-2;
			break;
		}
		case ACS_APGCC_HA_SUCCESS: {
			
			syslog(LOG_INFO, "ha-class: apos_ha_rdeagentd, HA Application Gracefully closed!");
			rCode=0;
			break;
		}
		default: {

			syslog(LOG_ERR, "ha-class: apos_ha_rdeagentd, Unknown HA Application error detected!");
			rCode=-2;
			break;
		}
	}
	delete haObj;
	return rCode;	
}
