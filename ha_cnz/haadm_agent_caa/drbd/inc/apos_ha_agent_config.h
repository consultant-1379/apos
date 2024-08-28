/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_agent_config.h
 *
 * @brief
 * 
 * This the configuration class of agent. It reads the configuration parameters
 * from config file and returns config object
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_CONFIG_H
#define APOS_HA_AGENT_CONFIG_H

#include <ace/ACE.h>
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"

#include <iostream>
#include <string>


class Global;

class HA_AGENT_Config
{
  
  public:	

	HA_AGENT_Config();
	// Description:
    //  Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	int readConfig();
	// Description:
	//  read the Configuration paramters from Config file.
	// Parameters:
	//    none
	// Return value:
	//    none


	 ~HA_AGENT_Config();
	// Description:
    //  Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	HA_AGENT_ConfigT& getConfig();
	// Description:
	//  returns the Config Object
	// Parameters:
	//    none
	// Return value:
	//    returns Config Object

	void dumpConfig();
	// Description:
	//  Destructor. Releases all allocated memory.
	// Parameters:
	//    none
	// Return value:
	//    none

	int readMips();
	// Description:
	//  read the MIP info from apos_ha_operations
	// Parameters:
	//    none
	// Return value:
	//    int


  private:

	int initConfig();
	// Description:
	//  dumps the Config Object
	// Parameters:
	//    none
	// Return value:
	//    0	- success
	//	 -1 - failure

	ACE_TCHAR* getToken(char *str, unsigned char tok);
	// Description:
	//  strips out the token from the string
	// Parameters:
	//    none
	// Return value:
	//    token

	int initLog(HA_AGENT_ConfigT tmpConfig);
	// Description:
	//  init the log subsystem if required.
	// Parameters:
	//    none
	// Return value:
	//    int

	HA_AGENT_ConfigT m_Config;

	Global* m_globalInstance;
};

inline
HA_AGENT_ConfigT& HA_AGENT_Config::getConfig()
{
	return this->m_Config;
}
#endif

// -------------------------------------------------------------------------
