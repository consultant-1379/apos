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
#ifndef HEADER_GUARD_CLASS_APG_COMPONENT_HA_APP_MANAGER_H_
#define HEADER_GUARD_CLASS_APG_COMPONENT_HA_APP_MANAGER_H_

#include "operation/creator.h"

#include <ACS_APGCC_ApplicationManager.h>


/**
 * @class HaImplementer
 *
 * @brief Implementation of abstract interface @c ACS_APGCC_ApplicationManager.
 *
 * Implements the callbacks to interacts with AMF framework for HA.
 *
 */
class HaImplementer : public ACS_APGCC_ApplicationManager
{
 public:

	///  Constructor.
	inline HaImplementer(const char * daemon_name)
	: ACS_APGCC_ApplicationManager(daemon_name)
	{}

	/// Destructor.
	inline virtual ~HaImplementer() {}

	//@{
	/**
	 *  AMF callbacks of the abstract interface @c ACS_APGCC_ApplicationManager.
	*/
	virtual ACS_APGCC_ReturnType performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT state);
	virtual ACS_APGCC_ReturnType performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT state);
	virtual ACS_APGCC_ReturnType performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT state);
	virtual ACS_APGCC_ReturnType performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT state);

	virtual ACS_APGCC_ReturnType performComponentTerminateJobs();
	virtual ACS_APGCC_ReturnType performComponentRemoveJobs();
	virtual ACS_APGCC_ReturnType performApplicationShutdownJobs();
	virtual ACS_APGCC_ReturnType performComponentHealthCheck();
	//@}

 private:

	/**
	 * @brief Requires execution of an operation by the operation scheduler.
	 *
	 * @param  id Operation identifier.
	 */
	void schedule(operation::identifier_t id);

	// = Disallow these operations.
	HaImplementer & operator=(const HaImplementer & rhs);
	HaImplementer(const HaImplementer& rhs);
};

#endif // HEADER_GUARD_CLASS_APG_COMPONENT_HA_APP_MANAGER_H_
