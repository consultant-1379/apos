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
#            2010-12-17   XMALSHA   Created
#
#***********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CNZ_NAME ?= ha_cnz
CAA_NAME ?= ha_appdemo/simap_agent/haadm_fagent_caa
CXC_NAME ?= ha_fagent_cxc

# Basic paths
VOB_PATH = $(APOS_ROOT)
CNZ_PATH = $(VOB_PATH)/$(CNZ_NAME)
CAA_PATH = $(CNZ_PATH)/$(CAA_NAME)
CXC_PATH = $(CNZ_PATH)/ha_appdemo/simap_agent/ha_fagent_cxc
OBJDIR = $(CAA_PATH)/obj

DOXYGENFILECONFIG := $(COMMON_ROOT)/doxygen_common.conf

DOCDIR = $(APOS_ROOT)/ha_cnz/ha_appdemo/ha_fagent_cxc/doc
DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=APOS_HA
BLOCK_VERSION=1_0
BLOCK_SEARCH=./src ./inc

export DOXYGEN_OUTPUT
export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

HA_FAGNT_SRCDIR = $(CAA_PATH)/src
HA_FAGNT_INCDIR = $(CAA_PATH)/inc
HA_AMFCLAS_SRCDIR = $(CNZ_PATH)/haadm_devmon_caa/md/src
HA_AMFCLAS_INCDIR = $(CNZ_PATH)/haadm_devmon_caa/md/inc
CXCDIR	= $(CXC_PATH)

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

##Include files
CINCLUDES += -I$(HA_AMFCLAS_INCDIR)
CINCLUDES += -I$(HA_FAGNT_INCDIR) 
CINCLUDES += -I$(COREMW_SDK_INC) 
CINCLUDES += -I$(ACE_SDK_INC) 

## Source files
HA_FAGNT_SRC =	$(HA_FAGNT_SRCDIR)/apos_ha_fagent_class.cpp \
		$(HA_FAGNT_SRCDIR)/apos_ha_fagent_main.cpp \
		$(HA_AMFCLAS_SRCDIR)/apos_ha_devmon_amfclass.cpp \
		$(HA_FAGNT_SRCDIR)/apos_ha_fagent_adm.cpp 
		
HA_FAGNT_OBJ =	$(OBJDIR)/apos_ha_fagent_class.obj \
		$(OBJDIR)/apos_ha_fagent_main.obj \
		$(OBJDIR)/apos_ha_devmon_amfclass.obj \
		$(OBJDIR)/apos_ha_fagent_adm.obj 
	       	
VPATH += $(HA_FAGNT_SRCDIR) $(HA_AMFCLAS_SRCDIR) $(OUTDIR) $(HA_AMFCLAS_INCDIR)  $(HA_FAGNT_INCDIR)  $(OBJDIR)

COVERAGE ?= no

# here you can add own compiler flags
ifeq ($(COVERAGE),yes)
CFLAGS += -O0 -fprofile-arcs -ftest-coverage
else
CFLAGS += -O3
endif

# here you can add own lib paths
LIBSDIR += -L$(COREMW_SDK_LIB)
LIBSDIR += -L$(AP_SDK_LIB)
LIBSDIR += -L$(ACE_SDK_LIB)

## # here you can add own libs
LIBS += -lrt -lpthread -lACE -lSaImmOm  -lSaAmf

## Object filebin
OBJ =  $(HA_FAGNT_SRC:%.cpp=%.obj) \
	$(HA_FAGNT_SRC:%.c=%.obj) \

## here you can add own File paths
VPATH += $(SRCDIR) $(OUTDIR) $(OBJDIR)

HA_FAGNT_APNAME = apos_ha_rdeagentd

.PHONY: all CFLAGS += $(GCOV_FLAGS)

all:	$(OUTDIR)/$(HA_FAGNT_APNAME)\

$(OUTDIR)/$(HA_FAGNT_APNAME):$(OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(HA_FAGNT_APNAME)'
	$(CC) $(CFLAGS) -o $(OUTDIR)/$(HA_FAGNT_APNAME) $(HA_FAGNT_OBJ) $(LIBSDIR) $(LIBS)
	$(SEPARATOR_STR)
	$(NEW_LINE)

.PHONY: cccc
cccc:
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'C/C++ Code Counter file: $@'
		$(CCCC) $(wildcard $(BLOCKDIR)/inc/*)
		$(CCCC) $(wildcard $(BLOCKDIR)/src/*)
	$(SEPARATOR_STR)

.PHONY: clean
clean:
	$(RM) -r $(OBJDIR)/*.obj
	$(RM) -r $(OBJDIR)/*.d

.PHONY: documentation
documentation:
	$(SILENT)$(ECHO) 'documentation updating ...'
	$(SILENT)$(ECHO) ' Removing $(DOXYGEN_OUTPUT) directory'
	$(SILENT)$(RM) -r -f $(DOXYGEN_OUTPUT)
	$(SILENT)$(ECHO) ' Creating $(DOXYGEN_OUTPUT) directory'
	$(SILENT)mkdir $(DOXYGEN_OUTPUT)
	$(SILENT)$(DOXYGEN) -g $(DOXYGENFILECONFIG)

.PHONY: metrics
metrics:
	$(SILENT)$(ECHO) 'Metrics updating ...'
	$(SILENT)$(ECHO) '**********************************'
	$(SILENT)$(ECHO) '****** NOT YET IMPLEMENTED *******'
	$(SILENT)$(ECHO) '**********************************'

