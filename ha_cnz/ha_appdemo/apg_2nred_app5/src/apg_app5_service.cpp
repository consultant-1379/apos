#include <stdio.h>
#include <syslog.h>
#include "apg_app5_class.h"

int main(int argc, char **argv)
{
	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	(void) argc;
	(void) argv;

	HAClass *haObj = new HAClass("apos_ha_2napp5d", "root");

	syslog(LOG_INFO, "Starting apos_ha_2napp5d service.. ");

	errorCode = haObj->activate();
	
	if (errorCode == ACS_APGCC_HA_FAILURE){
		syslog(LOG_ERR, "apos_ha_2napp5d, HA Activation Failed!!");
		return ACS_APGCC_FAILURE;
	}

	if (errorCode == ACS_APGCC_HA_FAILURE_CLOSE){
		syslog(LOG_ERR, "apos_ha_2napp5d, HA Application Failed to Gracefullly closed!!");
		return ACS_APGCC_FAILURE;
	}

	if (errorCode == ACS_APGCC_HA_SUCCESS){
		syslog(LOG_ERR, "apos_ha_2napp5d, HA Application Gracefully closed!!");
			return ACS_APGCC_FAILURE;
	}
}

