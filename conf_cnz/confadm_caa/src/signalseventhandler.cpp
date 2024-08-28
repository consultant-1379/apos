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

#include "signalseventhandler.h"
#include "engine/workingset.h"
#include "common/tracer.h"
#include "common/logger.h"
#include "common/programconstants.h"
#include "operation/creator.h"


APG_COMPONENT_TRACE_DEFINE(SignalsEventHandler)


int SignalsEventHandler::handle_signal(int signum, siginfo_t * /*siginfo*/, ucontext_t * /*context*/)
{
	if( ( SIGINT == signum ) || ( SIGTERM == signum) )
	{
		// Catch termination signals only
		if( engine::workingSet_t::instance()->isDebugModeOn() )
		{
			// server started from shell in debug mode
			APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Signal handler: ending the main reactor event loop...");
			//engine::workingSet_t::instance()->stopMainReactor();
			// Simulate HA deactivate
			operation::Creator operationFactoryCreator;
			operationFactoryCreator.schedule(operation::SHUTDOWN);
		}
		else
		{
			// server started by CoreMW in HA mode
			// The server was started by CoreMW cluster. Cluster commands should be used to stop the server.
			APG_COMPONENT_LOG(LOG_LEVEL_WARN, "Signal handler: server started by CoreMW in HA mode so SIGINT and SIGTERM signals are ignored! You must use CoreMW (AMF) application management commands");
		}
	}
	else
	{
		// SIGPIPE
		APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Signal handler: signal [<%d>,<%s>] ignored", signum, ::strsignal(signum) );
	}

	return common::errorCode::ERR_NO_ERRORS;
}

