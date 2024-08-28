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
CAA_NAME ?= haadm_agent_caa/md
CXC_NAME ?= ha_agent_cxc

# Basic paths
VOB_PATH = $(APOS_ROOT)
CNZ_PATH = $(VOB_PATH)/$(CNZ_NAME)
CAA_PATH = $(CNZ_PATH)/$(CAA_NAME)
CXC_PATH = $(CNZ_PATH)/$(CXC_NAME)

include $(COMMON_ROOT)/common.mk

DOXYGENFILECONFIG := $(COMMON_ROOT)/doxygen_common.conf

DOCDIR = $(APOS_ROOT)/ha_cnz/ha_agent_cxc/doc
DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=APOS_HA
BLOCK_VERSION=1_0
BLOCK_SEARCH=./src ./inc

export DOXYGEN_OUTPUT
export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

HA_RDAGNT_SRCDIR = $(CAA_PATH)/src
HA_RDAGNT_INCDIR = $(CAA_PATH)/inc
HA_DMONTR_SRCDIR = $(CAA_PATH)/src
HA_DMONTR_INCDIR = $(CAA_PATH)/inc
CXCDIR	= $(CXC_PATH)

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

##Include files
CINCLUDES += -I$(HA_RDAGNT_INCDIR)
CINCLUDES += -I$(ACE_SDK_INC)
CINCLUDES += -I$(COREMW_SDK_INC)

## Source files
HA_RDAGNT_SRC =	$(HA_RDAGNT_SRCDIR)/apos_ha_rdeagent_main.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_rdeagent_class.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_rdeagent_utils.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_rdeagent_tipc.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_rdeagent_amfclass.cpp

HA_RDAGNT_OBJ =	$(OBJDIR)/apos_ha_rdeagent_main.obj \
		$(OBJDIR)/apos_ha_rdeagent_class.obj \
		$(OBJDIR)/apos_ha_rdeagent_utils.obj \
		$(OBJDIR)/apos_ha_rdeagent_tipc.obj \
		$(OBJDIR)/apos_ha_rdeagent_amfclass.obj
		
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
LIBSDIR += -L$(COREMW_SDK_LIB)
LIBSDIR += -L$(ACE_SDK_LIB)

## # here you can add own libs
LIBS += -lrt -lpthread -lACE -lSaImmOm  -lSaAmf

## Object filebin
OBJ =   $(HA_RDAGNT_SRC:%.cpp=%.obj) \
	$(HA_RDAGNT_SRC:%.c=%.obj) 

## here you can add own File paths
VPATH += $(SRCDIR) $(OUTDIR) $(OBJDIR)

HA_RDANT_APNAME = apos_ha_rdeagentd_md

.PHONY: all CFLAGS += $(GCOV_FLAGS)

all:	$(OUTDIR)/$(HA_RDANT_APNAME)

$(OUTDIR)/$(HA_RDANT_APNAME):$(OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(HA_RDANT_APNAME)'
	$(CC) $(CFLAGS) -o $(OUTDIR)/$(HA_RDANT_APNAME) $(HA_RDAGNT_OBJ) $(LIBSDIR) $(LIBS)
	$(call stripp,$(HA_RDANT_APNAME))
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

