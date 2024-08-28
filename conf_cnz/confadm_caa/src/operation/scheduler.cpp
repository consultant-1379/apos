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
#include "operation/scheduler.h"

#include "operation/operationbase.h"
#include "operation/creator.h"
#include "common/tracer.h"
#include "common/logger.h"
#include <ace/Method_Request.h>


#include "common/macros.h"
#include "common/programconstants.h"
#include <memory>

APG_COMPONENT_TRACE_DEFINE(Operation_Scheduler)

namespace operation
{
	Scheduler::~Scheduler()
	{
		APG_COMPONENT_TRACE_FUNCTION;
		// Delete all queued request
		while(!((bool)m_ActivationQueue.is_empty()) )
		{
			// Dequeue the next method object
			std::auto_ptr<ACE_Method_Request> cmdRequest(m_ActivationQueue.dequeue());
		}
	}

	int Scheduler::svc(void)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Starting execution...");
		bool svcRun = true;

		int result = common::errorCode::ERR_NO_ERRORS;

		while(svcRun)
		{
			APG_COMPONENT_TRACE_MESSAGE("Waiting for operation requests");

			// Dequeue the next method object
			std::auto_ptr<ACE_Method_Request> cmdRequest(m_ActivationQueue.dequeue());

			//interrogate the auto_ptr to check if it is null
			if (cmdRequest.get())
			{
				APG_COMPONENT_TRACE_MESSAGE("Executing Operation");

				if(cmdRequest->call() == common::errorCode::ERR_SVC_DEACTIVATE)
				{
					svcRun = false;
				}
			}
			else
			{
				APG_COMPONENT_TRACE_MESSAGE("WARNING: READ NULL POINTER");
				APG_COMPONENT_LOG(LOG_LEVEL_WARN, "READ NULL POINTER");
			}
		}

		APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "...Terminating execution");
		return result;
	}

	int Scheduler::open(void *args)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		UNUSED(args);

		int result = common::errorCode::ERR_NO_ERRORS;

		if(activate(THR_NEW_LWP | THR_JOINABLE | THR_INHERIT_SCHED))
		{
			APG_COMPONENT_LOG_ERRNO(errno, LOG_LEVEL_ERROR, "cannot start svc thread");
			APG_COMPONENT_TRACE_MESSAGE("ERROR: cannot start svc thread. errno: %d", errno);
			result = common::errorCode::ERR_SVC_ACTIVATE;
		}

		return result;
	}

	int Scheduler::start()
	{
		APG_COMPONENT_TRACE_FUNCTION;

		int result = common::errorCode::ERR_NO_ERRORS;

		if( thr_count() > 0U )
		{
			//ERROR CASE
			APG_COMPONENT_LOG(LOG_LEVEL_ERROR, "thread already running. thr_count(): %zu", thr_count());
			APG_COMPONENT_TRACE_MESSAGE("ERROR: thread already running. thr_count(): %zu", thr_count());
			result = common::errorCode::ERR_OPEN;
		}
		else
		{
			result = open();
		}

		return result;
	}

	int Scheduler::stop()
	{
		APG_COMPONENT_TRACE_FUNCTION;

		if (thr_count() > 0)
		{
			operation::Creator operationFactoryCreator;
			ACE_Method_Request* terminate = operationFactoryCreator.make(SHUTDOWN);
			int result = enqueue(terminate);
			APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Thread running, Shutdown request enqueue result:<%d>", result);
			APG_COMPONENT_TRACE_MESSAGE("Thread running, Shutdown request enqueue result:<%d>", result);
		}

		return wait();
	}
}
