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

CNZ_NAME ?= ha_cnz
CAA_NAME ?= haadm_devmon_caa/drbd
CXC_NAME ?= ha_devmon_cxc

# Basic paths
VOB_PATH = $(APOS_ROOT)
CNZ_PATH = $(VOB_PATH)/$(CNZ_NAME)
CAA_PATH = $(CNZ_PATH)/$(CAA_NAME)
CXC_PATH = $(CNZ_PATH)/$(CXC_NAME)

include $(COMMON_ROOT)/common.mk

DOXYGENFILECONFIG := $(COMMON_ROOT)/doxygen_common.conf

DOCDIR = $(APOS_ROOT)/ha_cnz/ha_devmon_cxc/doc
DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=HA_DEVMON_CAA
BLOCK_VERSION=1_0
BLOCK_SEARCH=./src ./inc

export DOXYGEN_OUTPUT
export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

HA_DMONTR_SRCDIR = $(CAA_PATH)/src
HA_DMONTR_INCDIR = $(CAA_PATH)/inc
CXCDIR	= $(CXC_PATH)

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

##Include files
CINCLUDES += -I$(HA_DMONTR_INCDIR)
CINCLUDES += -I$(COREMW_SDK_INC)
CINCLUDES += -I$(ACE_SDK_INC)
## Source files

HA_DMONTR_SRC = $(HA_DMONTR_SRCDIR)/apos_ha_devmon_hamanager.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_main.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_amfclass.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_adm.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_reactorrunner.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_logtrace.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_utils.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_config.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_drbdmon.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_global.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_drbdmgr.cpp \
		$(HA_DMONTR_SRCDIR)/apos_ha_devmon_drbdrecovery.cpp \

HA_DMONTR_OBJ = $(OBJDIR)/apos_ha_devmon_hamanager.obj \
	 	$(OBJDIR)/apos_ha_devmon_main.obj \
		$(OBJDIR)/apos_ha_devmon_amfclass.obj \
		$(OBJDIR)/apos_ha_devmon_adm.obj\
		$(OBJDIR)/apos_ha_reactorrunner.obj \
		$(OBJDIR)/apos_ha_logtrace.obj \
		$(OBJDIR)/apos_ha_devmon_utils.obj \
		$(OBJDIR)/apos_ha_devmon_config.obj \
		$(OBJDIR)/apos_ha_devmon_drbdmon.obj \
		$(OBJDIR)/apos_ha_devmon_global.obj \
		$(OBJDIR)/apos_ha_devmon_drbdmgr.obj \
		$(OBJDIR)/apos_ha_devmon_drbdrecovery.obj \

VPATH += $(SRCDIR) $(OUTDIR) $(INCDIR) $(OBJDIR)

COVERAGE ?= no

# here you can add own compiler flags
ifeq ($(COVERAGE),yes)
CFLAGS += -O0 -fprofile-arcs -ftest-coverage 
else
CFLAGS += -O3
endif

# here you can add own lib paths
LIBSDIR += -L$(CAA_PATH)/lib64
LIBSDIR += -L$(AP_SDK_LIB)
LIBSDIR += -L$(ACE_SDK_LIB)
LIBSDIR += -L$(COREMW_SDK_LIB)

## # here you can add own libs
LIBS += -lrt -lpthread -lACE -lSaAmf 

## Object filebin
OBJ =	$(HA_DMONTR_SRC:%.cpp=%.obj) \
	$(HA_DMONTR_SRC:%.c=%.obj)

## here you can add own File paths
VPATH += $(SRCDIR) $(OUTDIR) $(OBJDIR)

HA_DMONTR_APNAME = apos_ha_devmond_drbd

.PHONY: all CFLAGS += $(GCOV_FLAGS)

all:	$(OUTDIR)/$(HA_DMONTR_APNAME)

$(OUTDIR)/$(HA_DMONTR_APNAME):$(OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(HA_DMONTR_APNAME)'
	$(CC) -o $(OUTDIR)/$(HA_DMONTR_APNAME) $(HA_DMONTR_OBJ) $(LIBSDIR) $(LIBS)
#	$(call stripp,$(HA_DMONTR_APNAME))
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

