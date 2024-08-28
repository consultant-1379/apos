#include <syslog.h>
#include "apos_ha_devmon_class.h"

DevMonClass *dMonObj = 0;

int main(int argc, char **argv) {

	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	int rCode=0;

        if( argc > 1)
        {
                // If -d flag is specified, then the user has requested to start the
		//                 // service in debug mode.
		//
		if( argc == 2 && (!strcmp(argv[1],"-d")) )
		{
			syslog(LOG_INFO, "Starting apos_ha_devmond in debug mode...");
		       //Allocate memory for NSF Server.
			ACE_NEW_NORETURN(dMonObj, DevMonClass());
			if( dMonObj == 0)
                        {
  				syslog(LOG_ERR, "Memory allocated failed for apos_ha_rdeagentd.. exiting");
				rCode=-1;
			}
			else
                        {
				if (dMonObj->Is_Node_Active() != ACS_APGCC_SUCCESS){
					syslog(LOG_ERR, "Failed to fetch node state in debug mode.. exiting");
					rCode=-2;
				}

				/*Some Logic for fetching node state*/
				if (rCode != -2) {
					if (ACS_APGCC_SUCCESS != dMonObj->Initialize()){
		                		syslog(LOG_ERR, "Failed to Initialize devmon.. exiting");
						rCode=-2;
	        	        	}
				}	
				if (rCode != -2) {
					dMonObj->svc_run(); // blocking call
					delete dMonObj;
					dMonObj=0;
				} else {
					delete dMonObj;
					dMonObj=0;					
				}
			}
		}
	}
	else
	{
		ACE_NEW_NORETURN(dMonObj, DevMonClass("apos_ha_devmond"));
        	if (!dMonObj) {
	        	syslog(LOG_ERR, "DevMon-class: dMonObj Creation FAILED");
		        rCode=-2;
			return rCode;
		}	
		syslog(LOG_INFO, "Starting apos_ha_devmond service.. ");

		errorCode = dMonObj->activate();

	        switch (errorCode) {

		        case ACS_APGCC_HA_FAILURE: {
				syslog(LOG_ERR, "apos_ha_devmond, HA Activation Failed!");
			        rCode=-1;
				break;
			}
			case ACS_APGCC_HA_FAILURE_CLOSE: {
				syslog(LOG_ERR, "apos_ha_devmond, HA Application Failed to Gracefullly closed!");
				rCode=-2;
	                        break;
	                }
	                case ACS_APGCC_HA_SUCCESS: {
				syslog(LOG_ERR, "apos_ha_devmond, HA Application Gracefully closed!");
			        rCode=0;
	                        break;
	                }
	                default: {
	                	syslog(LOG_ERR, "apos_ha_devmond, Unknown Application error detected!");
				rCode=-2;
				break;
			}
		
		}
		delete dMonObj;
	}
	return rCode;
}
