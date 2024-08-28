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
#include "operation/stop.h"

#include "common/programconstants.h"

#include "engine/workingset.h"
#include "common/tracer.h"
#include "common/logger.h"

APG_COMPONENT_TRACE_DEFINE(Operation_Stop)

namespace operation
{
	Stop::Stop()
	: OperationBase(STOP)
	{
		APG_COMPONENT_TRACE_FUNCTION;
	}

	int Stop::call()
	{
		APG_COMPONENT_TRACE_FUNCTION;
		APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Stop ongoing");

		/**
		 * Unregister Object Implementers
		 */

		/**
		 * Stop implementers and service threads
		 */

		/**
		 * Shutdown resources
		 */

		/**
		 * Cease All alarms
		 */

		/**
		 * Clanup and uninitialize libraries here. For example:
		 *      - Clueanup OpenSSL multithreading settings
		 *      - Exit libssh2 functions and free internal memory
		 *      - Cleanup libcurl internal memory
		 *      - ...
		 *
		 */

		APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Stop executed");
		return common::errorCode::ERR_NO_ERRORS;
	}

} /* namespace operation */
