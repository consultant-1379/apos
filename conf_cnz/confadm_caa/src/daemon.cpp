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
#include "daemon.h"

#include "haimplementer.h"
#include "engine/workingset.h"
#include "operation/creator.h"

#include "common/tracer.h"
#include "common/logger.h"
#include "common/programconstants.h"

#include <sys/file.h>
#include <sys/types.h>
#include <sys/capability.h>

#include <iostream>

APG_COMPONENT_TRACE_DEFINE(Daemon)

int Daemon::m_systemSignalsToCatch[] = { SIGHUP, SIGINT, SIGTERM };

Daemon::Daemon(std::string ha_daemon_name_value, std::string logger_appender_name_value, std::string server_lock_file_path_value)
:ACE_Task_Base(),
 m_signalHandler(),
 m_SignalsToCatch(),
 m_ha_daemon_name(ha_daemon_name_value),
 m_logger_appender_name(logger_appender_name_value),
 m_server_lock_file_path(server_lock_file_path_value)
{

}

int Daemon::svc(void)
{
	APG_COMPONENT_TRACE_FUNCTION;
	APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Daemon Task is running and it is starting the main reactor.");

	//Run reactor
	if (engine::workingSet_t::instance()->getMainReactor().run_reactor_event_loop() == -1)
	{
		//Log error
		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "Error while starting the main reactor");
	}

	APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Daemon Task is terminated");
	return common::errorCode::ERR_NO_ERRORS;
}


int Daemon::work(const int& debug_mode)
{
	APG_COMPONENT_TRACE_FUNCTION;

	APG_COMPONENT_SYSLOG(LOG_DEBUG, LOG_LEVEL_DEBUG,
			"Started AMF Dummy Server [ha_daemon_name: <%s>, logger_name: <%s>, lock_file: <%s>]\n",
			m_ha_daemon_name.c_str(),
			m_logger_appender_name.c_str(),
			m_server_lock_file_path.c_str());

	int result = common::errorCode::ERR_NO_ERRORS;

	if(debug_mode)
	{
		// Check for multiple program instances running
		if ( (result = multiple_process_instance_running_check()) ) return result;

		engine::workingSet_t::instance()->setDebugModeOn();

		//Ignore SIGPIPE
		sigignore(SIGPIPE);

		//Start Server in debug mode
		result = debug();

	}
	else
	{
		pid_t parent_pid = ::getpid();

		// Demonize the server and prepare to register with AMF
		HaImplementer haImplementer(m_ha_daemon_name.c_str());

		//Ignore SIGPIPE
		sigignore(SIGPIPE);

		checkDemonizeResult(parent_pid);

		engine::workingSet_t::instance()->setDebugModeOff();

		if(set_process_capability())
		{
			APG_COMPONENT_TRACE_MESSAGE("Error while setting process capabilities. errno: %d", errno);
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "Error while setting process capabilities");
		}

		// Initialize the server logger
		// Do this only after the process has been demonized by HaImplementer!!
		apg_component_logger::open(m_logger_appender_name.c_str());

		//Initialize Operation Scheduler
		if(engine::workingSet_t::instance()->startScheduler() != common::errorCode::ERR_NO_ERRORS)
		{
			APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot initialize the Operation Scheduler");
			APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot initialize the Operation Scheduler");
		}

		// Activate this server work task with the minimum number of thread running
		if(activate(THR_NEW_LWP | THR_JOINABLE | THR_INHERIT_SCHED) != common::errorCode::ERR_NO_ERRORS)
		{
			// ERROR: activating this main task
			APG_COMPONENT_LOG_ERRNO(errno, LOG_LEVEL_FATAL, "Call 'activate' failed: cannot activate the daemon worker thread");
			APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Call 'activate' failed: cannot activate the daemon worker thread");
		}
		else
		{
			//Just log the task activation
			APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Daemon Task started!");
			APG_COMPONENT_TRACE_MESSAGE("Daemon Task started!");
		}

		//Initialize signal handler
		if(init_signals_handler() != common::errorCode::ERR_NO_ERRORS)
		{
			APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot initialize the signal handler");
			APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot initialize the signal handler");
		}
		else
		{
			APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Signal handler initialized by main thread.");
			APG_COMPONENT_TRACE_MESSAGE("Signal handler initialized by main thread.");
		}

		//activate HA APP MANAGER to bind to the AMF framework
		APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Activating HA Implementer...");
		printWelcomeMessage();

		ACS_APGCC_HA_ReturnType ha_call_result = haImplementer.activate();

		logHAExitCode(ha_call_result);

		//remove signal handler
		if(reset_signals_handler() != common::errorCode::ERR_NO_ERRORS)
		{
			APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot remove the signal handler");
			APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot remove the signal handler");
		}

		//Stop Scheduler
		if(engine::workingSet_t::instance()->stopScheduler() != common::errorCode::ERR_NO_ERRORS)
		{
			APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot stop the operation scheduler thread");
			APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot stop the operation scheduler thread");
		}

		// wait svc thread termination
		wait();
	}

	apg_component_logger::close();
	return result;
}

int Daemon::debug ()
{
	APG_COMPONENT_TRACE_FUNCTION;

	int call_result = common::errorCode::ERR_NO_ERRORS;

	if (set_process_capability())
	{
		APG_COMPONENT_TRACE_MESSAGE("Error while setting process capabilities. errno: %d", errno);
		APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "Error while setting process capabilities for %s. errno: %d", m_ha_daemon_name.c_str(), errno);
	}

	// Initialize the server logger
	apg_component_logger::open(m_logger_appender_name.c_str());

	printWelcomeMessage();

	//Initialize Operation Scheduler
	if (engine::workingSet_t::instance()->startScheduler() != common::errorCode::ERR_NO_ERRORS)
	{
		APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot initialize the Operation Scheduler thread");
		APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot initialize the Operation Scheduler thread");
	}

	//Initialize signal handler
	if( init_signals_handler() != common::errorCode::ERR_NO_ERRORS)
	{
		APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot initialize the signal handler");
		APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot initialize the signal handler");
	}

	// Simulate HA activate
	{
		operation::Creator operationFactoryCreator;
		operationFactoryCreator.schedule(operation::START);
	}

	//Run reactor
	if (engine::workingSet_t::instance()->getMainReactor().run_reactor_event_loop() == -1)
	{
		//Log error
		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "Error while starting the main reactor");
	}

	// Simulate HA deactivate
	{
		operation::Creator operationFactoryCreator;
		operationFactoryCreator.schedule(operation::STOP);
	}

	//remove signal handler
	if( reset_signals_handler() != common::errorCode::ERR_NO_ERRORS)
	{
		APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot remove the signal handler");
		APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot remove the signal handler");
	}

	//Stop Scheduler
	if (engine::workingSet_t::instance()->stopScheduler() != common::errorCode::ERR_NO_ERRORS)
	{
		APG_COMPONENT_LOG(LOG_LEVEL_FATAL, "Daemon cannot stop the operation scheduler thread");
		APG_COMPONENT_TRACE_MESSAGE("FATAL ERROR: Daemon cannot stop the operation scheduler thread");
	}

	return call_result;
}


int Daemon::multiple_process_instance_running_check () {
	APG_COMPONENT_TRACE_FUNCTION;

	// Multiple server instance check: if there is another server instance
	// already running then exit immediately

	int lock_fd = ::open(m_server_lock_file_path.c_str(), O_CREAT | O_WRONLY | O_APPEND, 0664);
	if (lock_fd < 0)
	{
		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "multiple_process_instance_running_check failed: file system error");
		return common::PROGRAM_EXIT_LOCK_FILE_OPEN_ERROR;
	}
	errno = 0;
	if (::flock(lock_fd, LOCK_EX | LOCK_NB) < 0)
	{
		int errno_save = errno;
		if (errno_save == EWOULDBLOCK)
		{
			::fprintf(::stderr, "Another Server instance running\n");
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "Another Server instance running");
			return common::PROGRAM_EXIT_ANOTHER_SERVER_RUNNING;
		}

		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "multiple_process_instance_running_check failed. Error locking file");
		return common::PROGRAM_EXIT_LOCK_FILE_LOCKING_ERROR;
	}

	return common::errorCode::ERR_NO_ERRORS;
}

int Daemon::set_process_capability()
{
	// Clear CAP_SYS_RESOURCE bit thus root user cannot override disk quota limits
	int retStatus = 0;
	cap_t cap = cap_get_proc();
	if(NULL != cap)
	{
		cap_value_t cap_list[] = {CAP_SYS_RESOURCE};
		size_t NumberOfCap = sizeof(cap_list)/sizeof(cap_list[0]);

		// Clear capability CAP_SYS_RESOURCE
		if(cap_set_flag(cap, CAP_EFFECTIVE, NumberOfCap, cap_list, CAP_CLEAR) == -1)
		{
			// handle error
			char err_buff[128] = {0};
			snprintf(err_buff, sizeof(err_buff) - 1, "%s, cap_set_flag() failed, error=%s", __func__, strerror(errno) );
			retStatus = -1;
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "%s", err_buff);

		}
		if (cap_set_flag(cap, CAP_INHERITABLE, NumberOfCap, cap_list, CAP_CLEAR) == -1)
		{
			// handle error
			char err_buff[128] = { 0 };
			snprintf(err_buff, sizeof(err_buff) - 1, "%s, cap_set_flag() failed, error=%s", __func__, strerror(errno));
			retStatus = -1;
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "%s", err_buff);

		}
		// Change process capability
		if (cap_set_proc(cap) == -1)
		{
			// handle error
			char err_buff[128] = {0};
			snprintf(err_buff, sizeof(err_buff) - 1, "%s, cap_set_proc() failed, error=%s", __func__, strerror(errno) );
			retStatus = -1;
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "%s", err_buff);
		}

		if(cap_free(cap) == -1)
		{
			// handle error
			char err_buff[128] = {0};
			snprintf(err_buff, sizeof(err_buff) - 1, "%s, cap_free() failed, error=%s", __func__, strerror(errno) );
			retStatus = -1;
			APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "%s", err_buff);
		}
	}
	else
	{
		// handle error
		char err_buff[128] = {0};
		snprintf(err_buff, sizeof(err_buff)-1, "%s, cap_get_proc() failed, error=%s", __func__, strerror(errno) );
		retStatus = -1;
		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "%s", err_buff);
	}

	APG_COMPONENT_SYSLOG(LOG_INFO, LOG_LEVEL_INFO, "Capabilities modification status: %s", (retStatus == 0 ? "DONE" : "ERROR"));

	return retStatus;
}

int Daemon::init_signals_handler()
{
	APG_COMPONENT_TRACE_FUNCTION;

	int result = common::errorCode::ERR_NO_ERRORS;

	// Adding the process signal handler for the signals DDT server has to catch
	for(size_t signalIndex = 0U; signalIndex < APG_COMPONENT_ARRAY_SIZE(m_systemSignalsToCatch); ++signalIndex)
	{
		int signal = m_systemSignalsToCatch[signalIndex];

		// Try to add the process signal handler for signal
		if(!m_SignalsToCatch.is_member(signal))
		{
			APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Process signal handling: adding the handler for the signal: [ <%d>, <%s>]", signal, ::strsignal(signal));

			// signal not present, adding it
			if( engine::workingSet_t::instance()->getMainReactor().register_handler(signal, &m_signalHandler) < 0)
			{
				//ERROR: adding the signal handler
				result = common::errorCode::ERR_REACTOR_HANDLER_REGISTER_FAILURE;
				APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "Process signal handling: call 'register_handler' failed: cannot register the handler for the signal: [<%d>, <%s>]", signal, ::strsignal(signal));
			}
			else
			{
				//OK: remember this signal was added.
				m_SignalsToCatch.sig_add(signal);
			}
		}
	}

	return result;
}

int Daemon::reset_signals_handler()
{
	APG_COMPONENT_TRACE_FUNCTION;

	int result = common::errorCode::ERR_NO_ERRORS;

	// Removing the process signal handling
	for( size_t signalIndex = 0U; signalIndex < APG_COMPONENT_ARRAY_SIZE(m_systemSignalsToCatch); ++signalIndex )
	{
		int signal = m_systemSignalsToCatch[signalIndex];

		// Try to remove the process signal handler for signal
		if( m_SignalsToCatch.is_member(signal) )
		{
			APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Process signal handling: removing the handler for the signal: [<%d>, <%s>]", signal, ::strsignal(signal));

			// signal present, removing it
			if( engine::workingSet_t::instance()->getMainReactor().remove_handler(signal, reinterpret_cast<ACE_Sig_Action *>(0)) < 0 )
			{
				//ERROR: removing the signal handler
				result = common::errorCode::ERR_REACTOR_HANDLER_REMOVE_FAILURE;
				APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_ERR, LOG_LEVEL_ERROR, "PProcess signal handling: call 'remove_handler' failed: cannot remove the handler for the signal: [<%d>, <%s>]", signal, ::strsignal(signal));
			}
			else
			{
				//OK: remember this signal was removed.
				m_SignalsToCatch.sig_del(signal);
			}
		}
	}

	return result;
}

void Daemon::checkDemonizeResult(const pid_t& parent_pid)
{
	APG_COMPONENT_TRACE_FUNCTION;
	pid_t child_pid = ::getpid();

	if (parent_pid != child_pid )
	{
		// OK: server successfully demonized
		APG_COMPONENT_TRACE_MESSAGE(
					"server successfuly demonized: new child PID == %d",
					child_pid);
	}
	else
	{
		// ERROR: server was not demonized
		APG_COMPONENT_SYSLOG_ERRNO(errno, LOG_WARNING, LOG_LEVEL_WARN,
				"Server was not demonized correctly: child process was aborted on creation: the parent process (PID == %d) continues taking the control",
				parent_pid);

		APG_COMPONENT_TRACE_MESSAGE(
				"Server was not demonized correctly: child process was aborted on creation: the parent process (PID == %d) continues taking the control",
				parent_pid);
	}
}


void Daemon::logHAExitCode(int ha_result)
{
	APG_COMPONENT_TRACE_FUNCTION;

	switch (ha_result)
	{
		case ACS_APGCC_HA_SUCCESS:
			APG_COMPONENT_SYSLOG(LOG_DEBUG, LOG_LEVEL_DEBUG, "HA Application Gracefully closing...");
			break;
		case ACS_APGCC_HA_FAILURE:
			APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "HA Activation Failed: ha_call_result == %d", ha_result);
			break;
		case ACS_APGCC_HA_FAILURE_CLOSE:
			APG_COMPONENT_SYSLOG(LOG_ERR, LOG_LEVEL_ERROR, "HA Application Failed to Gracefully closing: ha_call_result == %d", ha_result);
			break;
		default:
			APG_COMPONENT_SYSLOG(LOG_WARNING, LOG_LEVEL_WARN, "HA Application error code unknown: ha_call_result == %d", ha_result);
			break;
	}

	APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "HA Implementer STOPPED!!! ha_call_result = <%d>", ha_result);
}

void Daemon::printWelcomeMessage()
{
	APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "\n\n"
				"==========================================================\n"
				"=     DUMMY SERVER RUNNING ON THIS NODE CONFIGURATION    =\n"
				"==========================================================\n"
				"=         ,__o                                           =\n"
				"=         _-\\_<,                                         =\n"
				"=    ....(*)/'(*)....                                    =\n"
				"==========================================================\n"
				"=          Waiting for HA callbacks only...              =\n"
				"==========================================================\n");

	std::cout << std::endl;
	std::cout << "        ,__o" << std::endl;
	std::cout << "       _-\\_<," << std::endl;
	std::cout << "      (*)/'(*)" << std::endl;
	std::cout << std::endl;

	APG_COMPONENT_LOG(LOG_LEVEL_DEBUG, "Daemon Passivated:\n"
			"    ha_daemon_name: <%s>\n"
			"    logger_name: <%s>\n"
			"    lock_file: <%s>\n",
			m_ha_daemon_name.c_str(),
			m_logger_appender_name.c_str(),
			m_server_lock_file_path.c_str());

	std::cout << "Daemon Passivated:" << std::endl;
	std::cout << "      ha_daemon_name: " << m_ha_daemon_name << std::endl;
	std::cout << "      logger_name:" << m_logger_appender_name << std::endl;
	std::cout << "      lock_file:" << m_server_lock_file_path << std::endl;

}

