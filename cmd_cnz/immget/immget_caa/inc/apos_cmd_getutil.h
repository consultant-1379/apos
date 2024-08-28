/*
 * immutil.h
 *
 *  Created on: Nov 06, 2015
 *      Author: xmadmut
 */

#ifndef APOS_IMM_UTIL_H_
#define APOS_IMM_UTIL_H_

#include <saAis.h>
#include <saImmOm.h>

class ImmUtil
{
	public:
		static const char* saf_errMsg(SaAisErrorT error);
		static SaAisErrorT initImmOm(SaImmHandleT &immHandle);
		static SaAisErrorT initImmOmAccessor(const SaImmHandleT immHandle, SaImmAccessorHandleT &accessorHandle);
		static SaAisErrorT finalizeImmOmAccessor(const SaImmAccessorHandleT accessorHandle);
		static SaAisErrorT finalizeImmOm(const SaImmHandleT immHandle);
		static bool isValidAttribute(const SaImmHandleT immHandle, const SaImmClassNameT className, SaImmAttrNameT attrName);
		static SaAisErrorT immGetClassName(const SaImmAccessorHandleT accessorHandle, const SaNameT *objectName, SaImmClassNameT *className);

	private:
		ImmUtil();
};

#endif /* APOS_IMM_UTIL_H_ */
