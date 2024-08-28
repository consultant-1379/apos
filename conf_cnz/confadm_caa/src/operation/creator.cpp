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

#include "operation/creator.h"
#include "operation/noop.h"
#include "operation/start.h"
#include "operation/stop.h"
#include "operation/shutdown.h"

#include "common/programconstants.h"

#include <ace/Method_Request.h>
#include "engine/workingset.h"
#include "common/tracer.h"
#include "common/logger.h"
#include "common/macros.h"


APG_COMPONENT_TRACE_DEFINE(Operation_Creator)

namespace operation {

	int Creator::schedule(const operation::identifier_t id)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		int result = common::errorCode::ERR_NO_ERRORS;

		OperationBase* operation = make(id);

		if( operation )
		{
			result = engine::workingSet_t::instance()->getScheduler().enqueue(operation);
		}
		else
		{
			APG_COMPONENT_LOG_ERRNO(errno, LOG_LEVEL_ERROR, "cannot allocate new operation:<%d> request", id);
			APG_COMPONENT_TRACE_MESSAGE("ERROR: cannot allocate new operation:<%d> request. errno:<%d>", id, errno);
			result = common::errorCode::ERR_MEMORY_BAD_ALLOC;
		}

		return result;
	}

	int Creator::schedule(const operation::identifier_t id, const void* op_details)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		int result = common::errorCode::ERR_NO_ERRORS;

		OperationBase* operation = make(id);

		if( operation )
		{
			operation->setOperationDetails(op_details);

			result = engine::workingSet_t::instance()->getScheduler().enqueue(operation);
		}
		else
		{
			APG_COMPONENT_LOG_ERRNO(errno, LOG_LEVEL_ERROR, "cannot allocate new operation:<%d> request", id);
			APG_COMPONENT_TRACE_MESSAGE("ERROR: cannot allocate new operation:<%d> request. errno:<%d>", id, errno);
			result = common::errorCode::ERR_MEMORY_BAD_ALLOC;
		}

		return result;
		}

	int Creator::schedule(const operation::identifier_t id, ACE_Future<operation::result>* op_result, const void* op_details)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		int result = common::errorCode::ERR_NO_ERRORS;

		OperationBase* operation = make(id);

		if( operation )
		{
			operation->setOperationResultRequest(op_result);
			operation->setOperationDetails(op_details);

			result = engine::workingSet_t::instance()->getScheduler().enqueue(operation);
		}
		else
		{
			APG_COMPONENT_LOG_ERRNO(errno, LOG_LEVEL_ERROR, "cannot allocate new operation:<%d> request", id);
			APG_COMPONENT_TRACE_MESSAGE("ERROR: cannot allocate new operation:<%d> request. errno:<%d>", id, errno);
			result = common::errorCode::ERR_MEMORY_BAD_ALLOC;
		}

		return result;
	}

	OperationBase* Creator::make(const operation::identifier_t id)
	{
		APG_COMPONENT_TRACE_FUNCTION;
		OperationBase* operation;

		switch(id)
		{
			case START:
			{
				operation = new (std::nothrow) Start();
			}
			break;

			case STOP:
			{
				operation = new (std::nothrow) Stop();
			}
			break;

			case SHUTDOWN:
			{
				operation = new (std::nothrow) Shutdown();
			}
			break;

			default:
			{
				operation = new (std::nothrow) NoOp();
			}
		}

		return operation;

	}


} /* namespace operation */

