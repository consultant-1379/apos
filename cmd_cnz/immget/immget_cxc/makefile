# **********************************************************************
#
# Short description:
# Makefile template for IMMGET 
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
#            2015-11-04   XMALSHA   Created
#
#***********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CNZ_PATH = $(APOS_ROOT)/cmd_cnz
CAA_PATH = $(CNZ_PATH)/immget/immget_caa
BLOCKDIR = $(CAA_PATH)
CXCDIR = $(CNZ_PATH)/immget/immget_cxc
OUTDIR = $(CXCDIR)/bin
OBJDIR = $(BLOCKDIR)/obj
INCDIR = $(BLOCKDIR)/inc
SRCDIR = $(BLOCKDIR)/src   
DOCDIR = $(CXCDIR)/doc
PARMTOOLDIR = $(CNZ_PATH)/parmtool/parmtool/cmd/get/

DOXYGEN_OUTPUT=$(DOCDIR)/docgen
BLOCK_NAME=APOS_HA
BLOCK_VERSION=1_0
BLOCK_SEARCH=./src ./inc

export DOXYGEN_OUTPUT
export BLOCK_NAME
export BLOCK_VERSION
export BLOCK_SEARCH

IMMGET_SRCDIR = $(CAA_PATH)/src
IMMGET_INCDIR = $(CAA_PATH)/inc

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

##Include files
CINCLUDES += -I$(IMMGET_INCDIR)
CINCLUDES += -I$(COREMW_SDK_INC)
CINCLUDES += -I$(ACE_SDK_INC)

VPATH += $(IMMGET_SRCDIR) $(OUTDIR) $(IMMGET_INCDIR) $(OBJDIR)

## Source files
IMMGET_SRC =	$(IMMGET_SRCDIR)/apos_cmd_immget.cpp \
		$(IMMGET_SRCDIR)/apos_cmd_getutil.cpp

IMMGET_OBJ =	$(OBJDIR)/apos_cmd_immget.obj \
		$(OBJDIR)/apos_cmd_getutil.obj


COVERAGE ?= no

# here you can add own compiler flags
ifeq ($(COVERAGE),yes)
CFLAGS += -O0 -fprofile-arcs -ftest-coverage
else
CFLAGS += -O3
endif

# here you can add own lib paths
LIBSDIR += -L$(AP_SDK_LIB)
LIBSDIR += -L$(COREMW_SDK_LIB)
LIBSDIR += -L$(ACE_SDK_LIB)

## # here you can add own libs
LIBS += -lrt -lpthread -lACE -lSaImmOm -lSaImmOi

## Object filebin
OBJ =   $(IMMGET_SRC:%.cpp=%.obj) \
		$(IMMGET_SRC:%.c=%.obj) 

## here you can add own File paths

IMMGET_APNAME = IMMGet

.PHONY: all CFLAGS += $(GCOV_FLAGS)

all:	$(OUTDIR)/$(IMMGET_APNAME)

$(OUTDIR)/$(IMMGET_APNAME):$(OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(IMMGET_APNAME)'
	$(CC) -o $(OUTDIR)/$(IMMGET_APNAME) $(IMMGET_OBJ) $(LIBSDIR) $(LIBS)
	$(call stripp,$(IMMGET_APNAME))
	$(SEPARATOR_STR)
	$(NEW_LINE)
	cp -f $(OUTDIR)/$(IMMGET_APNAME) $(PARMTOOLDIR)

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


