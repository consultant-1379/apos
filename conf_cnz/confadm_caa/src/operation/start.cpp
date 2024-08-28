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

#include "operation/start.h"

#include "common/programconstants.h"

#include <boost/make_shared.hpp>

#include "engine/workingset.h"
#include "common/tracer.h"
#include "common/logger.h"

APG_COMPONENT_TRACE_DEFINE(Operation_Start)

namespace operation
{

    Start::Start()
    : OperationBase(START)
    {
        APG_COMPONENT_TRACE_FUNCTION;
    }

    int Start::call()
    {
        APG_COMPONENT_TRACE_FUNCTION;
        APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Start ongoing");

        /**
         * Initialize external libraries here. For example:
         *      - libssh2
         *      - curl
         *      - Configure OpenSSL Threading
         *      - ...
         */

        /**
         * Load Managed Objects data from IMM.
         */

    	/**
    	 * Set any strategy and configuration related variable in your daemon.
    	 */

        /**
         * Register Object Implementers
         */

        /**
         * Start Implementers and needed service threads
         */

        APG_COMPONENT_LOG(LOG_LEVEL_INFO, "Start executed");
        return common::errorCode::ERR_NO_ERRORS;
    }
} /* namespace operation */
