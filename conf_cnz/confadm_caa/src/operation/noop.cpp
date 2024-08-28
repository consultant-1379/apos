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
#include "operation/noop.h"
#include "common/tracer.h"
#include "common/logger.h"
#include "common/programconstants.h"

APG_COMPONENT_TRACE_DEFINE(Operation_NoOp)

namespace operation
{

  NoOp::NoOp()
  : OperationBase(NOOP)
  {
      APG_COMPONENT_TRACE_FUNCTION;
  }

  int NoOp::call()
  {
      APG_COMPONENT_TRACE_FUNCTION;
      APG_COMPONENT_LOG(LOG_LEVEL_WARN, "NoOp executed");
      setResultToCaller();
      return common::errorCode::ERR_NO_ERRORS;
  }

} /* namespace operation */
