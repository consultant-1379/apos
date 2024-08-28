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
 * File: immget.cpp
 *
 * Brief:
 * This class is resposible for fetching IMM attribute of the 
 * specific DN 
 *
 * Author: xmadmut
 *
 ********************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <iostream>

#include <saAis.h>
#include <saImmOm.h>

#include "apos_cmd_immget.h"
#include "apos_cmd_getutil.h"
#include <vector>

using namespace std;

#define MAX_BUFF 1024

ImmGet::ImmGet() 
{
	m_immHandle = 0;
	m_accessorHandle = 0;
	m_immInitDone = false;
}

ImmGet::~ImmGet() 
{
	if(m_immInitDone) 
		finalizeImm();
	
}

void ImmGet::getAttrValue(SaImmValueTypeT attrValType, SaImmAttrValueT *attrValue)
{
    switch (attrValType) {
      case SA_IMM_ATTR_SAINT32T:
            printf("%d", *((SaInt32T *)attrValue));
            break;
      case SA_IMM_ATTR_SAUINT32T:
            printf("%u", *((SaUint32T *)attrValue));
            break;
      case SA_IMM_ATTR_SAINT64T:
            printf("%lld", *((SaInt64T *)attrValue));
            break;
      case SA_IMM_ATTR_SAUINT64T:
            printf("%llu", *((SaUint64T *)attrValue));
            break;
      case SA_IMM_ATTR_SATIMET:
            printf("%llu",  *((SaTimeT *)attrValue));
            break;
      case SA_IMM_ATTR_SAFLOATT:
            printf("%f", *((SaFloatT *)attrValue));
            break;
      case SA_IMM_ATTR_SADOUBLET:
            printf("%lf", *((SaDoubleT *)attrValue));
            break;
      case SA_IMM_ATTR_SANAMET: {
            SaNameT *myNameT = (SaNameT *)attrValue;
            printf("%s", myNameT->value);
            break;
      }
      case SA_IMM_ATTR_SASTRINGT:
            printf("%s", *((char **)attrValue));
            break;
      default:
            std::cout<<("Unknown");
            break;
      }
}

SaAisErrorT ImmGet::initImm()
{ 
	SaAisErrorT error = ImmUtil::initImmOm(m_immHandle);
	if( error == SA_AIS_OK) {
		error = ImmUtil::initImmOmAccessor(m_immHandle, m_accessorHandle);
		if( error != SA_AIS_OK) {
			ImmUtil::finalizeImmOm(m_immHandle);
		}
	}
	m_immInitDone = true;
	return error;
}

SaAisErrorT ImmGet::finalizeImm()
{
	SaAisErrorT error = SA_AIS_OK;
	if( m_accessorHandle != 0 ) {
		error = ImmUtil::finalizeImmOmAccessor(m_accessorHandle);
		m_accessorHandle = 0;
	}

	if( m_immHandle != 0 ) {
		error = ImmUtil::finalizeImmOm(m_immHandle);
		m_immHandle = 0;
	}
	if( (m_immHandle == 0) && (m_accessorHandle ==0) ) 
		m_immInitDone = false;
	return error;
}

SaAisErrorT ImmGet::getAttributs(std::string objectName, std::string attributeName)
{
	SaImmAttrValuesT_2 *attr;
	SaImmAttrValuesT_2 **attributes;
	SaAisErrorT error = SA_AIS_OK;

	SaImmAttrNameT retriveAttribute[2];
	retriveAttribute[0] = const_cast<char*>(attributeName.c_str());
	retriveAttribute[1] = 0;

	SaNameT objName;
	strncpy((char *)objName.value, objectName.c_str(), SA_MAX_NAME_LENGTH);
	objName.length = objectName.length();

	error = saImmOmAccessorGet_2(m_accessorHandle, &objName, retriveAttribute, &attributes);
	if (SA_AIS_OK != error) {
		if (error == SA_AIS_ERR_NOT_EXIST)
			std::cerr<<"`object<"<<objectName<<"> or attribute<"<<attributeName<<"> does not exist`"<<std::endl;
		else
			std::cerr<<"saImmOmAccessorGet_2 FAILED: %s"<<ImmUtil::saf_errMsg(error)<<std::endl;
		return error;
	}

	unsigned int i = 0;
	while ((attr = attributes[i++]) != NULL) {
		if( 0 == strcmp(retriveAttribute[0], attr->attrName))
		{
			//std::cout<<attr->attrName<<"="¨<<std::endl;
			if (attr->attrValuesNumber == 1) {
				getAttrValue(attr->attrValueType, (void **)attr->attrValues[0]);
				std::cout<<" ";
			}
			else if (attr->attrValuesNumber > 1) {
				unsigned int numOfAttrVals;
				for (numOfAttrVals = 0; numOfAttrVals < attr->attrValuesNumber; numOfAttrVals++) {
					getAttrValue(attr->attrValueType, (void **)attr->attrValues[numOfAttrVals]);
					if ((numOfAttrVals + 1) < attr->attrValuesNumber)
						std::cout<<":";
				}
			} else
				std::cout<<"<Empty>";
		}
	}
	return error;
}


void ImmGet::usage(const char *cmd_name)
{
      std::cout<<"Usage : "<<cmd_name<<"[-r] [value] [-t] [value] <attribute>:<dn>"<<std::endl;
      std::cout<<"	"<<cmd_name<<" [-r] [value] [-t] [value] <attribute1>:<dn> <attribute2>:<dn>..."<<std::endl;
      std::cout<<"	"<<cmd_name<<" [-r] [value] [-t] [value] <attribute1>:<dn1> <attribute1>:<dn2>..."<<std::endl;
}

inline bool isInteger(const std::string & s)
{
   if(s.empty() || ((!isdigit(s[0])) && (s[0] != '-') && (s[0] != '+'))) return false ;

   char * p ;
   strtol(s.c_str(), &p, 10) ;

   return (*p == 0) ;
}

bool ImmGet::isValidArgument(const char* arg)
{ 
	bool res=false;
	char *str = NULL;
	str = strstr(arg,"=");
	if (NULL != str) {
		char *tmpstr = strstr(str+1,"=");
		if (NULL == tmpstr) {
			res=true;
		} else {
			tmpstr = strstr(str+1,",");
			if (tmpstr != NULL)
				res=true;
		}
	}
	if( res == true)
	{
		const char delim[] = ":";
		char *subStr;
		int numOfTokens=0;

		subStr = strtok((char *)arg, delim);

		while( subStr != NULL ) 
		{
			++numOfTokens;
			subStr = strtok(NULL, delim);
		}
		if(numOfTokens > 2)
			res=false;
	}
	return res;
}

bool ImmGet::getAttrAndDN(const char* arg, RdnAttrStT &rdnAttr)
{
	bool attrDnFound=false;
	std::string tempStr = arg;

	std::size_t found = tempStr.find_last_of(":");
	if(found!=std::string::npos)
	{
		rdnAttr.objName  = tempStr.substr (found+1);
		rdnAttr.attrName = tempStr.substr (0,found);
		attrDnFound=true;
	}
	return attrDnFound;
}

int main(int argc,char **argv)
{
	ImmGet immget;
	if (argc < 2){
		std::cout<<"Incorrect usage"<<endl;
		immget.usage(basename(argv[0]));
		return 1;
	}
	std::vector<string> inputVect;
	int timeoutVal=60;
	int maxRetry=1;
    for (int i =1; i<argc; i++){
        if (( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0) || (strcmp (argv[i],"-t")==0) || (strcmp (argv[i],"--timeout")==0)){
            if(i+1<argc && isInteger(argv[i+1])){
                int temp=atoi(argv[i+1]);
                if ( ( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0))
                    maxRetry=temp;
                else
                    timeoutVal=temp;
                i=i+2;
            } else {
                cout<<"Incorrect usage"<<endl;
                immget.usage(basename(argv[0]));
                return 1;
            }
        }
		if ( i < argc ) {
            if (( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0) || (strcmp (argv[i],"-t")==0) || (strcmp (argv[i],"--timeout")==0)){
                i--;
                continue;
            }
            char tempBuf[MAX_BUFF] = {'\0'};
            strncpy(tempBuf, argv[i], MAX_BUFF);
            if ( !immget.isValidArgument(tempBuf)){
                std::cout<<"Incorrect usage"<<endl;
                immget.usage(basename(argv[0]));
                return -1;
            } else {
                inputVect.push_back(argv[i]);
            }
        }
    }

	if (SA_AIS_OK != immget.initImm()) {
		cout<<"IMM initialize failed :"<<endl;
		return 1;
	}
	SaAisErrorT rc = SA_AIS_OK;
	for (unsigned int i = 0; i<inputVect.size(); i++) {
        RdnAttrStT rdnAttrStInst;
        int retry=1;
        if( true == immget.getAttrAndDN(inputVect[i].c_str(), rdnAttrStInst)){
            rc = immget.getAttributs(rdnAttrStInst.objName,rdnAttrStInst.attrName);
            while((rc == SA_AIS_ERR_TRY_AGAIN || rc == SA_AIS_ERR_BUSY) && retry < timeoutVal){
                sleep(1);
                rc = immget.getAttributs(rdnAttrStInst.objName,rdnAttrStInst.attrName);
                retry++;
            }
            retry=1;
            while( rc == SA_AIS_ERR_TIMEOUT && retry < maxRetry) {
                sleep(1);
                rc = immget.getAttributs(rdnAttrStInst.objName,rdnAttrStInst.attrName);
                retry++;
            }
            if (rc != SA_AIS_OK) {
                std::cout<<"Immget failed :"<<ImmUtil::saf_errMsg(rc)<<std::endl;
                immget.finalizeImm();
                break;
            }
      	}
	}
	std::cout<<std::endl;
	immget.finalizeImm();
	return 0;
}

