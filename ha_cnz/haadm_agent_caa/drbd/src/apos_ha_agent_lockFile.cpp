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
 * @file apos_ha_agent_lockFile.cpp
 *
 * @brief
 *
 * This class creates and removes the lock file for agent
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_agent_lockFile.h"

//-------------------------------------------------------------------------
HA_AGENT_LFile::HA_AGENT_LFile()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_LFile::~HA_AGENT_LFile()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_LFile::LFile()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	int fd = open(APOS_HA_FILE_LOCK , O_RDWR|O_CREAT, 0666 );
	if (fd < 0) {
		HA_LG_ER("HA_AGENT_LFile:%s() - Lock File creation failed", __func__);	
		rCode=-1;
	}
	if (rCode != -1)
		close(fd);

	HA_TRACE_LEAVE();
	return rCode;
}	

//-------------------------------------------------------------------------
bool HA_AGENT_LFile::LFileExist()
{
	HA_TRACE_ENTER();
	bool rCode=false;

	if (access(APOS_HA_FILE_LOCK, F_OK) == 0) {
		HA_LG_IN("HA_AGENT_LFile:%s() - Lock File exist", __func__);
		rCode=true;
	}	
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_LFile::RMLFile()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	if (unlink(APOS_HA_FILE_LOCK) < 0) {
		HA_LG_ER("HA_AGENT_LFile:%s() - Failed to unlink(remove) Lock File", __func__);
		rCode=-1;
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
