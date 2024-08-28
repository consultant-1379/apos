
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
 * @file apos_ha_devmon_reactorrunner.cpp
 *
 * @brief
 * Implements the reactorrunner
 *
 * @details
 * When a reactor is stopped it need to be reset in order to be able to
 * be started again. This is handled by this class.
 * When a reactor is restarted from another thread it need to be assigned
 * this no thread as its owner. This is handled by this class.
 *
 * @author  Malangsha Shaik (xmalsha)
 *
 **************************************************************************/
#include "apos_ha_reactorrunner.h"

//----------------------------------------------------------------------------

APOS_HA_ReactorRunner::APOS_HA_ReactorRunner(ACE_Reactor* reactor, const std::string& name):
   m_globalInstance(0),
   m_reactor(reactor),
   m_name(name)
{
	if (0 == m_reactor) {
		HA_LG_ER("%s() No reactor provided", __func__);
	}
	HA_TRACE("APOS_HA_ReactorRunner invoked");
}

//----------------------------------------------------------------------------

int APOS_HA_ReactorRunner::open() 
{
	HA_TRACE_ENTER();
	return this->activate( THR_JOINABLE | THR_NEW_LWP );
}

//----------------------------------------------------------------------------

int APOS_HA_ReactorRunner::svc() 
{
	HA_TRACE_ENTER();
	if (0 == m_reactor) {
		HA_LG_ER("%s() No reactor defined", __func__);
		return -1;
	}

	if (m_reactor->reactor_event_loop_done() != 0) {
		HA_LG_IN("%s() '%s' REACTOR is already running!!!", __func__, m_name.c_str());
	}
   
	HA_TRACE("%s() starting '%s' REACTOR ", __func__, m_name.c_str());
	if (m_name.compare(DRBDMON_MAIN_REACTOR) == 0) {
		HA_TRACE("%s() '%s' Change the reactor's owner", __func__, m_name.c_str());
		m_reactor->owner(ACE_OS::thr_self()); // Must change owner otherwise reactor cannot be restarted
	}
	 if (m_name.compare(DRBDRECOVERY_MAIN_REACTOR) == 0) {
		 HA_TRACE("%s() '%s' Change the reactor's owner", __func__, m_name.c_str());
		  m_reactor->owner(ACE_OS::thr_self());
	 }
	m_reactor->run_reactor_event_loop(); // Will hang until someone ends the loop
	HA_TRACE("%s() '%s' REACTOR is stopped", __func__, m_name.c_str());
	HA_TRACE_LEAVE();
	return 0;
}

//----------------------------------------------------------------------------

void APOS_HA_ReactorRunner::stop() 
{
	HA_TRACE_ENTER();
	if (0 == m_reactor) {
		HA_TRACE("%s() No reactor defined", __func__);
		return;
	}
	HA_TRACE( "%s() stopping '%s' REACTOR", __func__, m_name.c_str());
	m_reactor->end_reactor_event_loop();
	HA_TRACE_LEAVE();
}

//----------------------------------------------------------------------------

int APOS_HA_ReactorRunner::close (u_long /* flags */)
{
	HA_TRACE_ENTER();
	HA_TRACE_LEAVE();
	return 0;
}

//----------------------------------------------------------------------------
