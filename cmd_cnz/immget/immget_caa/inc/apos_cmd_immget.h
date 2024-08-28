/*
 * immget.h
 *
 *  Created on: Oct 30, 2015
 *      Author: xmadmut
 */

#ifndef APOS_IMMGET_H_
#define APOS_IMMGET_H_

#include <saAis.h>
#include <saImmOm.h>
#include <string>
using namespace std;

typedef struct RdnAttrSt
{
	std::string objName;
	std::string attrName;
}RdnAttrStT;

class ImmGet {

public:
	ImmGet() ;
	~ImmGet();
	void usage(const char *cmd_name);
	bool isValidArgument(const char* arg);
	bool getAttrAndDN(const char* arg, RdnAttrStT &rdnAttr);
	
	SaAisErrorT getAttributs(std::string objectName, std::string attributeName);
	SaAisErrorT initImm();
	SaAisErrorT finalizeImm();

private:
	void getAttrValue(SaImmValueTypeT attrValType, SaImmAttrValueT *attrValue);

	SaImmHandleT m_immHandle;
	SaImmAccessorHandleT m_accessorHandle;
	bool m_immInitDone;
};

#endif /* APOS_IMMGET_H_ */
