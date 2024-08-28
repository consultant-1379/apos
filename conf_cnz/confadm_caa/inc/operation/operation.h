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

#ifndef HEADER_GUARD_CLASS_APG_OPERATION_OPERATION_H_
#define HEADER_GUARD_CLASS_APG_OPERATION_OPERATION_H_

#include "common/programconstants.h"

#include <string>
#include <stdint.h>

namespace operation
{

	/// Operation Identifiers
	enum identifier_t {
		NOOP,
		START,  ///< Activate
		STOP,	///< Deactivate
		SHUTDOWN,	///< Terminate
	};

	// Operation result
	struct result
	{
		int errorCode;
		std::string errorMessage;

		result(): errorCode(common::errorCode::ERR_NO_ERRORS), errorMessage() {}

		void set(const int& errorValue, const std::string& errMsg)
		{
			errorCode = errorValue;
			errorMessage.assign(errMsg);
		}

		const char* getErrorMessage() const { return errorMessage.c_str(); }

		int getErrorCode() const { return errorCode; }

		void setErrorCode(const int& errCode) {  errorCode = errCode; }

		bool good() { return (common::errorCode::ERR_NO_ERRORS == errorCode); }

		bool fail() { return (common::errorCode::ERR_NO_ERRORS != errorCode); }
	};

}


#endif // HEADER_GUARD_CLASS_APG_OPERATION_OPERATION_H_
