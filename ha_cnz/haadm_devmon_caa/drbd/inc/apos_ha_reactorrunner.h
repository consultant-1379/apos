
/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2012
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_reactorrunner.h
 *
 * @brief
 * Uses an ACE_Task to run a reactor.
 *
 * @details
 * Create an instance of this class and assign it a reactor instance.
 * Call open() to start the reactor.
 * Call stop() to stop the reactor.
 *
 * @author Malangsha Shaik
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_REACTORRUNNER_H_
#define APOS_HA_REACTORRUNNER_H_

#include <string>
#include <ace/Task.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_devmon_global.h" 

const std::string  DRBDMON_MAIN_REACTOR   = "DRBDMon Main Reactor";
const std::string  DRBDRECOVERY_MAIN_REACTOR  = "DRBDRecovery Main Reactor";

class ACE_Reactor;
class Global;
//----------------------------------------------------------------------------
class APOS_HA_ReactorRunner: public ACE_Task<ACE_SYNCH> 
{

 public:
	
   APOS_HA_ReactorRunner(ACE_Reactor* reactor, const std::string& name);
   int open();
   int svc();
   void stop();
   int close (u_long flags = 0);
   
 private:

   Global* m_globalInstance;
   ACE_Reactor* m_reactor;
   std::string m_name;
};

#endif

