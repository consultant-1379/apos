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
 * @file apos_ha_agent_main.cpp
 *
 * @brief
 *
 * This is the main class of AGENT
 *
 * @author	Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include <syslog.h>
#include <getopt.h>
#include <apos_ha_agent_actvAdm.h>
#include <apos_ha_agent_stbyAdm.h>
#include <apos_ha_agent_hamanager.h>
#include <apos_ha_agent_types.h>
#include <ace/ACE.h>
#include <apos_ha_logtrace.h>

/* Globals begin */
int nohaflag = 0;
int active   = 0;
int noactive = 0;
int parse_command_line(int argc, char **argv);
ACE_THR_FUNC_RETURN run_agent_daemon(void *);
ACE_THR_FUNC_RETURN run_active_daemon(void *);
ACE_THR_FUNC_RETURN run_noactive_daemon(void *);
/* Globals end */

//==========================================================================
// 							M A I N 
//==========================================================================
ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) 
{
	ACS_APGCC_HA_ReturnType errorCode = ACS_APGCC_HA_SUCCESS;
	agentHAClass* haObj;
	ACE_UINT32 rCode=0;
	haObj=0;

	/* parse the command line */
	if(parse_command_line(argc, argv) < 0) {
		fprintf(stderr, "USAGE: apos_ha_rdeagentd [--noha] [--active]|[--noactive]\n");
		return -1;
	}	

	if(nohaflag) {
		syslog(LOG_INFO, "Starting apos_ha_rdeagentd from the command line");
		return (long)run_agent_daemon(0);
	}	

	/* --*-- HA Implementation  --*--
	probably we might need to use syslog API at this point, 
	as our messaging subsystem is not up and working yet */
	syslog(LOG_INFO, "Starting apos_ha_rdeagentd daemon in HA Framework.");
	ACE_NEW_NORETURN(haObj, agentHAClass("apos_ha_rdeagentd", "root"));

	if (!haObj){
		syslog(LOG_ERR, "agent-main-class: haObj Creation FAILED");
		rCode=-1;
		return rCode;
	}	

	/* Initialize the tracing sub-system first */
	ACE_TCHAR tracefile[256]={'\0'};
	static unsigned int __tracemask  = APOS_HA_DFLT_TRCE_CATGY;
	snprintf(tracefile, sizeof(tracefile),APOS_HA_DFLT_TRCE_DIR APOS_HA_AGENT_LOG_FILE);
	if (apos_ha_logtrace_init("apos_ha_rdeagentd", tracefile, __tracemask) != 0) {
		syslog(LOG_ERR, "agent-main-class: Failed to initialize the trace subsystem");
		return -1;
	}	

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - AGENT STARTING (Build Date:%s)", __func__, __DATE__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	errorCode = haObj->activate(); /* this should a blocking call */
	
	switch (errorCode) {
		case ACS_APGCC_HA_FAILURE: {
			HA_LG_ER("agent-main-class: apos_ha_rdeagentd, HA Activation Failed!");
			rCode=-2;
			break;
		}
		case ACS_APGCC_HA_FAILURE_CLOSE: {
			HA_LG_ER("agent-main-class: apos_ha_rdeagentd, HA Application Failed to Gracefullly closed!");
			rCode=-2;
			break;
		}			
		case ACS_APGCC_HA_SUCCESS: {
			HA_LG_ER("agent-main-class: apos_ha_rdeagentd, HA Application Gracefully closed!");
			rCode=0;
			break;
		}
		default: {
			HA_LG_ER("agent-main-class: apos_ha_rdeagentd, Unknown HA Application error detected!");
			rCode=-3;
			break;
		}			
	
	}		 	
	delete haObj;

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - AGENT EXITING ", __func__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	return rCode;
}

//==========================================================================
// 	execute agent as daemon
//==========================================================================
ACE_THR_FUNC_RETURN run_agent_daemon(void *) 
{
	// Initialize the traceing sub-system first
	char tracefile[256]={'\0'};
	static unsigned int __tracemask  = APOS_HA_DFLT_TRCE_CATGY;
	snprintf(tracefile, sizeof(tracefile), APOS_HA_DFLT_TRCE_DIR APOS_HA_AGENT_LOG_FILE);
	if (apos_ha_logtrace_init("apos_ha_rdeagentd", tracefile, __tracemask) != 0) {
		syslog(LOG_ERR, "agent-main-class: Failed to initialize the trace subsystem");
		return (ACE_THR_FUNC_RETURN)-1;
	}	

	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - AGENT STARTING Build Date:(%s)", __func__, __DATE__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);

	HA_LG_IN("Starting AGENT from the command line");
	if (active) {
		run_active_daemon(0);
	} else if (noactive) {
		run_noactive_daemon(0);
	} else {
		HA_LG_ER("agent-main-class: Invalid option");
	}
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	HA_TRACE_1("%s() - AGENT EXITING ", __func__);
	HA_TRACE_1("%s() - ---------------------------------------", __func__);
	syslog(LOG_INFO, "AGENT EXITING...");

	return (ACE_THR_FUNC_RETURN)0;
}

//==========================================================================
// 	execute agent as active daemon
//==========================================================================
ACE_THR_FUNC_RETURN run_active_daemon(void *)
{
	HA_AGENT_ACTVAdm *actvAdmObj=0;
	ACE_THR_FUNC_RETURN rCode=0;
	//Determine the node state and act accordingly.
	ACE_NEW_NORETURN(actvAdmObj, HA_AGENT_ACTVAdm());
	if (0 == actvAdmObj){
		HA_LG_ER("agent-main-class: new HA_AGENT_ACTVAdm() Failed");
		rCode=(void*)-1;
	}else{
		int resAdm = actvAdmObj->start(0,0);
		if (resAdm < 0){
			HA_LG_ER("agent-main-class: Failed to start HA_AGENT_ACTVAdm()");
			}else{
			actvAdmObj->wait();
		}	
		delete actvAdmObj;
	}
	return rCode;
}

//==========================================================================
// 	execute agent as no-active daemon
//==========================================================================
ACE_THR_FUNC_RETURN run_noactive_daemon(void *)
{
	HA_AGENT_STNBYAdm *stbyAdmObj=0;
	ACE_THR_FUNC_RETURN rCode=0;
	//Determine the node state and act accordingly.
	ACE_NEW_NORETURN(stbyAdmObj, HA_AGENT_STNBYAdm());
	if (0 == stbyAdmObj){
		HA_LG_ER("agent-main-class: new HA_AGENT_STNBYAdm() Failed");
		rCode=(void*)-1;
	}else{
		int resAdm = stbyAdmObj->start(0,0);
		if (resAdm < 0){
			HA_LG_ER("agent-main-class: Failed to start HA_AGENT_STNBYAdm()");
		}else{
			stbyAdmObj->wait();
		}	
		delete stbyAdmObj;
	}
	return rCode;
}

//==========================================================================
//  parse command line paramters
//==========================================================================
int parse_command_line(int argc, char **argv) 
{
	int index;
	int c;
	int noha_opt_cnt = 0, active_opt_cnt = 0, passive_opt_cnt = 0;

	static struct option long_options[] =
	{		
		/* These options set a flag. */
		{"noha", no_argument, & nohaflag, 1},
		{"active", no_argument, & active, 1},
		{"noactive", no_argument, & noactive, 1},
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
					fprintf(stderr,"agent-main-class: Unrecognized option '%s'\n",argv[optind-1]);
					return -1;
				}	
				if (!strcmp(long_options[option_index].name, "noha")) {
					/* found --noha option */
					if(noha_opt_cnt > 0){
						fprintf(stderr,"agent-main-class: duplicated long option 'noha'\n");
						return -1;
					}
					++noha_opt_cnt;
				} else if (!strcmp(long_options[option_index].name, "active")) {
					/* found --active option */
					if(active_opt_cnt > 0){
						fprintf(stderr,"agent-main-class: duplicated long option 'active'\n");
						return -1;
					}
					if (passive_opt_cnt > 0) {
						fprintf(stderr,"agent-main-class: either 'active' or 'passive' can be specified\n");
						return -1;
					}
					++active_opt_cnt;
				} else if (!strcmp(long_options[option_index].name, "passive")) {
					if(passive_opt_cnt > 0){
						fprintf(stderr,"agent-main-class: duplicated long option 'passive'\n");
						return -1;
					}
					if (active_opt_cnt > 0) {
						fprintf(stderr,"agent-main-class: either 'active' or 'passive' can be specified\n");
						return -1;
					}
					++passive_opt_cnt;
				}
				break;
			}

			case '?':
					return -1;
			
			default:
				fprintf(stderr,"agent-main-class: unrecognized option '%s'\n",argv[optind-1]);
				exit(EXIT_FAILURE);
				break;
		}
	}				
	if( noha_opt_cnt == 0 && (passive_opt_cnt > 0 || active_opt_cnt > 0)) {
		fprintf(stderr,"agent-main-class: either 'active' or 'passive' can be specified with only 'noha' flag.\n");
		return -1;

	}
	if((optind > 1) && !strcmp(argv[optind-1],"--")){
		fprintf(stderr,"agent-main-class: Unrecognized option '%s'\n",argv[optind-1]);
		return -1;
	}
	if(optind < argc){
		for (index = optind; index < argc; index++)
			printf ("agent-main-class: Incorrect usage, found non-option argument '%s'\n", argv[index]);
		return -1;
	}	
	return 0;
}
//==========================================================================

