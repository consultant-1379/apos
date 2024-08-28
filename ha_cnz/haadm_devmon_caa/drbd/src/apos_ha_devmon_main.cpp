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
 * @file apos_ha_devmon_main.cpp
 *
 * @brief
 * This is the main class of Devmon
 * Execution starts from here 
 * 
 * @author	Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <syslog.h>
#include <getopt.h>
#include <ace/ACE.h>

#include "apos_ha_logtrace.h"
#include "apos_ha_devmon_adm.h"
#include "apos_ha_devmon_hamanager.h"
#include "apos_ha_devmon_types.h"

/* Globals begin */
int nohaflag = 0;
int active   = 0;
int parse_command_line(int argc, char **argv);
ACE_THR_FUNC_RETURN run_devmon_daemon(void *);
/* Globals end */

//==========================================================================
// 							M A I N 
//==========================================================================

ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) 
{
	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	devmonHAClass* haObj=0;
	ACE_UINT32 rCode=0;

	/* parse the command line */
	if(parse_command_line(argc, argv) < 0) {
		fprintf(stderr, "USAGE: apos_ha_devmond [--noha] [--active]\n");
		return -1;
	}	

	if(nohaflag)
		return (long)run_devmon_daemon(0);

	/* --*-- HA Implementation  --*--
	probably we might need to use syslog API at this point, 
	as our messaging subsystem is not up and working yet */
	syslog(LOG_INFO, "Starting apos_ha_devmond from the command line");
	ACE_NEW_NORETURN(haObj, devmonHAClass("apos_ha_devmond", "root"));

	if (!haObj){
		syslog(LOG_ERR, "devmon-main-class: haObj Creation FAILED");
		rCode=-1;
		return rCode;
	}	

	/* Initialize the tracing sub-system first */
	ACE_TCHAR tracefile[256]={'\0'};
	static unsigned int __tracemask  = APOS_HA_DFLT_TRCE_CATGY;
	snprintf(tracefile, sizeof(tracefile),APOS_HA_DFLT_TRCE_DIR APOS_HA_DEVMON_LOG_FILE);
	if (apos_ha_logtrace_init("apos_ha_devmond", tracefile, __tracemask) != 0) {
		syslog(LOG_ERR, "devmon-main-class: Failed to initialize the trace subsystem");
		return -1;
	}	

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - DEVMON STARTING (Build Date:%s)", __func__, __DATE__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	errorCode = haObj->activate(); /* this should a blocking call */
	
	switch (errorCode) {
		case ACS_APGCC_HA_FAILURE: {
			HA_LG_ER("devmon-main-class: apos_ha_devmond, HA Activation Failed!");
			rCode=-2;
			break;
		}
		case ACS_APGCC_HA_FAILURE_CLOSE: {
			HA_LG_ER("devmon-main-class: apos_ha_devmond, HA Application Failed to Gracefullly closed!");
			rCode=-2;
			break;
		}			
		case ACS_APGCC_HA_SUCCESS: {
			HA_LG_ER("devmon-main-class: apos_ha_devmond, HA Application Gracefully closed!");
			rCode=0;
			break;
		}
		default: {
			HA_LG_ER("devmon-main-class: apos_ha_devmond, Unknown HA Application error detected!");
			rCode=-3;
			break;
		}			
	
	}		 	
	delete haObj;
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - DEVMON EXITING ", __func__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	return rCode;
}

//==========================================================================
// 	execute devmon as daemon
//==========================================================================

ACE_THR_FUNC_RETURN run_devmon_daemon( void *) 
{
	ACE_THR_FUNC_RETURN rCode=0;
	HA_DEVMON_Adm *haAdmObj;
	haAdmObj=0;

	/* Initialize the tracing sub-system first */
    ACE_TCHAR tracefile[256]={'\0'};
    static unsigned int __tracemask  = APOS_HA_DFLT_TRCE_CATGY;
    snprintf(tracefile, sizeof(tracefile),APOS_HA_DFLT_TRCE_DIR APOS_HA_DEVMON_LOG_FILE);
    if (apos_ha_logtrace_init("apos_ha_devmond", tracefile, __tracemask) != 0) {
        syslog(LOG_ERR, "devmon-main-class: Failed to initialize the trace subsystem");
		return (ACE_THR_FUNC_RETURN)-1;
    }

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - DEVMON STARTING Build Date:(%s)", __func__, __DATE__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);

	HA_LG_IN("Starting DEVMON from the command line");
	ACE_NEW_NORETURN(haAdmObj, HA_DEVMON_Adm());
	if (0 == haAdmObj){
		HA_LG_ER("devmon-main-class: new HA_DEVMON_Adm() Failed");
		rCode=(void*)-1;
	}else {
		int resAdm = haAdmObj->start(0,0);
		if (resAdm < 0){
			HA_LG_ER("devmon-main-class: Failed to start HA_DEVMON_Adm()");
		}else {
			haAdmObj->wait();
		}	

		delete haAdmObj;
	}	

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - DEVMON EXITING ", __func__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	return rCode;
}

//==========================================================================
//  parse command line paramters
//==========================================================================
int parse_command_line(int argc, char **argv)
{
    int index;
    int c;
    int noha_opt_cnt = 0, active_opt_cnt = 0;

    static struct option long_options[] =
    {
        /* These options set a flag. */
        {"noha", no_argument, & nohaflag, 1},
        {"active", no_argument, & active, 1},
        {0, 0, 0, 0}
    };

    /* getopt_long stores the option index here. */
    int option_index = 0;
    while (1) {
        c = getopt_long(argc, argv, "", long_options, &option_index);

        if (c == -1) /* have all command-line options have been parsed? */
            break;

		switch (c) {
            case 0:
            {
                if(strcmp(long_options[option_index].name, argv[optind-1] + 2)) {
                    fprintf(stderr,"devmon-main-class: Unrecognized option '%s'\n",argv[optind-1]);
                    return -1;
                }
                if (!strcmp(long_options[option_index].name, "noha")) {
                    /* found --noha option */
                    if(noha_opt_cnt > 0){
                        fprintf(stderr,"devmon-main-class: duplicated long option 'noha'\n");
                        return -1;
                    }
                    ++noha_opt_cnt;
                } else if (!strcmp(long_options[option_index].name, "active")) {
                    /* found --active option */
                    if(active_opt_cnt > 0){
                        fprintf(stderr,"devmon-main-class: duplicated long option 'active'\n");
                        return -1;
                    }
					 ++active_opt_cnt;
				}
				break;
            }

            case '?':
                    return -1;

            default:
                fprintf(stderr,"devmon-main-class: unrecognized option '%s'\n",argv[optind-1]);
                exit(EXIT_FAILURE);
                break;
		}
	}
    if( noha_opt_cnt == 0 && active_opt_cnt > 0) {
        fprintf(stderr,"devmon-main-class: either 'active' can be specified with only 'noha' flag.\n");
        return -1;

    }
    if((optind > 1) && !strcmp(argv[optind-1],"--")){
        fprintf(stderr,"devmon-main-class: Unrecognized option '%s'\n",argv[optind-1]);
        return -1;
    }
    if(optind < argc){
        for (index = optind; index < argc; index++)
            printf ("devmon-main-class: Incorrect usage, found non-option argument '%s'\n", argv[index]);
        return -1;
    }
    return 0;
}

//==========================================================================

