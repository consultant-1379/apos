//	********************************************************
//
//	 COPYRIGHT Ericsson 2018
//	All rights reserved.
//
//	The Copyright to the computer program(s) herein
//	is the property of Ericsson 2018.
//	The program(s) may be used and/or copied only with
//	the written permission from Ericsson 2018 or in
//	accordance with the terms and conditions stipulated in
//	the agreement/contract under which the program(s) have
//	been supplied.
//
//	********************************************************
#include "engine/workingset.h"

#include "common/tracer.h"
#include "common/logger.h"


APG_COMPONENT_TRACE_DEFINE(Engine_WorkingSet)

namespace engine
{
	WorkingSet::WorkingSet()
	: m_debugMode(false),
	  m_scheduler(),
	  m_reactorImpl(),
	  m_reactor(&m_reactorImpl)
	{
		//pid_t parent_pid = ::getpid();
		//APG_COMPONENT_SYSLOG(LOG_DEBUG, LOG_LEVEL_DEBUG, "WorkingSet created by daemon pid:<%d>", parent_pid);
	};

	WorkingSet::~WorkingSet()
	{
		//pid_t parent_pid = ::getpid();
		//APG_COMPONENT_SYSLOG( LOG_DEBUG, LOG_LEVEL_DEBUG, "WorkingSet deleted by daemon pid:<%d>", parent_pid);
	}
}
