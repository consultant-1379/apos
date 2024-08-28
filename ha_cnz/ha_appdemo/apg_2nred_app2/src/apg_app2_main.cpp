#include <stdio.h>
#include <syslog.h>
#include "apg_app2_class.h"

ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) {

	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	(void) argc;
	(void) argv;
	
	int rCode=0;
	HAClass *haObj;
	
	ACE_NEW_NORETURN(haObj, HAClass("apos_ha_2napp2d", "root")); 
	if (!haObj) {
		syslog(LOG_ERR, "ha-class: haObj Creation FAILED");
		rCode=-2;
		return rCode;
	}

	haObj->log.Write("ha-class: starting apos_ha_2napp2d service.", LOG_LEVEL_INFO);
	errorCode = haObj->activate(); /* blocking call */

	switch (errorCode) {

		case ACS_APGCC_HA_FAILURE: {
			
			syslog(LOG_ERR, "ha-class: apos_ha_2napp2d, HA Activation Failed!");
			haObj->log.Write("ha-class: apos_ha_2napp2d, HA Activation Failed!", LOG_LEVEL_ERROR);
			rCode=-1;
			break;
		}
		case ACS_APGCC_HA_FAILURE_CLOSE: {

			syslog(LOG_ERR, "ha-class: apos_ha_2napp2d, HA Application Failed to Gracefullly closed!");
			haObj->log.Write("ha-class: apos_ha_2napp2d, HA Application Failed to Gracefullly closed!", LOG_LEVEL_ERROR);
			rCode=-2;
			break;
		}
		case ACS_APGCC_HA_SUCCESS: {
			
			syslog(LOG_INFO, "ha-class: apos_ha_2napp2d, HA Application Gracefully closed!");
			haObj->log.Write("ha-class: apos_ha_2napp2d, HA Application Gracefully closed!", LOG_LEVEL_ERROR);
			rCode=0;
			break;
		}
		default: {

			syslog(LOG_ERR, "ha-class: apos_ha_2napp2d, Unknown HA Application error detected!");
			haObj->log.Write("ha-class: apos_ha_2napp2d, Unknown HA Application error detected!", LOG_LEVEL_ERROR);
			rCode=-2;
			break;
		}
	}
	delete haObj;
	return rCode;	
}
