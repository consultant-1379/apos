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
# -----      ----------   --------  --------------------------
#            2018-04-23   xcsrajn   ESM adoptations            
#            2018-03-06   eginsan   Adaptation to SwM2.0
#            2016-09-06   ecremal   Created
#                                                            
# **********************************************************************

# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk 

# example: APOS_OSCONFBIN-CXC1371499_9-R1A01.x86_64.sdp
CXC_NAME ?= APOS_OSCONFBIN
CXC_NR ?= CXC1371499_19
CXC_VER ?= R1B
#CXC_OLD_VER ?= R1A04
BASE_SW_VER ?= 3.7.0-R1A

CXCDIR = $(shell pwd)
SDPDIR = $(CXCDIR)/packages/sdp
ESMDIR = $(CXCDIR)/packages/esm
export CXCDIR

CXC_BLK_NAME?=apos_osconf
#ESM_VER = $(shell $(ESM_SCRIPTS_DIR)/getversion.sh $(CXC_NR) $(CXC_VER))

CAA_ADM_DIR = ../confadm_caa
export CAA_ADM_DIR
CAA_DIRS = $(CAA_ADM_DIR)

BLOCK_NAME=$(CXC_NAME)
BLOCK_VERSION=$(CXC_NAME)_$(CXC_VER)
export BLOCK_NAME
export BLOCK_VERSION

FX_CLEAN_CONTRIB := find ../ -name *.contrib* | xargs -I {} rm {}
FX_CLEAN_TMP := rm -rf /tmp/$(USER)/*

.PHONY: clean_and_build
clean_and_build: clean all

.PHONY: all
all:
	@for i in $(CAA_DIRS) ; do \
	(echo "*****************" ; \
	 echo "***    ALL    ***" ; \
	 echo "*****************" ; \
	echo "cd $$i" ; \
	cd $$i ; \
	$(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) checkdirs ;\
	$(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) all) ;\
	if [ $$? != 0 ] ; \
	then $(ECHO) "Error: please see the printout !!!";\
	exit $$?;\
	fi;\
	echo "===================" ; \
	echo "====  END ALL  ====" ; \
	echo "===================" ; \
	done

.PHONY: release
release: all rpm_package sdp_package esm_package

.PHONY: nightbuild
nightbuild: del_update all rpm_package sdp_package esm_package 

.PHONY: del_update
del_update:
	$(call rpm_del_update,$(CXCDIR),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call sdp_del_update,$(CXCDIR),$(BLOCK_NAME),$(CXC_VER),$(OLD_CXC_VER),$(CXC_NR))
	$(call esm_del_update,$(CXCDIR),$(BLOCK_NAME),$(CXC_VER),$(OLD_ESM_VER),$(CXC_NR))

.PHONY: delivery
delivery: clean  all rpm_package sdp_package esm_package 

	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
    echo "cd $$i" ; \
    cd $$i ; \
    $(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT)) ;\
    if [ $$? != 0 ] ; \
			then $(ECHO) "Error: please see the printout !!!";\
			exit $$?;\
		fi;\
    echo "+++++++++++++++++" ; \
    done

.PHONY: clean
clean:
		$(SILENT)$(ECHO) '===================================================================='
		$(SILENT)$(ECHO) 'CLEANING OBJECT FILES FOR BLOCK $(BLOCK_NAME)'
		$(SILENT)$(ECHO) '===================================================================='
		$(NEW_LINE)
		$(call FX_CLEAN_CONTRIB)
		$(call FX_CLEAN_TMP)
		@for i in $(CAA_DIRS) ; do \
			(echo "*****************" ; \
			 echo "***   CLEAN   ***" ; \
			 echo "*****************" ; \
			 echo "cd $$i" ; \
			 cd $$i ; \
			 $(MAKE) $(MFLAGS) COMMON_ROOT=$(COMMON_ROOT) APOS_ROOT=$(APOS_ROOT) clean ) ;\
			 if [ $$? != 0 ] ; \
			then $(ECHO) "Error: please see the printout !!!";\
			exit $$?;\
			fi;\
			 echo "=====================" ; \
			 echo "====  END CLEAN  ====" ; \
			 echo "=====================" ; \
		done

.PHONY: rpm_package
rpm_package:
	$(call rpm_file_creation,apos-conf.spec,$(CXC_NAME),$(CXC_NR),$(CXC_VER))

.PHONY: tar_package
tar_package:
		 $(SILENT) echo '==========================='
		 $(SILENT) echo '====  END TAR_PACKAGE  ===='
		 $(SILENT) echo '==========================='

.PHONY: sdp_package
sdp_package:
	$(SILENT)$(ECHO) 'SDP packaging ...'
	$(call sdp_creation_US2,$(CXCDIR),$(BLOCK_NAME),$(CXC_VER),$(CXC_OLD_VER),$(CXC_NR))
	$(call up_creation,$(CXC_NAME),$(CXC_NR),$(CXC_VER),$(CXC_OLD_VER),$(CXCDIR),$(BASE_SW_VER))

.PHONY: esm_package
esm_package:
	if [ ! -d $(ESMDIR) ]; then echo "ESM directory created...."; mkdir -p $(ESMDIR);  fi 
	$(call esm_pkg_creation,$(CXCDIR),$(CXC_BLK_NAME),$(CXC_VER),$(BASE_SW_VER),$(CXC_NR),$(CXC_NAME))
                      
.PHONY: upload_package 
upload_package: 
	$(call upload_package,$(CXC_BLK_NAME),$(CXC_NR),$(CXC_NAME),$(CXC_VER))

	$(SILENT)$(ECHO) 'Copied Runtime and Deployment packages to esm directory'

