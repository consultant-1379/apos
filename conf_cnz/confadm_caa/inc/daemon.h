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
#ifndef HEADER_GUARD_CLASS_APG_COMPONENT_DAEMON_H_
#define HEADER_GUARD_CLASS_APG_COMPONENT_DAEMON_H_

#include "signalseventhandler.h"

#include <ace/Signal.h>
#include <ace/Task.h>

class Daemon : public ACE_Task_Base
{

 public:

	//==============//
	// Constructors //
	//==============//
	Daemon(std::string ha_daemon_name_value, std::string logger_appender_name_value, std::string server_lock_file_path_value);

	//============//
	// Destructor //
	//============//
	inline virtual ~Daemon() {}

	//===========//
	// Functions //
	//===========//

	/**
	   @brief	Run by the daemon thread
	 */
	virtual int svc(void);

	int work(const int& debug_mode);
	int debug();

 private:

	int multiple_process_instance_running_check();
	int set_process_capability();

	int init_signals_handler();
	int reset_signals_handler();

	void checkDemonizeResult(const pid_t& parent_pid);
	void logHAExitCode(int ha_result);

	// Disallow these operations.
	Daemon(const Daemon & rhs);
	Daemon & operator= (const Daemon & rhs);

	void printWelcomeMessage();
	//========//
	// Fields //
	//========//
 private:

	SignalsEventHandler m_signalHandler;
	ACE_Sig_Set m_SignalsToCatch;
	static int m_systemSignalsToCatch[];

	std::string m_ha_daemon_name;
	std::string m_logger_appender_name;
	std::string m_server_lock_file_path;
};

#endif // HEADER_GUARD_CLASS_APG_COMPONENT_DAEMON_H_
