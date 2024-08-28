# **********************************************************************
#
# Short description:
# Makefile for command date in CAA level
# **********************************************************************
#
# Ericsson AB 2012 All rights reserved.
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
# ---        ----         ----      ----
# R1A        2012-07-13   UABTSO    Created
#
#***********************************************************************

# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common


CNZ_NAME ?= date
CAA_NAME ?= datecmd_caa
CXC_NAME ?= date_cxc

# Basic paths
VOB_PATH = $(APOS_ROOT)
CNZ_PATH = $(VOB_PATH)/cmd_cnz/$(CNZ_NAME)
CAA_PATH = $(CNZ_PATH)/$(CAA_NAME)
CXC_PATH = $(CNZ_PATH)/$(CXC_NAME)

include $(COMMON_ROOT)/common.mk

DOXYGENFILECONFIG := $(COMMON_ROOT)/doxygen_common.conf 

CXC_PATH = $(CURDIR)/../date_cxc

BLOCKDIR = $(CAA_PATH)
OUTDIR   = $(CXC_PATH)/bin
OBJDIR	 = $(BLOCKDIR)/obj
SRCDIR	 = $(BLOCKDIR)/src
INCDIR	 = $(BLOCKDIR)/inc
TESTDIR  = $(BLOCKDIR)/test

OWNLIBDIR = $(OUTDIR)

# Flexelint application
FL    = $(LINT)     # Global wrap-up mode
FL1   = $(LINT) -u  # Single unit mode

# Here you can add own compiler flags
#CPPFLAGS += -g -O2 -Wall 

# Here you can add own lib paths
# This may need to be modified later once external libraries are available 
LIBSDIR += -L$(OWNLIBDIR)

# Here you can add own Assembler flags
ASMFLAGS += 

## Here you can add own Include paths and/or other includes
# This may need to be modified later once external libraries are available
CINCLUDES += -I$(INCDIR) -B$(INCDIR)

## Here you can add own libs
# This may need to be modified later once external libraries are available 
LIBS +=

## Here you can add own File paths
VPATH += $(SRCDIR) $(INCDIR) $(OUTDIR) $(OBJDIR)

## Source files and Object files

L_FILES += $(SRCFILES:%=$(BLOCKDIR)/src/%) 

SRCFILES = $(wildcard $(SRCDIR)/*.cpp)

SRCTOOBJ =  \
        $(patsubst %.cpp, %.obj, $(SRCFILES))
OBJMOD = $(subst src,obj,$(SRCTOOBJ))
CMD_OBJ = $(subst $(OBJDIR)/, ,$(OBJMOD))

## Build instructions

#.cpp.obj:
#	$(NEW_LINE)
#	$(SEPARATOR_STR)
#	$(SILENT)$(ECHO) 'Compiling file: $<'
#	$(CC) $(EXTRA_CFLAGS) $(GCOV_FLAGS) -c $(CFLAGS)  $(CINCLUDES) -I$(AP_SDK_INC) $< -o $(OBJDIR)/$(@F)
#	$(SEPARATOR_STR)

CMD_APNAME = apos_date
CMD_APEXE = $(OUTDIR)/$(CMD_APNAME)

.PHONY: all
all: $(CMD_APEXE)

$(OUTDIR)/$(CMD_APNAME): $(CMD_OBJ)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) "Linking $@..."
	$(SILENT)$(CC) -o $@ $(OBJMOD) $(LIBSDIR) $(LIBS)
	$(call stripp,$(CMD_APNAME))
	$(SEPARATOR_STR)
	$(NEW_LINE)

.PHONY: clean
clean:
	$(SILENT)$(ECHO) 'Cleaning files'
	$(SILENT)$(RM) $(OBJDIR)/*

.PHONY: distclean
distclean: clean
	$(SILENT)$(RM) -r $(OUTDIR)/$(CMD_APNAME)

# DO NOT DELETE THIS LINE -- make depend needs it

