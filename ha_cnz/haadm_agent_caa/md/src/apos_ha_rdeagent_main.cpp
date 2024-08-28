/*===================================================================
 *
 *    @file   apos_ha_rdeagent_main.cpp
 *
 *    @brief
 *
 *
 *    @version 1.0.0
 *
 *
 *    HISTORY
 *
 *
 *
 *
 *       PR           DATE      INITIALS    DESCRIPTION
 *--------------------------------------------------------------------
 *       N/A       DD/MM/YYYY     NS       Initial Release
 *==================================================================== */

/*====================================================================
 *                           DIRECTIVE DECLARATION SECTION
 * =================================================================== */

#include "apos_ha_rdeagent_class.h"
#include "ace/ACE.h"
#include "syslog.h"
#include "ace/OS_NS_poll.h"
#include "errno.h"
#include "sys/time.h"

ACS_APGCC_BOOL agent_poll(APGHA_RDEAgent*);

ACE_INT32 ACE_TMAIN(ACE_INT32 argc, ACE_TCHAR **argv) 
{
	(void)argc;
	(void)argv;
	APGHA_RDEAgent *rdaObj;
	if( argc >= 1) {
		if( argc == 2 && (!strcmp(argv[1],"-d")) )
		{
			syslog(LOG_INFO, "Starting apos_ha_rdeagentd in debug mode...");
			rdaObj = new APGHA_RDEAgent();
			if(rdaObj){ rdaObj->IsDebug=TRUE; }
			else {
				syslog(LOG_INFO, "Memory allocated failed for apos_ha_rdeagentd ");
				syslog(LOG_INFO, "Shutting down apos_ha_rdeagentd");
			}
			if(agent_poll(rdaObj)==ACS_APGCC_SUCCESS) {
				syslog(LOG_INFO,  "apos_ha_rdeagentd daemon exiting...");
			} else { syslog(LOG_INFO,  "Critical error occured in apos_ha_rdeagentd daemon while exiting!"); }

			delete rdaObj;
			rdaObj = 0;
		}
		else
		{       
			syslog(LOG_INFO,  "apos_ha_rdeagentd started in HA mode...");
			rdaObj = new APGHA_RDEAgent("apos_ha_rdeagentd","root");
			if( rdaObj == 0) {
				syslog(LOG_INFO, "Memory allocated failed for apos_ha_rdeagentd ");
				syslog(LOG_INFO, "Shutting down apos_ha_rdeagentd");
			}
			if(agent_poll(rdaObj) == ACS_APGCC_SUCCESS) {
				syslog(LOG_INFO,  "apos_ha_rdeagentd daemon exiting...");
			} else { syslog(LOG_INFO,  "Critical error occured in apos_ha_rdeagentd daemon while exiting!"); }

			delete rdaObj;
			rdaObj = 0;
		}
	}
	return 0;			
}


ACS_APGCC_BOOL agent_poll(APGHA_RDEAgent *rdaObj)
{
	ACE_INT32 retval;
	nfds_t nfds = 7;

	/* Create a Selection Objects */
	if ( APGHA_RDEAgent::utils.sel_obj_create(&(rdaObj->term_sel_obj)) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR ,"RDE_Agent: term_sel_obj failed");
		return ACS_APGCC_FAILURE;
	}
	if ( APGHA_RDEAgent::utils.sel_obj_create(&(rdaObj->sigrt_sel_obj)) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR ,"RDE_Agent: sigrt_sel_obj failed");
		return ACS_APGCC_FAILURE;
	}
	if ( APGHA_RDEAgent::utils.sel_obj_create(&(rdaObj->sighup_sel_obj)) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR ,"RDE_Agent: sighup_sel_obj failed");
		return ACS_APGCC_FAILURE;
	}
	if ( APGHA_RDEAgent::utils.sel_obj_create(&(rdaObj->sigint_sel_obj)) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR ,"RDE_Agent: sigint_sel_obj failed");
		return ACS_APGCC_FAILURE;
	}	
	/* Initialize signal handlers */
	if ((signal(SIGUSR1, APGHA_RDEAgent::sigusr1Handler)) == SIG_ERR) {
		syslog(LOG_ERR,"RDE_Agent: signal USR1 failed: %s", strerror(errno));
		return ACS_APGCC_FAILURE;
	}
	if ((signal(SIGTERM, APGHA_RDEAgent::AgentShutdownHandler)) == SIG_ERR) {
		syslog(LOG_ERR,"RDE_Agent: Installing sigusrTwo handler FAILED: %s", strerror(errno));
		return ACS_APGCC_FAILURE;
	}
	if ((signal(SIGINT, APGHA_RDEAgent::AgentShutdownHandler)) == SIG_ERR) {
		syslog(LOG_ERR,"RDE_Agent: Installing sigint handler FAILED: %s", strerror(errno));
		return ACS_APGCC_FAILURE;
	}
	if ((signal(SIGHUP, APGHA_RDEAgent::sighupHandler)) == SIG_ERR) {
		syslog(LOG_ERR,"RDE_Agent: Installing sigusrTwo handler FAILED: %s", strerror(errno));
		return ACS_APGCC_FAILURE;
	}
	/* Initialize the RT Signal Handler to receive Signal from
	 * DEVMON on the Health of Following.
	 * 1. Data Disks Health
	 * 2. Controllers Health
	 * 3. Raid Health
	 */
	if ((signal(SIG_UPDATE_DISK, APGHA_RDEAgent::updateDiskStatusHandler)) == SIG_ERR){
		syslog(LOG_ERR, "RDE_Agent: Error! Registeration of updateDiskStatusHandler FAILED");
		return ACS_APGCC_FAILURE;
	}
	if ((signal(SIG_UPDATE_RAID, APGHA_RDEAgent::updateRaidStatusHandler)) == SIG_ERR){
		syslog(LOG_ERR, "RDE_Agent: Error! Registeration of updateRaidStatusHandler FAILED");
		return ACS_APGCC_FAILURE;
	}	
	/* rde agent initialization */
	if (rdaObj->InitializeRdeAgentEngine() != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR, "RDE_Agent: Application Initialization FAILED");
		return ACS_APGCC_FAILURE;
	}
	if(!rdaObj->IsDebug) {
		/* Initialize CoreMW Framework */
		if (rdaObj->coreMWInitialize() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: coreMWInitialize FAILED");
			return ACS_APGCC_FAILURE;
		}
	}
	/* Initialize the iTimer to schedule the disk renewal */
	if (rdaObj->iTimerInit() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: iTimerInit FAILED");
		return ACS_APGCC_FAILURE;
	}

	/* AMF fd */
	rdaObj->fds[rdaObj->FD_AMF].fd = rdaObj->getSelObj();
	rdaObj->fds[rdaObj->FD_AMF].events = POLLIN;

	/*TERM fd*/
	rdaObj->fds[rdaObj->FD_TERM].fd = rdaObj->term_sel_obj.rmv_obj;
	rdaObj->fds[rdaObj->FD_TERM].events = POLLIN;

	/* RTMIN fd */
	rdaObj->fds[rdaObj->FD_RT].fd = rdaObj->sigrt_sel_obj.rmv_obj;
	rdaObj->fds[rdaObj->FD_RT].events = POLLIN;

	/* HUP fd */
	rdaObj->fds[rdaObj->FD_HUP].fd = rdaObj->sighup_sel_obj.rmv_obj;
	rdaObj->fds[rdaObj->FD_HUP].events = POLLIN;

	/* iTimer fd */
	rdaObj->fds[rdaObj->FD_iTimer].fd = rdaObj->iTimer_sel_obj.rmv_obj;
	rdaObj->fds[rdaObj->FD_iTimer].events = POLLIN;

	/* TIPC fd */
	rdaObj->fds[rdaObj->FD_TIPC].fd = rdaObj->tipcObj.getFd();
	rdaObj->fds[rdaObj->FD_TIPC].events = POLLIN;

	rdaObj->fds[rdaObj->FD_INT].fd = rdaObj->sigint_sel_obj.rmv_obj;
	rdaObj->fds[rdaObj->FD_INT].events = POLLIN;

	if(rdaObj->IsDebug) {
		if(rdaObj->ExecuteDebug() == ACS_APGCC_FAILURE) { return ACS_APGCC_FAILURE; }
	}
	while(1) {
		retval = ACE_OS::poll(rdaObj->fds, nfds, 0) ;
		if (retval == -1) {
			if (errno == EINTR)
				continue;
			syslog(LOG_ERR,"RDE_Agent: poll Failed - %s, Exiting...",strerror(errno));
			break;
		}	
		if(!rdaObj->IsDebug)
		{
			if ( rdaObj->fds[rdaObj->FD_AMF].revents & POLLIN ){
				if ( (rdaObj->getSelObj()) != 0 ) {
					if ( rdaObj->dispatch(ACS_APGCC_AMF_DISPATCH_ALL) != ACS_APGCC_SUCCESS) {
						syslog(LOG_ERR,"RDE_Agent :rdaObj->dispatch failed, Exiting...");
						break;
					}
					if (rdaObj->terminateRdeAgent == TRUE){
						/* we have already released both the disks on performComponentTerminateJobs */
						syslog(LOG_INFO, "RDE_Agent: Exiting...");
						break;
					}
				}
			}	
		}

		if (rdaObj->fds[rdaObj->FD_RT].revents & POLLIN){
			APGHA_RDEAgent::utils.sel_obj_rmv_ind(APGHA_RDEAgent::sigrt_sel_obj, TRUE, TRUE);
			syslog(LOG_INFO ,"RDE_Agent: Event received to update Disk/Raid Status");

			if(rdaObj->updateDeviceStatus() != ACS_APGCC_SUCCESS) {
				syslog(LOG_INFO ,"RDE_Agent: Error! Updating the devices status, Exiting...");
				break;
			}
		}

		if ( rdaObj->fds[rdaObj->FD_HUP].revents & POLLIN ){
			syslog(LOG_INFO, "RDE_Agent: HUP event received");
			APGHA_RDEAgent::utils.sel_obj_rmv_ind(APGHA_RDEAgent::sighup_sel_obj, TRUE, TRUE);

			syslog(LOG_INFO,"Reading config file");
			if (rdaObj->readConfig() != ACS_APGCC_SUCCESS){
				syslog(LOG_ERR, "RDE_Agent: Error in Reading configuration file");
			}
		}

		if (rdaObj->fds[rdaObj->FD_TERM].revents & POLLIN ){
			APGHA_RDEAgent::utils.sel_obj_rmv_ind(APGHA_RDEAgent::term_sel_obj, TRUE, TRUE);
			if(rdaObj->sigterm_received){
				syslog(LOG_ERR, "RDE_Agent: Shutting down Agent gracefully...");
				if (rdaObj->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
					syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED");
				}
			}
			syslog(LOG_INFO, "RDE_Agent: (TERM) Exiting...");
			break;
		}

		if (rdaObj->fds[rdaObj->FD_INT].revents & POLLIN ){
			APGHA_RDEAgent::utils.sel_obj_rmv_ind(APGHA_RDEAgent::sigint_sel_obj, TRUE, TRUE);
			if(rdaObj->sigint_received){
				syslog(LOG_ERR, "RDE_Agent: Shutting down Agent gracefully...");
				if (rdaObj->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
					syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED");
				}
			}
			syslog(LOG_INFO, "RDE_Agent: (INT) Exiting...");
			break;
		}

		if (rdaObj->fds[rdaObj->FD_iTimer].revents & POLLIN){
			if (rdaObj->iTimerTimeoutHandler() != ACS_APGCC_SUCCESS){
				syslog(LOG_INFO, "RDE_Agent (TIMEOUT): Exiting...");
				break;
			}
		}

		if (rdaObj->fds[rdaObj->FD_TIPC].revents & POLLIN){
			rdaObj->tipcObj.topserver_handler();
		}
	}		         

	/* end while */
	/* Time to release handles we own.
	 * First:  destroy rda library
	 * second: release amf handle
	 */
	if(!rdaObj->IsDebug) {
		if ( !rdaObj->sigterm_received) {
			syslog(LOG_INFO ,"RDE_Agent: SIGTERM received in HA mode...calling finalize AMF");
			if ( rdaObj->AmfFinalize() != ACS_APGCC_SUCCESS ) {
				syslog(LOG_ERR, "RDE_Agent :rdaObj->finalize FAILED");
			}
		}
	}

	/* destroy the real time signal selection object */
	APGHA_RDEAgent::utils.sel_obj_destroy(rdaObj->sigrt_sel_obj);

	/* destroy hup signal selection object */
	APGHA_RDEAgent::utils.sel_obj_destroy(rdaObj->sighup_sel_obj);

	/* destroy iTimer signal selection object */
	APGHA_RDEAgent::utils.sel_obj_destroy(rdaObj->iTimer_sel_obj);

	/* destroy term & usr2 signal selection object */
	APGHA_RDEAgent::utils.sel_obj_destroy(rdaObj->term_sel_obj);

	/* destroy int signal selection object */
	APGHA_RDEAgent::utils.sel_obj_destroy(rdaObj->sigint_sel_obj);

	return ACS_APGCC_SUCCESS;
}
//******************************************************************************

//----------------------------------------------------------------------------
//
//  COPYRIGHT Ericsson AB 2010
//
//  The copyright to the computer program(s) herein is the property of
//  ERICSSON AB, Sweden. The programs may be used and/or copied only
//  with the written permission from ERICSSON AB or in accordance with
//  the terms and conditions stipulated in the agreement/contract under
//  which the program(s) have been supplied.
//
//----------------------------------------------------------------------------
