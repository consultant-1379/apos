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
#ifndef HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONBASE_H_
#define HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONBASE_H_

#include "operation/operation.h"
#include <boost/noncopyable.hpp>
#include <ace/Method_Request.h>
#include <ace/Future.h>

#include  "common/macros.h"

namespace operation
{
	/**
	 * @class OperationBase
	 *
	 * @brief
	 * Base class of operation requests.
	 *
	 * @sa ACE_Method_Request
	 */

	class OperationBase : public ACE_Method_Request, private boost::noncopyable
	{
	 public:

		///  Constructor.
		OperationBase(operation::identifier_t type) : ACE_Method_Request(), m_type(type), m_operationResult(), m_result(NULL) {};

		/// Destructor.
		virtual ~OperationBase() {};

		/**
		 * @brief Set an operation result request.
		 *
		 * @param  op_result Operation result.
		 */
		virtual void setOperationResultRequest(ACE_Future<operation::result>* op_result) { m_result = op_result; };

		/**
		 * @brief Set an operation info details.
		 *
		 * @param  op_details Operation details.
		 */
		virtual void setOperationDetails(const void* op_details) { UNUSED(op_details);};

		/**
		 * @brief Get the operation type
		 *
		 * @param  result Operation result.
		 */
		operation::identifier_t getType() const { return m_type; };

	 protected:

		inline void setResultToCaller() { if(m_result) m_result->set(m_operationResult); };

		/// Operation type
		operation::identifier_t m_type;

		/// Operation result
		operation::result m_operationResult;

	 private:

		/// Operation result caller callback
		ACE_Future<operation::result>* m_result;

	};

} /* namespace operation */

#endif // HEADER_GUARD_CLASS_APG_OPERATION_OPERATIONBASE_H_
