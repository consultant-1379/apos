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
 * @file apos_ha_agent_immOm.cpp
 *
 * @brief
 *
 * This class is used for fetching information from IMM using IMM APIs
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_immOm.h"

//-------------------------------------------------------------------------
HA_AGENT_ImmOm::HA_AGENT_ImmOm():
m_globalInstance(HA_AGENT_Global::instance())
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
HA_AGENT_ImmOm::~HA_AGENT_ImmOm()
{
	HA_TRACE_ENTER();

	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
bool HA_AGENT_ImmOm::peerNodeLockd()
{
	HA_TRACE_ENTER();
	bool rCode=true, Ominit=false;
	string peerNodeId(""), dnOfAmfNodeObj("");
	SaNameT objectNode;
	ACE_INT32 tCode=-1;
	
	// check which node we are running on.
	if (m_globalInstance->Utils()->Ap_1() == true) {
		peerNodeId="2";
	} else if (m_globalInstance->Utils()->Ap_2() == true) {
		peerNodeId="1";
	} else {
		rCode=false;	
	}
	/* IMM variable setup to make imm calls */
	SaAisErrorT error;
	SaImmHandleT immHandle;
	SaVersionT immVersion;

	SaImmAccessorHandleT accessorHandle;
	SaImmAttrNameT attributeNames[2] = {const_cast<char *>("saAmfNodeAdminState"), 0};
	SaImmAttrValuesT_2 **attributes = 0;
	SaImmAttrValuesT_2 *attr = 0;

	if (rCode) {
		dnOfAmfNodeObj = "safAmfNode=SC-";
		dnOfAmfNodeObj += peerNodeId;
		dnOfAmfNodeObj += ",safAmfCluster=myAmfCluster";

		immVersion.releaseCode  = 'A';
		immVersion.majorVersion =  2;
		immVersion.minorVersion =  1;

		error = saImmOmInitialize(&immHandle, NULL, &immVersion);
		if (error != SA_AIS_OK) {
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmInitialize failed", __func__);
			rCode=false;
		} else {
			Ominit=true;
		}	
		
	}

	if (rCode) {
		strncpy((char*)objectNode.value, dnOfAmfNodeObj.c_str(), SA_MAX_NAME_LENGTH);
		objectNode.length = strlen((char *)objectNode.value);

		error = saImmOmAccessorInitialize(immHandle, &accessorHandle);
		if (error != SA_AIS_OK) {
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorInitialize failed", __func__);
			rCode=false;
		}		
	}

	if (rCode) {
		error = saImmOmAccessorGet_2(accessorHandle, &objectNode, attributeNames, &attributes);
		if (error != SA_AIS_OK) {
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorGet_2 failed", __func__);
			rCode=false;
		}
	}	

	if (rCode) {
		attr = attributes[0];
		if (strcmp(attributes[0]->attrName, "saAmfNodeAdminState") == 0) {
			tCode = attr->attrValuesNumber > 0
			? *reinterpret_cast<SaInt32T *>(attr->attrValues[0]) //*((SaInt32T *)attributes[0]->attrValues[0])
			: -1;
		} 
		error = saImmOmAccessorFinalize(accessorHandle);
		if (error != SA_AIS_OK) {
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorFinalize failed", __func__);
			rCode=false;
		}	
	}

	if (rCode || Ominit) {
		error = saImmOmFinalize(immHandle);
		if (error != SA_AIS_OK) {
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmInitialize failed", __func__);
			rCode=false;
		}	
	}
	if ((tCode != APOS_HA_ADMIN_LOCK) &&
		(tCode != APOS_HA_ADMIN_LOCK_IN)) {
			HA_TRACE("HA_AGENT_ImmOm:%s() safAmfNodeAdminState=%d", __func__, tCode);
			rCode=false;
	}

	HA_TRACE_LEAVE();
	return rCode;
}	

//-------------------------------------------------------------------------

bool HA_AGENT_ImmOm::isVirtualNode()
{
	HA_TRACE_ENTER();
	bool rCode = true, Ominit = false, isVirtual = false;
	string peerNodeId(""), axeFunctionObjDN("");
	SaNameT objName;
	ACE_INT32 shelf_architecture_value = -1;

	/* IMM variable setup to make imm calls */
	SaAisErrorT error;
	SaImmHandleT immHandle;
	SaVersionT immVersion;
	SaImmAccessorHandleT accessorHandle;
	SaImmAttrValuesT_2 **attributes = 0;
	SaImmAttrValuesT_2 *attr = 0;

	SaImmAttrNameT attributeNames[2] = {const_cast<char *>(APOS_HA_NODE_ARCHITECTURE_ATTR_NAME), 0};
	axeFunctionObjDN = APOS_HA_AXEFUNCTIONS_OBJ_DN;

	immVersion.releaseCode  = 'A';
	immVersion.majorVersion =  2;
	immVersion.minorVersion =  1;

	error = saImmOmInitialize(&immHandle, NULL, &immVersion);
	if (error != SA_AIS_OK)
	{
		HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmInitialize failed", __func__);
		rCode = false;
	}
	else
		Ominit = true;


	if (rCode)
	{
		error = saImmOmAccessorInitialize(immHandle, &accessorHandle);
		if (error != SA_AIS_OK)
		{
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorInitialize failed", __func__);
			rCode = false;
		}
	}

	if (rCode)
	{
		strncpy((char*)objName.value, axeFunctionObjDN.c_str(), SA_MAX_NAME_LENGTH);
		objName.length = strlen((char *)objName.value);
		error = saImmOmAccessorGet_2(accessorHandle, &objName, attributeNames, &attributes);
		if (error != SA_AIS_OK)
		{
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorGet_2 failed", __func__);
			rCode = false;
		}
	}

	if (rCode)
	{
		attr = attributes[0];
		if (strcmp(attributes[0]->attrName, APOS_HA_NODE_ARCHITECTURE_ATTR_NAME) == 0)
		{
			shelf_architecture_value = attr->attrValuesNumber > 0 ? *reinterpret_cast<SaInt32T *>(attr->attrValues[0]) : -1;
			if (shelf_architecture_value == APOS_HA_NODE_VIRTUAL)
			{
				HA_LG_IN("HA_AGENT_ImmOm:%s() Node is VIRTUAL - PING will be used in SplitBrainAlogrithm", __func__);
				isVirtual = true;
			}
		}
		error = saImmOmAccessorFinalize(accessorHandle);
		if (error != SA_AIS_OK)
		{
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmAccessorFinalize failed", __func__);
			rCode = false;
		}
	}

	if (rCode || Ominit)
	{
		error = saImmOmFinalize(immHandle);
		if (error != SA_AIS_OK)
		{
			HA_LG_ER("HA_AGENT_ImmOm:%s() saImmOmInitialize failed", __func__);
			rCode = false;
		}
	}
	if(rCode == false)
		HA_LG_ER("HA_AGENT_ImmOm:%s() Errors found during IMM OM operation.", __func__);

	HA_TRACE_LEAVE();
	return isVirtual;
}
