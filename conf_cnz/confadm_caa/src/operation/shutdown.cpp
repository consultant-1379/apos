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
#include "operation/shutdown.h"
#include "common/programconstants.h"

#include "engine/workingset.h"
#include "common/tracer.h"
#include "common/logger.h"

APG_COMPONENT_TRACE_DEFINE(Operation_Shutdown)

namespace operation
{

	Shutdown::Shutdown()
	: OperationBase(SHUTDOWN)
	{
		APG_COMPONENT_TRACE_FUNCTION;
	}

	int Shutdown::call()
	{
		APG_COMPONENT_TRACE_FUNCTION;
		APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Shutdown ongoing");

		engine::workingSet_t::instance()->stopMainReactor();

		APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Shutdown executed");
		return common::errorCode::ERR_SVC_DEACTIVATE;
	}

} /* namespace operation */
