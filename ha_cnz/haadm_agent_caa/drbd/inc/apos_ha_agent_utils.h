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
 * @file apos_ha_agent_utils.h
 *
 * @brief
 * 
 * This class is used as a generic utility class. It checks the physical 
 * components of the node viz., name, architecture etc.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#ifndef APOS_HA_AGENT_UTILS_H
#define APOS_HA_AGENT_UTILS_H

#include <ace/ACE.h>
#include <arpa/inet.h>
#include <string>
#include "apos_ha_logtrace.h"
#include "apos_ha_agent_types.h"
#include "apos_ha_agent_global.h"

using namespace std;

class Global;

class HA_AGENT_Utils
{
  
  public:	

	HA_AGENT_Utils();
	// Description:
    //  Default constructor
    // Parameters:
    //    none
    // Return value:
    //    none

	 ~HA_AGENT_Utils();
	// Description:
    //  Destructor. Releases all allocated memory.
    // Parameters:
    //    none
    // Return value:
    //    none

	void msec_sleep(ACE_UINT32 msecs);
	// Description:
	//  sleep in milli seconds
	// Parameters:
	//    none
	// Return value:
	//    none

	int init();
	// Description:
	//  shall invoke Ap() and Gep()
	// Parameters:
	//    none
	// Return value:
	//    none

	bool Ap_1();
	// Description:
	//  sleep in milli seconds
	// Parameters:
	//    none
	// Return value:
	//    none

	bool Ap_2();
	// Description:
	//  sleep in milli seconds
	// Parameters:
	//    none
	// Return value:
	//    none

	bool Gep1();
	// Description:
	//  checks if the hardware we are running is GEP1
	// Parameters:
	//    none
	// Return value:
	//    true if GEP1, false otherwise

	bool Gep2();
	// Description:
	//  checks if the hardware we are running is GEP2
	// Parameters:
	//    none
	// Return value:
	//    true if GEP2, false otherwise

	bool Gep4();
	// Description:
	//  checks if the hardware we are running is GEP4
	// Parameters:
	//    none
	// Return value:
	//    true if GEP4, false otherwise

	bool Gep5();
	// Description:
	//  checks if the hardware we are running is GEP5
	// Parameters:
	//    none
	// Return value:
	//    true if GEP5, false otherwise

	int _execlp(const char *str);
	// Description:
	//  execute a new process
	// Parameters:
	//    str
	// Return value:
	//    0, if success

	int _execvp(char *const argv[], char **outstr); 
	// Description:
	//  execute a new process
	// Parameters:
	//    argv, outrStr
	// Return value:
	//    0, if success

    void forceExit();
    // Description:
    //    forceExits the process.
    // Parameters:
    //    none
    // Return value:
    //    none
    //

	int createRCF();
	// Description:
	//    create reboot count file
	// Parameters:
	//	none
	// Return value:
	//    0, if success

	int removeRCF();
	// Description:
	//    remove reboot count file
	// Parameters:
	//  none
	// Return value:
	// 0, if success

	int APEvent();
	// Description:
	//    AP Event info
	// Parameters:
	//  none
	// Return value:
	//  0, if success

	bool isIPv4(const string &ipaddress);
	// Description:
	//   verify ipv4 address
	// Parameters:
	//   ipaddress
	// Return value:
	//   true if success, false otherwise
	
	bool isIPv6(const string &ipaddress);
	// Description:
	//   verify ipv6 address
	// Parameters:
	//   ipaddress
	// Return value:
	//   true if success, false otherwise

	   /** Runs any linux command/script
    * @param[in] command - command or script to run
    * @param[out] output - the output from the command as a string
    * @return true if successful, otherwise false
    */
   bool runCommand(const string command, string& output);
   

   /** Returns the state of the local disk
    * @param[in] resource - (drbd0 or drbd1)
    * @param[out] state of the local disk
    * @return true if successful, otherwise false
    */   
   bool getDiskState(string resource, string& state, bool isLocal);
   
   
   
   
   /** Returns the role of the local disk
    * @param[in] resource - (drbd0 or drbd1)
    * @param[out] role of the local disk
    * @return true if successful, otherwise false
    */
   bool getDrbdRole(string resource, string& role, bool isLocal);
   
   
   
   
	/** Returns the connected state
    * @param[in] resource - (drbd0 or drbd1)
    * @param[out] connected state
    * @return true if successful, otherwise false
    */
    bool getConnectedState(string resource, string& state);	  
	
	
  private:

  	bool FileExist();

	int Ap();

	int Gep();

	void fillEvent(std::string &msg);

	bool ap_1;
	
	bool ap_2;
	
	bool Gep1flag;
	
	bool Gep2flag;
	
	bool Gep4flag;

	bool Gep5flag;

	Global* m_globalInstance;
};

inline
bool HA_AGENT_Utils::Ap_1()
{
	return this->ap_1;
}

inline
bool HA_AGENT_Utils::Ap_2()
{
	return this->ap_2;
}

inline 
bool HA_AGENT_Utils::Gep1()
{
	return this->Gep1flag;
}

inline 
bool HA_AGENT_Utils::Gep2()
{
	return this->Gep2flag;
}

inline 
bool HA_AGENT_Utils::Gep4()
{
	return this->Gep4flag;
}

inline 
bool HA_AGENT_Utils::Gep5()
{
	return this->Gep5flag;
}

#endif
// -------------------------------------------------------------------------
