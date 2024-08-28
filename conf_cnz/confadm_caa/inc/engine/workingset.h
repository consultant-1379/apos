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
#ifndef HEADER_GUARD_CLASS_APG_COMPONENT_WORKINGSET_H_
#define HEADER_GUARD_CLASS_APG_COMPONENT_WORKINGSET_H_

#include "operation/scheduler.h"

#include <ace/TP_Reactor.h>
#include <ace/Reactor.h>
#include <ace/Singleton.h>
#include <ace/Synch.h>
#include <ace/RW_Thread_Mutex.h>

namespace engine
{

	class WorkingSet
	{
	 public:

		friend class ACE_Singleton<WorkingSet, ACE_Recursive_Thread_Mutex>;

		/**	@brief
		 *
		 *	This method gets the scheduler associated with working set.
		 *
		 *	@return scheduler.
		 *
		 *	@remarks Remarks
		 */
		inline operation::Scheduler& getScheduler()  { return m_scheduler; };

		/**	@brief
		 *
		 *	This method starts the scheduler.
		 *
		 *	@return zero on success, otherwise non zero value.
		 *
		 *	@remarks Remarks
		 */
		inline int startScheduler() { return m_scheduler.start(); };

		/**	@brief
		 *
		 *	This method stops the scheduler.
		 *
		 *	@return zero on success, otherwise non zero value.
		 *
		 *	@remarks Remarks
		 */
		inline int stopScheduler() { return m_scheduler.stop(); };

		/**	@brief
		 *
		 *	This method gets the main reactor.
		 *
		 *	@return reactor.
		 *
		 *	@remarks Remarks
		 */
		inline ACE_Reactor& getMainReactor()  { return m_reactor; };

		/**	@brief
		 *
		 *	This method stops the main reactor.
		 *
		 *	@return zero on success, otherwise non zero value.
		 *
		 *	@remarks Remarks
		 */
		inline int stopMainReactor() { return m_reactor.end_reactor_event_loop(); };

		/**	@brief
		 *
		 *	This method checks debug mode is on or not.
		 *
		 *	@return true if debug mode is on, otherwise false.
		 *
		 *	@remarks Remarks
		 */
		inline bool isDebugModeOn() const { return m_debugMode; };

		/**	@brief
		 *
		 *	This method sets debug mode is on.
		 *
		 *	@return none.
		 *
		 *	@remarks Remarks
		 */
		inline void setDebugModeOn() {m_debugMode = true; };

		/**	@brief
		 *
		 *	This method sets debug mode is off.
		 *
		 *	@return none.
		 *
		 *	@remarks Remarks
		 */
		inline void setDebugModeOff() {m_debugMode = false; };

	 private:

		/// Constructor.
		WorkingSet();

		/// Destructor.
		virtual ~WorkingSet();

		// INHIBIT COPY CONTRUCTOR
		WorkingSet(const WorkingSet& rhs);

		// INHIBIT ASSIGNMENT OPERATOR
		WorkingSet& operator=(const WorkingSet& rhs);


	 private:

		/// debug mode
		bool m_debugMode;

		/// Scheduler
		operation::Scheduler m_scheduler;

		/// TP Reactor
		ACE_TP_Reactor m_reactorImpl;

		/// Reactor
		ACE_Reactor	m_reactor;

	};

	typedef ACE_Singleton< WorkingSet, ACE_Recursive_Thread_Mutex> workingSet_t;
} /* namespace operation */



#endif // HEADER_GUARD_CLASS_APG_COMPONENT_WORKINGSET_H_
