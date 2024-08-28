# **********************************************************************
#
# Short description:
# Makefile template for XXX library
# **********************************************************************
#
# Ericsson AB 2010 All rights reserved.
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
#            2018-04-23   xcsrajn   ESM adoptations
#            2011-01-03   xmalsha   Created
#                                                            
# **********************************************************************
 
# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk 

CXC_NAME?=APOS_HADEVMONBIN
CXC_NR?=CXC1371468_10
CXC_VER?=R1A01
BASE_SW_VER?=3.6.0-R1A
CXC_BLK_NAME ?= apos_hadevmon
CURDIR = $(shell pwd)
CXCPATH=$(CURDIR)
CXCDIR=$(CXCPATH)
export CXCDIR
#ESM_VER = $(shell $(ESM_SCRIPTS_DIR)/getversion.sh $(CXC_NR) $(CXC_VER))
FX_CLEAN_TMP := rm -rf /tmp/$(USER)/*
CAA_ADM_DIR = ../haadm_devmon_caa/
DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=$(CXC_NAME)
BLOCK_VERSION=$(CXC_NAME)_$(CXC_VER)
BLOCK_SEARCH=  ../haadm_devmon_caa/drbd/src ../haadm_devmon_caa/md/src \
			haadm_devmon_caa/drbd/inc ../haadm_devmon_caa/md/inc

APNAME?=ha_apos_devmond

export CAA_ADM_DIR

SUBSYSTEM_DIRS = \
		../haadm_devmon_caa/drbd \
		../haadm_devmon_caa/md

.PHONY: all
all:
		@for i in $(SUBSYSTEM_DIRS) ; do \
			(echo "+++++++++++++++++" ; \
			echo "cd $$i" ; \
			cd $$i ; \
			$(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) all ) ;\
			if [ $$? != 0 ] ; \
				then $(ECHO) "Error: please see the printout !!!";\
				exit 3;\
			fi;\
			echo "+++++++++++++++++" ; \
		done

.PHONY: nightbuild
nightbuild: del_update  distclean all rpm_package sdp_package esm_package copy_package  documentation metrics doc_package

.PHONY: del_update
del_update:
	$(call rpm_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call sdp_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call esm_del_update,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(OLD_ESM_VER),$(CXC_NR))


.PHONY: release
release: all rpm_package sdp_package esm_package ap_sdk documentation metrics

.PHONY: documentation
documentation:
	$(call doc_creation)

CPPCKECK_SRCS = ../haadm_devmon_caa/drbd/src/*.cpp ../haadm_devmon_caa/md/src/*.cpp
CPPCKECK_INCS = -I../haadm_devmon_caa/drbd/inc -I../haadm_devmon_caa/md/inc

.PHONY: cppcheck_m
cppcheck_m:
	$(call cppcheck_doc_creation,$(CPPCKECK_SRCS),$(CPPCKECK_INCS))

CCCC_SRCS = ../haadm_devmon_caa/drbd/src/* ../haadm_devmon_caa/md/src/*

.PHONY: cccc_m
cccc_m:
	$(call cccc_doc_creation,$(CCCC_SRCS))

SLOCCOUNT_SRCS = ../haadm_devmon_caa/drbd ../haadm_devmon_caa/md 

.PHONY: sloccount_m
sloccount_m:
	$(call sloccount_doc_creation,$(SLOCCOUNT_SRCS))
	

.PHONY: metrics
metrics: cppcheck_m cccc_m sloccount_m

	
.PHONY: clean
clean:
		@for i in $(SUBSYSTEM_DIRS) ; do \
			(echo "+++++++++++++++++" ; \
			 echo "cd $$i" ; \
			 cd $$i ; \
			 $(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) clean ) ;\
			 echo "+++++++++++++++++" ; \
		done
		$(call FX_CLEAN_TMP)

.PHONY: distclean
distclean:
		@for i in $(SUBSYSTEM_DIRS) ; do \
			(echo "+++++++++++++++++" ; \
			 echo "cd $$i" ; \
			 cd $$i ; \
			 $(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) distclean ) ;\
			 echo "+++++++++++++++++" ; \
		done
		$(call FX_CLEAN_TMP)

.PHONY: rpm_package
rpm_package:
	$(call rpm_file_creation,devmon.spec,$(CXC_NAME),$(CXC_NR),$(CXC_VER))

.PHONY: sdp_package
sdp_package:
	$(call sdp_creation_US3,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(CXC_OLD_VER),$(CXC_NR))
	$(call up_creation,$(CXC_NAME),$(CXC_NR),$(CXC_VER),$(CXC_OLD_VER),$(CXCPATH),$(BASE_SW_VER))
.PHONY: esm_package
esm_package:
	$(call esm_pkg_creation,$(CXCPATH),$(CXC_BLK_NAME),$(CXC_VER),$(BASE_SW_VER),$(CXC_NR),$(CXC_NAME))
                      
.PHONY: upload_package 
upload_package: 
	$(call upload_package,$(CXC_BLK_NAME),$(CXC_NR),$(CXC_NAME),$(CXC_VER))

.PHONY: tar_package
tar_package:
	$(call tar_creation,$(BLOCK_NAME),$(CXC_NR),$(CXC_VER))

.PHONY: copy_package
copy_package:
	$(call copy_file_to_integration,$(RPMDIR)/$(CXC_NAME)-$(CXC_NR)-$(CXC_VER).x86_64.rpm)
	$(call copy_file_to_integration,$(CXC_NAME)-$(CXC_NR)-$(CXC_VER)-documentation.tar)

.PHONY: doc_package
doc_package: documentation metrics
	$(SILENT)$(ECHO) 'DOC and Metrics packaging ...'
	$(call doc_tarfile_creation,$(CXC_NAME)-$(CXC_NR)-$(CXC_VER)-documentation.tar)

.PHONY: ap_sdk
ap_sdk:
	$(SILENT)$(ECHO) 'AP SDK updating ...'
	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
		echo "cd $$i" ; \
		cd $$i ; \
		$(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) ap_sdk ) ;\
		if [ $$? != 0 ] ; \
		then $(ECHO) "Error: please see the printout !!!";\
		exit $$?;\
	fi;\
	echo "+++++++++++++++++" ; \
	done

.PHONY: undo_ap_sdk
undo_ap_sdk:
	$(SILENT)$(ECHO) 'UNDO AP SDK packaging ...'
	$(SILENT)$(ECHO) '**********************************'
	$(SILENT)$(ECHO) '****** NOT YET IMPLEMENTED *******'
	$(SILENT)$(ECHO) '**********************************'

