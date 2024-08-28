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
#ifndef HEADER_GUARD_CLASS_APG_COMPONENT_MACROS_H_
#define HEADER_GUARD_CLASS_APG_COMPONENT_MACROS_H_

#ifndef APG_COMPONENT_ARRAY_SIZE
#	define APG_COMPONENT_ARRAY_SIZE(array) (sizeof(array)/sizeof(*(array)))
#endif

// To avoid warning about unused parameter
#define UNUSED(expr) do { (void)(expr); } while (0)

#endif // HEADER_GUARD_CLASS_APG_COMPONENT_MACROS_H_

