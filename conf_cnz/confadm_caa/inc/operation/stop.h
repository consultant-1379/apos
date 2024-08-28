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
#ifndef HEADER_GUARD_CLASS_APG_OPERATION_STOP_H_
#define HEADER_GUARD_CLASS_APG_OPERATION_STOP_H_

#include "operation/operationbase.h"

namespace operation
{
	/**
	 * @class Stop
	 *
	 * @brief Deactivate operation request.
	 *
	 * @sa OperationBase
	 */
	class Stop : public OperationBase
	{
	 public:

		/// Constructor.
		Stop();

		/// Destructor.
		inline virtual ~Stop() { }

		/**
		 * @brief  Implementation of the operation.
		 */
		virtual int call();
	};

} /* namespace operation */

#endif // HEADER_GUARD_CLASS_APG_OPERATION_STOP_H_
