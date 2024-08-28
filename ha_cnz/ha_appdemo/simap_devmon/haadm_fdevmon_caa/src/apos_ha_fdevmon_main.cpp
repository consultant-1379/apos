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
 * @file apos_ha_fdevmon_main.cpp
 *
 * @brief
 *
 *
 * @author  Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <stdio.h>
#include <syslog.h>
#include <getopt.h>
#include "apos_ha_fdevmon_class.h"

/* Globals begin */
int nohaflag = 0;
int parse_command_line(int argc, char **argv);
ACE_THR_FUNC_RETURN run_devmon_daemon(void *);
/* Globals end */

//==========================================================================
//                          M A I N
//==========================================================================
ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) {

	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	(void) argc;
	(void) argv;
	
	int rCode=0;
	HAClass *haObj;
	/* parse the command line */
	if(parse_command_line(argc, argv) < 0) {
		fprintf(stderr, "USAGE: apos_ha_devmond [--noha] \n");
		return -1;
	}
	if(nohaflag)
		return (long)run_devmon_daemon(0);
	
	/* --*-- HA Implementation  --*--*/
	ACE_NEW_NORETURN(haObj, HAClass("apos_ha_devmond")); 
	if (!haObj) {
		syslog(LOG_ERR, "ha-class: haObj Creation FAILED");
		rCode=-2;
		return rCode;
	}

	syslog(LOG_INFO,"ha-class: starting apos_ha_devmond service.");
	errorCode = haObj->activate(); /* blocking call */

	switch (errorCode) {

		case ACS_APGCC_HA_FAILURE: {
			
			syslog(LOG_ERR, "ha-class: apos_ha_devmond, HA Activation Failed!");
			rCode=-1;
			break;
		}
		case ACS_APGCC_HA_FAILURE_CLOSE: {

			syslog(LOG_ERR, "ha-class: apos_ha_devmond, HA Application Failed to Gracefullly closed!");
			rCode=-2;
			break;
		}
		case ACS_APGCC_HA_SUCCESS: {
			
			syslog(LOG_INFO, "ha-class: apos_ha_devmond, HA Application Gracefully closed!");
			rCode=0;
			break;
		}
		default: {

			syslog(LOG_ERR, "ha-class: apos_ha_devmond, Unknown HA Application error detected!");
			rCode=-2;
			break;
		}
	}
	delete haObj;
	return rCode;	
}

//==========================================================================
//  parse command line paramters
//==========================================================================
int parse_command_line(int argc, char **argv)
{
    int index;
    int c;
    int noha_opt_cnt = 0;

    static struct option long_options[] =
    {
        /* These options set a flag. */
        {"noha", no_argument, & nohaflag, 1},
        {0, 0, 0, 0}
    };

    /* getopt_long stores the option index here. */
    int option_index = 0;
    while (1) {
        c = getopt_long(argc, argv, "", long_options, & option_index);

        if (c == -1) /* have all command-line options have been parsed? */
            break;

        switch (c) {
            case 0:
                if(strcmp(long_options[option_index].name, argv[optind-1] + 2)) {
                    fprintf(stderr,"fdevmon-main-class: Unrecognized option '%s'\n",argv[optind-1]);
                    return -1;
                }
                /* found --noha option */
                if(noha_opt_cnt > 0){
                    fprintf(stderr,"fdevmon-main-class: duplicated long option 'noha'\n");
                    return -1;
                }
                ++noha_opt_cnt;
                break;

            case '?':
                    return -1;

            default:
                fprintf(stderr,"fdevmon-main-class: unrecognized option '%s'\n",argv[optind-1]);
                exit(EXIT_FAILURE);
                break;
        }
    }

    if((optind > 1) && !strcmp(argv[optind-1],"--")){
        fprintf(stderr,"fdevmon-main-class: Unrecognized option '%s'\n",argv[optind-1]);
        return -1;
    }
    if(optind < argc){
        for (index = optind; index < argc; index++)
            printf ("fdevmon-main-class: Incorrect usage, found non-option argument '%s'\n", argv[index]);
        return -1;
    }
    return 0;
}
//==========================================================================
//  execute devmon as daemon
//==========================================================================
ACE_THR_FUNC_RETURN run_devmon_daemon( void *)
{
    int rCode=0;
    admClass *haAdmObj=0;

	syslog(LOG_INFO,"Starting FAKE DEVMON from the command line");
    ACE_NEW_NORETURN(haAdmObj, admClass());
    if (0 == haAdmObj){
		syslog(LOG_ERR,"fdevmon-main-class: new admClass() Failed");
		rCode=-1;
    }else{
        int resAdm = haAdmObj->start(0,0);
        if (resAdm < 0){
             syslog(LOG_ERR, "fdevmon-main-class: Failed to start admClass()");
        }else{
            haAdmObj->wait();
        }
        delete haAdmObj;
		haAdmObj=0;
    }

	syslog(LOG_INFO, "FAKE DEVMON EXITING");
    return (ACE_THR_FUNC_RETURN)rCode;
}



