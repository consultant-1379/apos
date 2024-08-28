# **********************************************************************
#
# Short description:
# Makefile (at CXC level) for Smart Image
# **********************************************************************
#
# Ericsson AB 2015 All rights reserved.
# The information in this document is the property of Ericsson.
# Except as specifically authorized in writing by Ericsson, the receiver of this
# document shall keep the information contained herein confidential and shall protect
# the same in whole or in part from disclosure and dissemination to third parties.
# Disclosure and disseminations to the receivers employees shall only be made
# on a strict need to know basis.
#
# **********************************************************************
#
# Rev        Date         Name      What
# -----      -------      --------  --------------------------
#            2018-01-26   epaopal   18B: Cr_role handling + code review
#            2016-03-03   xclaele   Created
# **********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CXC_BLK_NAME?=ext_tinycore
CXC_NAME ?= EXT_TINYCOREBIN
CXC_NR ?= CXC1371530_20
CXC_VER ?= R1A01
CXC_OLD_VER ?= ''
BASE_SW_VER ?=5.2.0-R1A

OLD_CXC_NAME ?= SMART_IMAGE
OLD_CXC_NR ?= CXC0000000
OLD_CXC_VER ?= R1A01
OLD_RPM_SPEC = old_smart_image.spec

CURDIR = $(shell pwd)
CXCPATH = $(CURDIR)
CXCDIR = $(CXCPATH)
FX_CLEAN_TMP := rm -rf /tmp/$(USER)/*

export CXCDIR
export CXCPATH

RPM_SPEC = smart_image.spec

BLOCK_NAME=$(CXC_NAME)
BLOCK_VERSION=$(CXC_NAME)_$(CXC_VER)
BLOCK_SEARCH=../tinycore_caa

export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

CAADIR = ../tinycore_caa
CAA_DIRS = $(CAADIR)

.PHONY: all
all: sinetcc smart_image

.PHONY: sinetcc
sinetcc: 
	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
		echo "cd $$i" ; \
		cd $$i ; \
		$(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) all) ;\
		if [ $$? != 0 ] ; \
		then $(ECHO) "Error: please see the printout !!!";\
		exit $$?;\
		fi;\
		echo "+++++++++++++++++" ; \
		done
		$(call FX_CLEAN_TMP)

.PHONY: del_update
del_update:
	$(call rpm_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call sdp_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call esm_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_ESM_VER),$(CXC_NR))

.PHONY: smart_image
smart_image: 
	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
		echo "cd $$i" ; \
		cd $$i ; \
		./build_smart_image.sh $(CXCDIR) $(CAADIR)) ;\
		if [ $$? != 0 ] ; \
		then $(ECHO) "Error: please see the printout !!!";\
		exit $$?;\
		fi;\
		echo "+++++++++++++++++" ; \
		done
	  $(call FX_CLEAN_TMP) 

.PHONY: clean
clean:
	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
		 echo "cd $$i" ; \
		 cd $$i ; \
		 $(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) clean ) ;\
		if [ $$? != 0 ] ; \
		then $(ECHO) "Error: please see the printout !!!";\
			exit $$?;\
		fi;\
		echo "+++++++++++++++++" ; \
	done
	$(call FX_CLEAN_TMP)

.PHONY: rpm_package
rpm_package:
	$(call rpm_file_creation,$(RPM_SPEC),$(CXC_NAME),$(CXC_NR),$(CXC_VER))
#	$(call rpm_file_creation,$(OLD_RPM_SPEC),$(OLD_CXC_NAME),$(OLD_CXC_NR),$(OLD_CXC_VER))



.PHONY: sdp_package
sdp_package:
	$(SILENT)$(ECHO) 'SDP packaging ...'
	$(call sdp_creation_US1,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(CXC_OLD_VER),$(CXC_NR))
	$(SILENT)$(ECHO) 'UP packaging ...'

.PHONY: esm_package
esm_package:
		$(call esm_pkg_creation,$(CXCPATH),$(CXC_BLK_NAME),$(CXC_VER),$(BASE_SW_VER),$(CXC_NR),$(CXC_NAME))


