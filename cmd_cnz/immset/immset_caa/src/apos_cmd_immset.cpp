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
 * File: immset.cpp
 *
 * Brief:
 * This class is resposible for updating IMM attribute of the 
 * specific DN 
 *
 * Author: xmadmut
 *
 ********************************************************* */

//#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <saAis.h>
#include <saImmOm.h>
#include <iostream>
#include <vector>
#include "apos_cmd_immset.h"
#include "apos_cmd_setutil.h"
#include <sstream>
#include <getopt.h>

#define MAX_BUFF 1024
#define no_argument 0
#define required_argument 1

using namespace std;


namespace patch
{
    template < typename T > std::string to_string( const T& n )
    {
        std::ostringstream stm ;
        stm << n ;
        return stm.str() ;
    }
}

std::vector<string> objNameVect;
std::vector<string> attrNameVect;
std::vector<string> attrValVect;
std::string m_attrName, m_attrValue;

ImmSet::ImmSet() 
{
	m_immHandle = 0;
	m_accessorHandle = 0;
	m_immInitDone = false;
}

ImmSet::~ImmSet() 
{
	if(m_immInitDone) {
		finalizeImm();
	}
}

void ImmSet::getAttrValue(SaImmValueTypeT attrValType, SaImmAttrValueT *attrValue)
{
    switch (attrValType) {
      case SA_IMM_ATTR_SAINT32T:
			attrValVect.push_back(patch::to_string(*((SaInt32T *)attrValue)));
            break;
      case SA_IMM_ATTR_SAUINT32T:
			attrValVect.push_back(patch::to_string(*((SaUint32T *)attrValue)));
            break;
      case SA_IMM_ATTR_SAINT64T:
			attrValVect.push_back(patch::to_string(*((SaInt64T *)attrValue)));
            break;
      case SA_IMM_ATTR_SAUINT64T:
			attrValVect.push_back(patch::to_string(*((SaUint64T *)attrValue)));
            break;
      case SA_IMM_ATTR_SATIMET:
			attrValVect.push_back(patch::to_string(*((SaTimeT *)attrValue)));
            break;
      case SA_IMM_ATTR_SAFLOATT:
			attrValVect.push_back(patch::to_string(*((SaFloatT *)attrValue)));
            break;
      case SA_IMM_ATTR_SADOUBLET:
			attrValVect.push_back(patch::to_string(*((SaDoubleT *)attrValue)));
            break;
      case SA_IMM_ATTR_SANAMET: {
            SaNameT *myNameT = (SaNameT *)attrValue;
			attrValVect.push_back(patch::to_string( myNameT->value));
            break;
      }
      case SA_IMM_ATTR_SASTRINGT:
			attrValVect.push_back(*((char **)attrValue) );
            break;
      default:
            std::cout<<("Unknown");
            break;
      }
}

SaAisErrorT ImmSet::initImm()
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

SaAisErrorT ImmSet::finalizeImm()
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

SaAisErrorT ImmSet::getAttributes(std::string objectName, std::string attributeName)
{
	SaImmAttrValuesT_2 *attr;
	SaImmAttrValuesT_2 **attributes;
	SaAisErrorT saRet = SA_AIS_OK;

	SaImmAttrNameT retriveAttribute[2];
	retriveAttribute[0] = const_cast<char*>(attributeName.c_str());
	retriveAttribute[1] = 0;

	SaNameT objName;
	strncpy((char *)objName.value, objectName.c_str(), SA_MAX_NAME_LENGTH);
	objName.length = objectName.length();

	saRet = saImmOmAccessorGet_2(m_accessorHandle, &objName, retriveAttribute, &attributes);
	if (SA_AIS_OK != saRet) {
		if (saRet == SA_AIS_ERR_NOT_EXIST)
			std::cerr<<"Object '"<<objectName<<"' or Attribute '"<<attributeName<<"' does not exist"<<std::endl;
		else
			std::cerr<<"saImmOmAccessorGet_2 FAILED:"<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		return saRet;
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
				attrValVect.push_back("<Empty>");
		}
	}
	return saRet;
}

SaAisErrorT ImmSet::getAttrType(SaImmClassNameT className, char *attrName, SaImmValueTypeT &attrValType)
{
      SaAisErrorT saRet = SA_AIS_OK;
      saRet = immGetAttrValueType(className, attrName, attrValType);
      if (saRet == SA_AIS_ERR_NOT_EXIST) {
	      std::cerr<<"Class '"<<className<<"' does not exist"<<std::endl;
	      free(className);
	      className = NULL;
	      return saRet;
      }
      if (saRet != SA_AIS_OK) {
            std::cout<<"Attribute '"<<attrName<<"' does not exist in class '"<<className<<"'"<<std::endl;
	      free(className);
	      className = NULL;
      }

      return saRet;
}

SaAisErrorT ImmSet::modifyImmObject(std::string objectName, std::string attributeName, std::string attributeValue)
{
	SaAisErrorT saRet = SA_AIS_OK;

	SaNameT objName;
	strncpy((char *)objName.value, objectName.c_str(), SA_MAX_NAME_LENGTH);
	objName.length = objectName.length();

	SaImmClassNameT clsName;
	if((saRet = ImmUtil::immGetClassName(m_accessorHandle, &objName, &clsName)) != SA_AIS_OK) {
		return saRet;
	}

	SaImmValueTypeT attrValType;
	std::string attrNameStr = attributeName;
	std::string attrNameVal = attributeValue;
	if ((saRet = getAttrType(clsName, (char*)attrNameStr.c_str(), attrValType)) != SA_AIS_OK) {
		return saRet;
	}

      SaImmAdminOwnerNameT adminOwnerName = (char *)"immget";
      SaImmAdminOwnerHandleT ownerHandle;

      if( (saRet = saImmOmAdminOwnerInitialize(m_immHandle, adminOwnerName, SA_TRUE, &ownerHandle)) != SA_AIS_OK){
	      std::cerr<<"saImmOmAdminOwnerInitialize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
	      return saRet;
      }

	const SaNameT *objNamesList[] = {&objName, 0};

	if ((saRet = saImmOmAdminOwnerSet(ownerHandle, objNamesList, SA_IMM_ONE)) != SA_AIS_OK) {
		if (saRet == SA_AIS_ERR_NOT_EXIST)
			std::cerr<<"Object '"<<objNamesList[0]->value<<"' does not exist"<<std::endl;
		else
			std::cerr<<"saImmOmAdminOwnerSet FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;

		if( saImmOmAdminOwnerFinalize(ownerHandle) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerFinalize:FAILED"<<std::endl;
		}
		return saRet;
	}

	SaImmCcbHandleT ccbHandle;
	if ((saRet = saImmOmCcbInitialize(ownerHandle, 0, &ccbHandle)) != SA_AIS_OK) {
		std::cerr<<"saImmOmCcbInitialize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		if ((saImmOmAdminOwnerRelease(ownerHandle, objNamesList, SA_IMM_ONE)) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerRelease FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		if (saImmOmAdminOwnerFinalize(ownerHandle) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerFinalize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		return saRet;
	}

	SaImmAttrModificationT_2 attr;
	attr.modType = SA_IMM_ATTR_VALUES_REPLACE;
	attr.modAttr.attrName = (char *)attrNameStr.c_str();
	attr.modAttr.attrValuesNumber = 1;
	attr.modAttr.attrValues = (void **)malloc(sizeof(SaImmAttrValueT *));
	attr.modAttr.attrValueType = attrValType;
	attr.modAttr.attrValues[0] = setImmAttrValue(attrValType, attrNameVal.c_str());
	if (attr.modAttr.attrValues[0]==NULL){
		saRet=SA_AIS_ERR_NOT_SUPPORTED;
		return saRet;
	}

	SaImmAttrModificationT_2* attrMods[2] = {0, 0};
	attrMods[0] = &attr;
	attrMods[1] = 0;

	if ((saRet = saImmOmCcbObjectModify_2(ccbHandle, &objName, (const SaImmAttrModificationT_2**)attrMods)) != SA_AIS_OK) {
                  std::cerr<<"saImmOmCcbObjectModify_2 FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;

		  if ((saImmOmAdminOwnerRelease(ownerHandle, objNamesList, SA_IMM_ONE)) != SA_AIS_OK) {
			  std::cerr<<"saImmOmAdminOwnerRelease FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		  }
		  if (saImmOmAdminOwnerFinalize(ownerHandle) != SA_AIS_OK) {
			  std::cerr<<"saImmOmAdminOwnerFinalize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		  }
		  return saRet;
   }
	if((saRet = saImmOmCcbApply(ccbHandle)) != SA_AIS_OK) {
		std::cerr<<"saImmOmCcbApply FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		
		if (saImmOmAdminOwnerRelease(ownerHandle, objNamesList, SA_IMM_ONE) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerRelease FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		if (saImmOmAdminOwnerFinalize(ownerHandle) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerFinalize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		return saRet;
	}

	if ((saRet = saImmOmCcbFinalize(ccbHandle)) != SA_AIS_OK) {
		std::cerr<<"saImmOmCcbFinalize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		
		if (saImmOmAdminOwnerRelease(ownerHandle, objNamesList, SA_IMM_ONE) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerRelease FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		
		if (saImmOmAdminOwnerFinalize(ownerHandle) != SA_AIS_OK) {
			std::cerr<<"saImmOmAdminOwnerFinalize FAILED: "<<ImmUtil::saf_errMsg(saRet)<<std::endl;
		}
		return saRet;
	}
	return saRet;
}

SaAisErrorT ImmSet::immGetAttrValueType(const SaImmClassNameT className, SaImmAttrNameT attrName, SaImmValueTypeT &attrValueType)
{
    SaAisErrorT rc = SA_AIS_OK;
    SaImmClassCategoryT classCategory;
    SaImmAttrDefinitionT_2 *attrDef;
    SaImmAttrDefinitionT_2 **attrDefinitions;
    int i = 0;

    if ((rc = saImmOmClassDescriptionGet_2(m_immHandle, className, &classCategory, &attrDefinitions)) != SA_AIS_OK)
        return rc;

    rc = SA_AIS_ERR_INVALID_PARAM;
    while ((attrDef = attrDefinitions[i++]) != NULL) {
        if (!strcmp(attrName, attrDef->attrName)) {
            attrValueType = attrDef->attrValueType;
            rc = SA_AIS_OK;
            break;
        }
    }
    (void)saImmOmClassDescriptionMemoryFree_2(m_immHandle, attrDefinitions);
    return rc;
}

void * ImmSet::setImmAttrValue(SaImmValueTypeT attrValueType, const char *str)
{
    void *attrValue = NULL;
    size_t len;
    char *endptr;

    /*
    ** sizeof(long) varies between 32 and 64 bit machines. Therefore on a
    ** 64 bit machine, a check is needed to ensure that the value returned
    ** from strtol() or strtoul() is not greater than what fits into 32 bits.
    */
    switch (attrValueType) {
    case SA_IMM_ATTR_SAINT32T: {
        errno = 0;
        long value = strtol(str, &endptr, 0);
        SaInt32T attr_value = value;
        if ((errno != 0) || (endptr == str) || (*endptr != '\0')) {
            fprintf(stderr, "int32 conversion failed\n");
            return NULL;
        }
        if (value != attr_value) {
            printf("int32 conversion failed, value too large\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaInt32T));
        *((SaInt32T *)attrValue) = value;
        break;
    }
    case SA_IMM_ATTR_SAUINT32T: {
        errno = 0;
        unsigned long value = strtoul(str, &endptr, 0);
        SaUint32T attr_value = value;
        if ((errno != 0) || (endptr == str) || (*endptr != '\0')) {
            fprintf(stderr, "uint32 conversion failed\n");
            return NULL;
        }
        if (value != attr_value) {
            printf("uint32 conversion failed, value too large\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaUint32T));
        *((SaUint32T *)attrValue) = value;
        break;
    }
    case SA_IMM_ATTR_SAINT64T:
        // fall-through, same basic data type
    case SA_IMM_ATTR_SATIMET: {
        errno = 0;
        long long value = strtoll(str, &endptr, 0);
        if ((errno != 0) || (endptr == str) || (*endptr != '\0')) {
            fprintf(stderr, "int64 conversion failed\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaInt64T));
        *((SaInt64T *)attrValue) = value;
        break;
    }
    case SA_IMM_ATTR_SAUINT64T: {
        errno = 0;
        unsigned long long value = strtoull(str, &endptr, 0);
        if ((errno != 0) || (endptr == str) || (*endptr != '\0')) {
            fprintf(stderr, "uint64 conversion failed\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaUint64T));
        *((SaUint64T *)attrValue) = value;
        break;
    }
    case SA_IMM_ATTR_SAFLOATT: {
        errno = 0;
        float myfloat = strtof(str, &endptr);
        if (((myfloat == 0) && (endptr == str)) ||
            (errno == ERANGE) || (*endptr != '\0')) {
            fprintf(stderr, "float conversion failed\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaFloatT));
        *((SaFloatT *)attrValue) = myfloat;
        break;
    }
    case SA_IMM_ATTR_SADOUBLET: {
        errno = 0;
        double mydouble = strtod(str, &endptr);
        if (((mydouble == 0) && (endptr == str)) ||
            (errno == ERANGE) || (*endptr != '\0')) {
            fprintf(stderr, "double conversion failed\n");
            return NULL;
        }
        attrValue = malloc(sizeof(SaDoubleT));
        *((SaDoubleT *)attrValue) = mydouble;
        break;
    }
    case SA_IMM_ATTR_SANAMET: {
        SaNameT *mynamet;
        len = strlen(str);
        if (len > SA_MAX_NAME_LENGTH) {
            fprintf(stderr, "too long SaNameT\n");
            return NULL;
        }
        attrValue = mynamet = (SaNameT *)malloc(sizeof(SaNameT));
        mynamet->length = len;
        strncpy((char *)mynamet->value, str, SA_MAX_NAME_LENGTH);
        break;
    }
    case SA_IMM_ATTR_SASTRINGT: {
        attrValue = malloc(sizeof(SaStringT));
        *((SaStringT *)attrValue) = strdup(str);
        break;
    }
    case SA_IMM_ATTR_SAANYT: {
        char* endMark;
        SaBoolT even = SA_TRUE;
        char byte[5];
        unsigned int i;

        len = strlen(str);
        if(len % 2) {
            len = len/2 + 1;
            even = SA_FALSE;
        } else {
            len = len/2;
        }
        attrValue = malloc(sizeof(SaAnyT));
        ((SaAnyT*)attrValue)->bufferAddr =
            (SaUint8T*)malloc(sizeof(SaUint8T) * len);
        ((SaAnyT*)attrValue)->bufferSize = len;

        byte[0] = '0';
        byte[1] = 'x';
        byte[4] = '\0';

        endMark = byte + 4;

        for (i = 0; i < len; i++) {
            byte[2] = str[2*i];
            if(even || (i + 1 < len)) {
                byte[3] = str[2*i + 1];
            } else {
                byte[3] = '0';
            }
            ((SaAnyT*)attrValue)->bufferAddr[i] =
                (SaUint8T)strtod(byte, &endMark);
        }
    }
    default:
        break;
    }
    return attrValue;
}

void ImmSet::usage(const char *cmd_name)
{
      std::cout<<"Usage : "<<cmd_name<<" [-r] [value] [-t] [value] <attribute=<value>>:<dn>"<<std::endl;
      std::cout<<"	"<<cmd_name<<" [-r] [value] [-t] [value] <attribute1=<value1>>:<dn> <attribute2=<value2>>:<dn>..."<<std::endl;
      std::cout<<"	"<<cmd_name<<" [-r] [value] [-t] [value] <attribute1=<value1>>:<dn1> <attribute2=<value2>>:<dn2> ..."<<std::endl;
}

bool ImmSet::isValidArgument(const char* arg)
{ 
	bool res=false;
	char *str = NULL;
	str = strstr(arg,"==");
	if (NULL == str) {
		char *attrStr=NULL;
		attrStr = strstr(arg,"=");
		cout <<"attrStr:"<<attrStr<<endl;
		if (attrStr == NULL)
			return false;
		else {
			char *dnStr = NULL;
			dnStr=strstr(attrStr+1,"=");
			if (dnStr == NULL) 
				return false;
			else
				res=true;
			cout<<"dnStr:"<<dnStr<<endl;
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

inline bool isInteger(const std::string & s)
{
   if(s.empty() || ((!isdigit(s[0])) && (s[0] != '-') && (s[0] != '+'))) return false ;

   char * p ;
   strtol(s.c_str(), &p, 10) ;

   return (*p == 0) ;
}
bool ImmSet::getAttrAndDN(const char* arg, RdnAttrStT &rdnAttr)
{
	bool attrDnFound=false;
	std::string tempStr = arg;
	std::string obj,attr;
	std::size_t found = tempStr.find_last_of(":");
	if(found!=std::string::npos){
		rdnAttr.objName = tempStr.substr (found+1);
		objNameVect.push_back(rdnAttr.objName);
		cout<<"Object Name:"<<rdnAttr.objName<<endl;
		rdnAttr.attrName= tempStr.substr (0,found);
    	std::size_t found = rdnAttr.attrName.find_last_of("=");
    	if(found!=std::string::npos){
        	m_attrName = rdnAttr.attrName.substr(0,found);
			cout<<"attribute name: "<<m_attrName<<endl;
			attrNameVect.push_back(m_attrName);
        	m_attrValue = rdnAttr.attrName.substr(found+1);
			cout<<"attribute Value:"<<m_attrValue<<endl;
			attrDnFound=true;
    	}	
	}
	return attrDnFound;
}

int main(int argc,char **argv)
{
	ImmSet immset;
	if (argc < 2){
		std::cout<<"Incorrect usage"<<endl;
		immset.usage(basename(argv[0]));
		return 1;
	}
	bool rollback=false;
	std::vector<string> inputVect;
	int timeoutVal=60;
	int opt_argc=0,man_argc=0;
	int maxRetry=1;
	int retry=1;
	for (int i =1; i<argc; i++){
		if (( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0) || (strcmp (argv[i],"-t")==0) || (strcmp (argv[i],"--timeout")==0)){
			if(i+1<argc && isInteger(argv[i+1])){
				int temp=atoi(argv[i+1]);
				if ( ( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0))
					maxRetry=temp;
				else
					timeoutVal=temp;
				i=i+2;
				opt_argc++;
			} else {
				cout<<"Incorrect usage"<<endl;
				immset.usage(basename(argv[0]));
				return -1;
			}
		}
		if ( i < argc ) {
			if (( strcmp (argv[i],"-r")==0) || (strcmp (argv[i],"--retry")==0) || (strcmp (argv[i],"-t")==0) || (strcmp (argv[i],"--timeout")==0)){
				i--;
				continue;
			}
			char tempBuf[MAX_BUFF] = {'\0'};
			strncpy(tempBuf, argv[i], MAX_BUFF);
			if ( !immset.isValidArgument(tempBuf)){
				std::cout<<"Incorrect usage"<<endl;
				immset.usage(basename(argv[0]));
				return -1;
			} else {
				cout<<"Inside valid argument";
				inputVect.push_back(argv[i]);
				man_argc++;
			}
		}
	}
	if( opt_argc>0 && man_argc == 0){
		immset.usage(basename(argv[0]));
		return -1;
	}
	if (SA_AIS_OK != immset.initImm()) {
		cout<<"IMM initialize failed :"<<endl;
		return 1;
	}
	SaAisErrorT rc = SA_AIS_OK;
	for (unsigned int i = 0; i<inputVect.size(); i++) {
		RdnAttrStT rdnAttrStInst;
		retry=1;
		if( true == immset.getAttrAndDN(inputVect[i].c_str(), rdnAttrStInst)){
			rc = immset.getAttributes(rdnAttrStInst.objName,m_attrName);
			while((rc == SA_AIS_ERR_TRY_AGAIN || rc == SA_AIS_ERR_BUSY) && retry < timeoutVal){
				sleep(1);
				rc = immset.getAttributes(rdnAttrStInst.objName,m_attrName);
				retry++;
			}
			retry=1;
			while( rc == SA_AIS_ERR_TIMEOUT && retry < maxRetry) {
				sleep(1);
				rc = immset.getAttributes(rdnAttrStInst.objName,m_attrName);
				retry++;
			}
			if (rc != SA_AIS_OK) {
				std::cout<<"Immget failed :"<<ImmUtil::saf_errMsg(rc)<<std::endl;
				immset.finalizeImm();
				rollback=true;
				break;
			}
			retry=1;
			rc=immset.modifyImmObject(rdnAttrStInst.objName, m_attrName, m_attrValue);
			while((rc == SA_AIS_ERR_TRY_AGAIN || rc == SA_AIS_ERR_BUSY) && retry < timeoutVal){
                sleep(1);
				rc=immset.modifyImmObject(rdnAttrStInst.objName, m_attrName, m_attrValue);
                retry++;
            }
            retry=1;
            while( rc == SA_AIS_ERR_TIMEOUT && retry < maxRetry) {
                sleep(1);
				rc=immset.modifyImmObject(rdnAttrStInst.objName, m_attrName, m_attrValue);
                retry++;
            }
			if(rc != SA_AIS_OK) {
				std::cout<<"Immset failed :"<<ImmUtil::saf_errMsg(rc)<<std::endl;
				rollback=true;
				immset.finalizeImm();
				break;
			}
		} else {
			immset.usage(basename(argv[0]));
			return -1;
		}

	}
	if (rollback) {
		if (attrValVect.size()==0) return -1;
		for (unsigned int i = 0; i<attrValVect.size(); i++) {
			if(strcmp(attrValVect[i].c_str(),"<Empty>")==0){
				cout<<"Roll back is not possible,because of previous empty value\n";
				return -1;
			}
		}
	}
	if (rollback) {
		if (SA_AIS_OK != immset.initImm()) {
			cout<<"IMM initialize failed :"<<endl;
			return -1;
		}
		cout<<"Trying to roll back to previous values\n";
		for (unsigned int i = 0; i<objNameVect.size(); i++) {
			rc = immset.modifyImmObject(objNameVect[i], attrNameVect[i], attrValVect[i]);
			if ( rc != SA_AIS_OK){
				immset.finalizeImm();
				cout<< "Rollback failed:"<<ImmUtil::saf_errMsg(rc)<<endl;
				return -1;
			}
		}
		cout << "Roll back success"<<endl;
	}
	std::cout<<std::endl;
	immset.finalizeImm();
	return 0;
}

