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
#            2010-10-26   teiggam   Created
#            2010-11-19   xgencol   Adjusted
#            2020-11-12   xbippol   Adjusted
#                                                            
# **********************************************************************
 
# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CXC_NAME ?= openssh
CXC_NR ?= 7.2p2_81.12.1
CXC_VER ?= 11.0.1
CXC_OLD_VER ?= 10.0.1|9.0.1

CURDIR = $(shell pwd)
CXCPATH = $(CURDIR)
CXCDIR = $(CXCPATH)
export CXCDIR
export CXCPATH

CAA_BSD_DIR = ../bsd_caa
export CAA_BSD_DIR

CAA_PORTABLE_DIR = ../portable_caa
export CAA_PORTABLE_DIR

DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=$(CXC_NAME)
BLOCK_VERSION=$(CXC_NAME)_$(CXC_VER)
BLOCK_SEARCH=
	#$(CAA_PORTABLE_DIR)/$(SRCDIR) $(CAA_BSD_DIR)/$(SRCDIR)
	#$(CAA_API_DIR)/$(SRCDIR) $(CAA_API_DIR)/$(INCEXTDIR) $(CAA_API_DIR)/$(INCINTDIR) $(CAA_CMD_DIR)/$(SRCDIR) $(CAA_CMD_DIR)/inc
export DOXYGEN_OUTPUT
export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

CAA_DIRS = $(CAA_PORTABLE_DIR)

.PHONY: all
all:
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

.PHONY: release
release: all rpm_package sdp_package tar_package ap_sdk documentation metrics

.PHONY: nightbuild
nightbuild:  distclean all rpm_package sdp_package documentation metrics doc_package copy_package 

.PHONY: copy_targets
copy_targets :
	@for i in $(CAA_DIRS) ; do \
		(echo "+++++++++++++++++" ; \
    echo "cd $$i" ; \
    cd $$i ; \
    $(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) $@) ;\
    if [ $$? != 0 ] ; \
			then $(ECHO) "Error: please see the printout !!!";\
			exit $$?;\
		fi;\
    echo "+++++++++++++++++" ; \
    done

.PHONY: documentation
documentation:
	$(call doc_creation)


#CPPCKECK_SRCS = $(CAA_API_DIR)/$(SRCDIR)/*.cpp $(CAA_ADM_DIR)/$(SRCDIR)/*.cpp $(CAA_CMD_DIR)/$(SRCDIR)/*.cpp
#CPPCKECK_INCS = -I$(CAA_API_DIR)/$(INCEXTDIR) -I$(CAA_API_DIR)/$(INCINTDIR) -I$(CAA_ADM_DIR)/inc -I$(CAA_CMD_DIR)/inc
#
#.PHONY: cppcheck_m
#cppcheck_m:
#       $(call cppcheck_doc_creation,$(CPPCKECK_SRCS),$(CPPCKECK_INCS))


#CCCC_SRCS = $(CAA_API_DIR)/$(SRCDIR)/* $(CAA_ADM_DIR)/$(SRCDIR)/* $(CAA_CMD_DIR)/$(SRCDIR)/*
#
#.PHONY: cccc_m
#cccc_m:
#       $(call cccc_doc_creation,$(CCCC_SRCS))


#SLOCCOUNT_SRCS = $(CAA_API_DIR)/ $(CAA_ADM_DIR)/ $(CAA_CMD_DIR)/
#
#.PHONY: sloccount_m
#sloccount_m:
#       $(call sloccount_doc_creation,$(SLOCCOUNT_SRCS))


#.PHONY: metrics
#metrics: cppcheck_m cccc_m sloccount_m


.PHONY: clean
clean:
		@for i in $(CAA_DIRS) ; do \
                        (echo "+++++++++++++++++" ; \
                         echo "cd $$i" ; \
                         cd $$i ; \
                         $(MAKE) $(MFLAGS) clean ) ;\
                         if [ $$? != 0 ] ; \
                        then $(ECHO) "Error: please see the printout !!!";\
                        exit $$?;\
                        fi;\
                         echo "+++++++++++++++++" ; \
                done


.PHONY: distclean
distclean:
	@for i in $(CAA_DIRS) ; do \
                (echo "+++++++++++++++++" ; \
                echo "cd $$i" ; \
                cd $$i ; \
                $(MAKE) $(MFLAGS) $(MFLAGS) CXCDIR=$(CXCPATH) distclean ) ;\
                if [ $$? != 0 ] ; \
                then $(ECHO) "Error: please see the printout !!!";\
                exit $$?;\
                fi;\
                echo "+++++++++++++++++" ; \
        done


####################
# $(call rpm_file_creation,spec_file,blockName,producNr,ver)
.PHONY: rpm_package
rpm_package:
	$(call rpm_file_creation,openssh.spec,$(CXC_NAME),$(CXC_NR),$(CXC_VER))
#       rpmConf/buildrpm.sh openssh.spec $(CXC_NAME) $(CXC_NR) $(CXC_VER);

.PHONY: sdp_package
sdp_package:
	$(SILENT)$(ECHO) 'SDP packaging ...'
	$(call sdp_creation_US3,$(CXCPATH),$(BLOCK_NAME),$(CXC_VER),$(CXC_OLD_VER),$(CXC_NR))


.PHONY: copy_package
copy_package:
	$(call copy_file_to_integration,$(RPMDIR)/$(CXC_NAME)-$(CXC_NR)-$(CXC_VER).x86_64.rpm)
	$(call copy_file_to_integration,$(CXC_NAME)-$(CXC_NR)-$(CXC_VER)-documentation.tar)


.PHONY: doc_package
doc_package: documentation metrics
	$(SILENT)$(ECHO) 'DOC and Metrics packaging ...'
	$(call doc_tarfile_creation,$(CXC_NAME)-$(CXC_NR)-$(CXC_VER)-documentation.tar)


.PHONY: tar_package
tar_package:
	$(SILENT)$(ECHO) 'TAR packaging ...'
	$(call tar_creation,$(BLOCK_NAME),$(CXC_NR),$(CXC_VER))


.PHONY: ap_sdk
ap_sdk:
	$(SILENT)$(ECHO) 'AP SDK updating ...'
	@for i in $(CAA_DIRS) ; do \
                (echo "+++++++++++++++++" ; \
                echo "cd $$i" ; \
                cd $$i ; \
                $(MAKE) $(MFLAGS) $(MFLAGS) CXCDIR=$(CXCPATH) ap_sdk ) ;\
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
