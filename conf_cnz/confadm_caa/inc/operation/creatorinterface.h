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
#ifndef HEADER_GUARD_CLASS_APG_OPERATION_CREATORINTERFACE_H_
#define HEADER_GUARD_CLASS_APG_OPERATION_CREATORINTERFACE_H_
#include <boost/noncopyable.hpp>
#include "operation/operation.h"

#include <ace/Future.h>

namespace operation {

	class OperationBase;

	/**
	 * @class CreatorInterface
	 *
	 * @brief Provides an abstract interface of a factory class of operation requests.
	 *
	 * @sa Creator
	 */
	class CreatorInterface :  private boost::noncopyable
	{
	 public:

		/// Constructor.
		CreatorInterface() {};

		/// Destructor.
		virtual ~CreatorInterface() { }

		/**
		 * @brief Schedule execution of an operation
		 *
		 * @param  id Operation identifier.
		 *
		 */
		virtual int schedule(const operation::identifier_t id) = 0;

		/**
		 * @brief Schedule execution of an operation.
		 *
		 * The specified operation is created and queued into the operation scheduler queue.
		 *
		 * @param  id Operation identifier
		 *
		 * @param  op_details Operation details
		 *
		 * @retval >0 The number of operation requests on the queue after adding
		 *            the specified request.
		 * @retval -1 if an error occurs; errno contains further information.
		 */
		virtual int schedule(const operation::identifier_t id, const void* op_details) = 0;

		/**
		 * @brief Schedule execution of an operation and orders result request
		 *
		 * @param  id Operation identifier.
		 *
		 * @param  op_result Operation result.
		 *
		 * @param  op_details Operation details.
		 *
		 */
		virtual int schedule(const operation::identifier_t id, ACE_Future<operation::result>* op_result, const void* op_details) = 0;

	 protected:

		/**
		 * @brief Create an operation object
		 *
		 * @param  id Identifier of the operation
		 *
		 * @retval Pointer to the created operation object.
		 *
		 */
		virtual  OperationBase* make(const operation::identifier_t id) = 0;

	};

}

#endif // HEADER_GUARD_CLASS_APG_OPERATION_CREATORINTERFACE_H_
