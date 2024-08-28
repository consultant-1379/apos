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
#ifndef HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONSCHEDULER_H_
#define HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONSCHEDULER_H_
#include <boost/noncopyable.hpp>
#include <ace/Task.h>
#include <ace/Activation_Queue.h>

class ACE_Method_Request;

namespace operation
{
	/**
	 * @class Scheduler
	 *
	 * @brief A scheduler class derived from @c ACE_Task_Base.
	 *
	 * Maintains a priority-ordered queue of operation objects.
	 * Subsequently removes each operation request and invokes its @c call() method.
	 *
	 */
	class Scheduler : public ACE_Task_Base, private boost::noncopyable
	{
	 public:

		/// Constructor.
		inline Scheduler() : ACE_Task_Base(), m_ActivationQueue() {}

		/// Destructor.
		virtual ~Scheduler();

		/**
		 *	@brief	Scheduler function thread.
		 */
		virtual int svc(void);

		/**
		 * @brief	Activates the scheduler thread.
		*/
		virtual int open(void *args = 0);

		/**
		 *	@brief	Initializes the scheduler task and prepare it to run as thread.
		 */
		virtual int start();

		/**
		 * @brief	Enqueues a @a Shutdown operation into the scheduler and
		 * waits the thread termination.
		 */
		virtual int stop();

		/**
		 * @brief	This method enqueue a command in the queue
		 */
		inline int enqueue(ACE_Method_Request* cmdRequest)
		{
			return m_ActivationQueue.enqueue(cmdRequest);
		}

	 private:

		/**
		 * @brief	Queue of operation to execute.
		 *
		 * @sa ACE_Activation_Queue.
		 */
		ACE_Activation_Queue m_ActivationQueue;

	};
}

#endif // HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONSCHEDULER_H_
