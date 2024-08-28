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
 * @file apos_ha_usa_reactorRunner.h
 *
 * @brief
 * Users an ACE_Task to run a reactor.
 *
 * @details
 * Create an instance of this class and assign it a reactor instance.
 * Call open() to start the reactor.
 * Call stop() to stop the reactor.
 *
 * @author XTBAKLU
 *
 -------------------------------------------------------------------------*//*
 *
 * REVISION HISTORY
 *
 * DATE        USER     DESCRIPTION/TR
 * --------------------------------
 *
 ****************************************************************************/

#ifndef APOS_HA_REACTORRUNNER_H_
#define APOS_HA_REACTORRUNNER_H_

#include <string>
#include <ace/Task.h>
#include <ace/TP_Reactor.h>

class ACE_Reactor;

//----------------------------------------------------------------------------
class APOS_HA_ReactorRunner: public ACE_Task<ACE_SYNCH> {
	
public:
	
   APOS_HA_ReactorRunner();
   ACE_Reactor* m_reactor;
   int open();
   int svc();
   void stop();
   
private:
   
   ACE_TP_Reactor* m_reactorImpl;
   std::string m_name;
};

#endif /* APOS_HA_REACTORRUNNER_H_ */

