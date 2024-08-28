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
#ifndef HEADER_GUARD_CLASS_APG_COMPONENT_CONSTANTS_H_
#define HEADER_GUARD_CLASS_APG_COMPONENT_CONSTANTS_H_
#include <string>
#include <stdint.h>

namespace common {

	/** @brief Server program codes and enumerations.
	 *
	 */
#define APG_PROGRAM_RETURN_CODE_CONSTANTS_BASE 0

	/**
	 * @brief
	 * This enumeration specifies various program return code constants
	 */
	enum ProgramReturnCodeConstants {
		PROGRAM_EXIT_OK = APG_PROGRAM_RETURN_CODE_CONSTANTS_BASE,
		PROGRAM_EXIT_ANOTHER_SERVER_RUNNING,
		PROGRAM_EXIT_BAD_INVOCATION,
		PROGRAM_EXIT_LOCK_FILE_OPEN_ERROR,
		PROGRAM_EXIT_LOCK_FILE_LOCKING_ERROR,
		PROGRAM_EXIT_MEMORY_ALLOCATION_ERROR
	};

	namespace errorCode
	{
		/**
		 * @brief
		 * This enumeration specifies various error constants
		 */
		enum ErrorConstants
		{
			ERR_API_CALL	= -1,
			ERR_NO_ERRORS	= 0,

			//Basic Erroc Codes
			ERR_GENERIC,
			ERR_OPEN,
			ERR_WRITE,
			ERR_CLOSE,
			ERR_SVC_ACTIVATE,
			ERR_SVC_DEACTIVATE,
			ERR_MEMORY_BAD_ALLOC,
			ERR_REACTOR_HANDLER_REGISTER_FAILURE,
			ERR_REACTOR_HANDLER_REMOVE_FAILURE

			// Add here new error codes

		};
	}

	namespace event
	{
		const int INVALID = -1;
		const unsigned int INITIAL_VALUE = 0U;
		const int FLAGS = 0U; //In Linux up to version 2.6.26, the flags argument is unused, and must be specified as zero
	}

	namespace handle
	{
		const int INVALID = -1;
	}

}

#endif // HEADER_GUARD_CLASS_APG_COMPONENT_CONSTANTS_H_
