/* *********************************************************
 *
 * (C) Copyright Ericsson 2015
 *
 *  The Copyright to the computer program(s) herein
 * is the property of Ericsson 2015.
 * The program(s) may be used and/or copied only with
 * the written permission from Ericsson 2015 or in
 * accordance with the terms and conditions stipulated in
 * the agreement/contract under which the program(s) have
 * been supplied.
 *
 * File: immutil.cpp
 *
 * Brief:
 * This class is resposible for updating IMM attribute of the 
 * specific DN 
 *
 * Author: xmadmut
 *
 ********************************************************* */
#include "apos_cmd_getutil.h"
#include <unistd.h>
#include <string.h>
#include <iostream>
using namespace std;

#define MAX_RETRY 60

const char* ImmUtil::saf_errMsg(SaAisErrorT error)
{
	switch (error) {
		case SA_AIS_OK:
			return "SA_AIS_OK";
		case SA_AIS_ERR_LIBRARY:
			return "SA_AIS_ERR_LIBRARY";
		case SA_AIS_ERR_VERSION:
			return "SA_AIS_ERR_VERSION";
		case SA_AIS_ERR_INIT:
			return "SA_AIS_ERR_INIT";
		case SA_AIS_ERR_TIMEOUT:
			return "SA_AIS_ERR_TIMEOUT";
		case SA_AIS_ERR_TRY_AGAIN:
			return "SA_AIS_ERR_TRY_AGAIN";
		case SA_AIS_ERR_INVALID_PARAM:
			return "SA_AIS_ERR_INVALID_PARAM";
		case SA_AIS_ERR_NO_MEMORY:
			return "SA_AIS_ERR_NO_MEMORY";
		case SA_AIS_ERR_BAD_HANDLE:
			return "SA_AIS_ERR_BAD_HANDLE";
		case SA_AIS_ERR_BUSY:
			return "SA_AIS_ERR_BUSY";
		case SA_AIS_ERR_ACCESS:
			return "SA_AIS_ERR_ACCESS";
		case SA_AIS_ERR_NOT_EXIST:
			return "SA_AIS_ERR_NOT_EXIST";
		case SA_AIS_ERR_NAME_TOO_LONG:
			return "SA_AIS_ERR_NAME_TOO_LONG";
		case SA_AIS_ERR_EXIST:
			return "SA_AIS_ERR_EXIST";
		case SA_AIS_ERR_NO_SPACE:
			return "SA_AIS_ERR_NO_SPACE";
		case SA_AIS_ERR_INTERRUPT:
			return "SA_AIS_ERR_INTERRUPT";
		case SA_AIS_ERR_NAME_NOT_FOUND:
			return "SA_AIS_ERR_NAME_NOT_FOUND";
		case SA_AIS_ERR_NO_RESOURCES:
			return "SA_AIS_ERR_NO_RESOURCES";
		case SA_AIS_ERR_NOT_SUPPORTED:
			return "SA_AIS_ERR_NOT_SUPPORTED";
		case SA_AIS_ERR_BAD_OPERATION:
			return "SA_AIS_ERR_BAD_OPERATION";
		case SA_AIS_ERR_FAILED_OPERATION:
			return "SA_AIS_ERR_FAILED_OPERATION";
		case SA_AIS_ERR_MESSAGE_ERROR:
			return "SA_AIS_ERR_MESSAGE_ERROR";
		case SA_AIS_ERR_QUEUE_FULL:
			return "SA_AIS_ERR_QUEUE_FULL";
		case SA_AIS_ERR_QUEUE_NOT_AVAILABLE:
			return "SA_AIS_ERR_QUEUE_NOT_AVAILABLE";
		case SA_AIS_ERR_BAD_FLAGS:
			return "SA_AIS_ERR_BAD_FLAGS";
		case SA_AIS_ERR_TOO_BIG:
			return "SA_AIS_ERR_TOO_BIG";
		case SA_AIS_ERR_NO_SECTIONS:
			return "SA_AIS_ERR_NO_SECTIONS";
		case SA_AIS_ERR_NO_OP:
			return "SA_AIS_ERR_NO_OP";
		case SA_AIS_ERR_REPAIR_PENDING:
			return "SA_AIS_ERR_REPAIR_PENDING";
		case SA_AIS_ERR_NO_BINDINGS:
			return "SA_AIS_ERR_NO_BINDINGS";
		case SA_AIS_ERR_UNAVAILABLE:
			return "SA_AIS_ERR_UNAVAILABLE";
		case SA_AIS_ERR_CAMPAIGN_ERROR_DETECTED:
			return "SA_AIS_ERR_CAMPAIGN_ERROR_DETECTED";
		case SA_AIS_ERR_CAMPAIGN_PROC_FAILED:
			return "SA_AIS_ERR_CAMPAIGN_PROC_FAILED";
		case SA_AIS_ERR_CAMPAIGN_CANCELED:
			return "SA_AIS_ERR_CAMPAIGN_CANCELED";
		case SA_AIS_ERR_CAMPAIGN_FAILED:
			return "SA_AIS_ERR_CAMPAIGN_FAILED";
		case SA_AIS_ERR_CAMPAIGN_SUSPENDED:
			return "SA_AIS_ERR_CAMPAIGN_SUSPENDED";
		case SA_AIS_ERR_CAMPAIGN_SUSPENDING:
			return "SA_AIS_ERR_CAMPAIGN_SUSPENDING";
		case SA_AIS_ERR_ACCESS_DENIED:
			return "SA_AIS_ERR_ACCESS_DENIED";
		case SA_AIS_ERR_NOT_READY:
			return "SA_AIS_ERR_NOT_READY";
		case SA_AIS_ERR_DEPLOYMENT:
			return "SA_AIS_ERR_DEPLOYMENT";
	}
	return "Bad error number";
}

SaAisErrorT ImmUtil::initImmOm(SaImmHandleT &immHandle)
{ 
	SaVersionT immVersion = { 'A', 2, 1 };

	SaAisErrorT saRet = saImmOmInitialize(&immHandle, NULL, &immVersion);
	unsigned int retry = 1;
	while (saRet == SA_AIS_ERR_TRY_AGAIN && retry < MAX_RETRY) {
		saRet = saImmOmInitialize(&immHandle, NULL, &immVersion);
		sleep(1);
		retry++;
	}
	if (saRet != SA_AIS_OK) {
		std::cerr<<"saImmOmInitialize FAILED:"<<saf_errMsg(saRet)<<std::endl;
		return saRet;
	}
	return saRet;
}


SaAisErrorT ImmUtil::initImmOmAccessor(const SaImmHandleT immHandle, SaImmAccessorHandleT &accessorHandle)
{
	SaAisErrorT saRet = saImmOmAccessorInitialize(immHandle, &accessorHandle);
	unsigned int retry = 1;
	while (saRet == SA_AIS_ERR_TRY_AGAIN && retry < MAX_RETRY) {
		saRet = saImmOmAccessorInitialize(immHandle, &accessorHandle);
		sleep(1);
		retry++;
	}
	if (SA_AIS_OK != saRet) {
		std::cerr<<"saImmOmAccessorInitialize FAILED:"<<saf_errMsg(saRet)<<std::endl;
		return saRet;
	}
	return saRet;
}

SaAisErrorT ImmUtil::finalizeImmOmAccessor(const SaImmAccessorHandleT accessorHandle)
{
	SaAisErrorT saRet = SA_AIS_OK;
	if( accessorHandle != 0 ) {
		saRet = saImmOmAccessorFinalize(accessorHandle);
		unsigned int retry = 1;
		while (saRet == SA_AIS_ERR_TRY_AGAIN && retry < MAX_RETRY) {
			saRet = saImmOmAccessorFinalize(accessorHandle);
			sleep(1);
			retry++;
		}

		if (SA_AIS_OK != saRet) {
			std::cerr<<"saImmOmAccessorFinalize FAILED"<<saf_errMsg(saRet)<<std::endl;
			return saRet;
		}
	}
	return saRet;
}

SaAisErrorT ImmUtil::finalizeImmOm(const SaImmHandleT immHandle)
{
	SaAisErrorT saRet = SA_AIS_OK;
	if( immHandle != 0 ) {
		saRet = saImmOmFinalize(immHandle);
		unsigned int retry = 1;
		while (saRet == SA_AIS_ERR_TRY_AGAIN && retry < MAX_RETRY) {
			saRet = saImmOmFinalize(immHandle);
			sleep(1);
			retry++;
		}
		if (SA_AIS_OK != saRet) {
			std::cerr<<"saImmOmFinalize FAILED:"<< saf_errMsg(saRet)<<std::endl;
			return saRet;
		}
	}
	return saRet;
}

bool ImmUtil::isValidAttribute(const SaImmHandleT immHandle, const SaImmClassNameT className, SaImmAttrNameT attrName)
{
	SaAisErrorT rc = SA_AIS_OK;
	SaImmClassCategoryT classCategory;
	SaImmAttrDefinitionT_2 *attrDef;
	SaImmAttrDefinitionT_2 **attrDefinitions;
	int i = 0;
	bool attrFound=false;

	if ((rc = saImmOmClassDescriptionGet_2(immHandle, className, &classCategory, &attrDefinitions)) != SA_AIS_OK)
		return rc;

	rc = SA_AIS_ERR_INVALID_PARAM;
	while ((attrDef = attrDefinitions[i++]) != NULL) {
		if (!strcmp(attrName, attrDef->attrName)) {
			attrFound=true;
			rc = SA_AIS_OK;
			break;
		}
	}
	(void)saImmOmClassDescriptionMemoryFree_2(immHandle, attrDefinitions);
	return attrFound;
}

SaAisErrorT ImmUtil::immGetClassName(const SaImmAccessorHandleT accessorHandle, const SaNameT *objectName, SaImmClassNameT *className)
{
	SaAisErrorT  rc = SA_AIS_OK;
	SaImmAttrValuesT_2 **attributes;
	SaImmAttrNameT attributeNames[] = { "SaImmAttrClassName", NULL };

	rc = saImmOmAccessorGet_2(accessorHandle, objectName, attributeNames, &attributes);
	unsigned int retry = 1;
	while (rc == SA_AIS_ERR_TRY_AGAIN && retry < MAX_RETRY) {
		sleep(1);
		rc = saImmOmAccessorGet_2(accessorHandle, objectName, attributeNames, &attributes);
		retry++;
	}
	if (SA_AIS_OK != rc) {
		if (rc == SA_AIS_ERR_NOT_EXIST)
			std::cerr<<"Object '"<<objectName->value<<"' does not exist"<<std::endl;
		else
			std::cerr<<"saImmOmAccessorGet_2 FAILED: %s"<<saf_errMsg(rc)<<std::endl;
	}
	else{
		//std::cerr<<"GetClass Name:"<<*((char **)attributes[0]->attrValues[0])<<std::endl;
		*className = strdup(*((char **)attributes[0]->attrValues[0]));
	}
	return rc;
}
