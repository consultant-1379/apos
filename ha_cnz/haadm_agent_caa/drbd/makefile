# **********************************************************************
#
# Short description:
# Makefile template for HAAGENT 
# **********************************************************************
#
# Ericsson AB 2013 All rights reserved.
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
#            2013-04-25   XMALSHA   Created
#
#***********************************************************************
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common
 
include $(COMMON_ROOT)/common.mk 

CNZ_PATH = $(APOS_ROOT)/ha_cnz
CAA_PATH = $(CNZ_PATH)/haadm_agent_caa/drbd
BLOCKDIR = $(CAA_PATH)
CXCDIR = $(CNZ_PATH)/ha_agent_cxc
OUTDIR = $(CXCDIR)/bin
OBJDIR = $(BLOCKDIR)/obj
INCDIR = $(BLOCKDIR)/inc
SRCDIR = $(BLOCKDIR)/src   
DOCDIR = $(CXCDIR)/doc

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

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

##Include files
CINCLUDES += -I$(HA_RDAGNT_INCDIR)
CINCLUDES += -I$(COREMW_SDK_INC)
CINCLUDES += -I$(ACE_SDK_INC)

VPATH += $(HA_RDAGNT_SRCDIR) $(OUTDIR) $(HA_RDAGNT_INCDIR) $(OBJDIR)

## Source files
HA_RDAGNT_SRC =	$(HA_RDAGNT_SRCDIR)/apos_ha_agent_main.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_stbyAdm.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_actvAdm.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_amfclass.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_tipc.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_hamanager.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_reactorrunner.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_global.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_rolemngr.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_arping.cpp \
                $(HA_RDAGNT_SRCDIR)/apos_ha_agent_ping.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_ndisc.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_drbdmgr.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_config.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_utils.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_immOm.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_logtrace.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_lockFile.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_powerOff.cpp \
		$(HA_RDAGNT_SRCDIR)/apos_ha_agent_drbdmon.cpp

HA_RDAGNT_OBJ =	$(OBJDIR)/apos_ha_agent_main.obj \
		$(OBJDIR)/apos_ha_agent_stbyAdm.obj \
		$(OBJDIR)/apos_ha_agent_actvAdm.obj \
		$(OBJDIR)/apos_ha_agent_amfclass.obj \
		$(OBJDIR)/apos_ha_agent_tipc.obj \
		$(OBJDIR)/apos_ha_agent_hamanager.obj \
		$(OBJDIR)/apos_ha_reactorrunner.obj \
		$(OBJDIR)/apos_ha_agent_global.obj \
		$(OBJDIR)/apos_ha_agent_rolemngr.obj \
		$(OBJDIR)/apos_ha_agent_arping.obj \
                $(OBJDIR)/apos_ha_agent_ping.obj \
		$(OBJDIR)/apos_ha_agent_ndisc.obj \
		$(OBJDIR)/apos_ha_agent_drbdmgr.obj \
		$(OBJDIR)/apos_ha_agent_config.obj \
		$(OBJDIR)/apos_ha_agent_utils.obj \
		$(OBJDIR)/apos_ha_agent_immOm.obj \
		$(OBJDIR)/apos_ha_logtrace.obj \
		$(OBJDIR)/apos_ha_agent_lockFile.obj \
		$(OBJDIR)/apos_ha_agent_powerOff.obj \
		$(OBJDIR)/apos_ha_agent_drbdmon.obj

		

COVERAGE ?= no

# here you can add own compiler flags
ifeq ($(COVERAGE),yes)
CFLAGS += -O0 -fprofile-arcs -ftest-coverage
else
CFLAGS += -O3
endif

# here you can add own lib paths
LIBSDIR += -L$(AP_SDK_LIB)
LIBSDIR += -L$(ACE_SDK_LIB)
LIBSDIR += -L$(COREMW_SDK_LIB)

## # here you can add own libs
LIBS += -lACE -lrt -lpthread -lSaImmOm  -lSaAmf

## Object filebin
OBJ =   $(HA_RDAGNT_SRC:%.cpp=%.obj) \
		$(HA_RDAGNT_SRC:%.c=%.obj) 

## here you can add own File paths

HA_RDANT_APNAME = apos_ha_rdeagentd_drbd

.PHONY: all CFLAGS += $(GCOV_FLAGS)

all:	$(OUTDIR)/$(HA_RDANT_APNAME)

$(OUTDIR)/$(HA_RDANT_APNAME):$(OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(HA_RDANT_APNAME)'
	$(CC) -o $(OUTDIR)/$(HA_RDANT_APNAME) $(HA_RDAGNT_OBJ) $(LIBSDIR) $(LIBS) 
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

