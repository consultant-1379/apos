# **********************************************************************
#
# Short description:
# Makefile template for DSD Private Implementation Library
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
#            2010-02-19   teiggam   Created
#            2010-07-30   xnicmut   Adjusted
#            2010-11-19   xgencol   Adjusted
# **********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

MODULE_NAME = NSS_UFBS_CMD
MODULE_VERSION = 1_0
MODULE_SEARCH = ./$(SRCDIR) ./inc
export DOXYGEN_OUTPUT
export MODULE_NAME
export MODULE_VERSION
export MODULE_SEARCH

## Object files
NSS_UFBS_OBJS = \
	$(OBJDIR)/TUfbsHandler.obj \
	$(OBJDIR)/TDbHandler.obj \
	$(OBJDIR)/TConfigFile.obj \
	$(OBJDIR)/TString.obj \
	$(OBJDIR)/main.obj

## Dependencies
#NSS_UFBS_SET_DEPS := $(NSS_UFBS_OBJS:.obj=.d)

OUTDIR = ../nss_cxc/bin

ifneq ($(MAKECMDGOALS),clean)
#include $(NSS_UFBS_DEPS)
endif

## Application Command Names
NSS_UFBS_APPNAME := nss_ufbs

NSS_UFBS_CMDNAME := $(NSS_UFBS_APPNAME)

NSS_UFBS_CMDNAME_DBG := $(NSS_UFBS_APPNAME)_dbg

## here you can add own lib paths
#LIBSDIR += -L"$(CXCPATH)/bin/lib_ext"
#LIBSDIR += -L"$(AP_SDK_LIB)"
#LIBSDIR += -L"$(3PP_SDK_PATH)/log4cplus/lib"
#LIBSDIR += -L"$(3PP_SDK_PATH)/libXerces/lib64"

## here you can add own compiler flags
CFLAGS += -Wno-empty-body

# here you can add own linker flags
LDFLAGS +=

#EXTRA_DEFINES += -DBS_DEBUG -DCSNOTWORKINGFORCBA
#EXTRA_DEFINES += -g -DACS_APBM_HAS_TRACE -DACS_APBM_TRACE_HAS_FUNCTION_TRACE -DACS_APBM_TRACE_USE_PRETTY_FUNCTION -DACS_APBM_TRACE_USE_FILE_INFO

# here you can add more defines
EXTRA_CFLAGS += -Wextra $(EXTRA_DEFINES)

# here you can add own Include paths and/or other includes before those included by common.mk file
CINCLUDES += -I"inc"

NSS_UFBS_APEXE = $(OUTDIR)/$(NSS_UFBS_CMDNAME)

# here you can add own libs
#LIBS += -lrt -lpthread -lacs_tra -llog4cplus -lnetsnmp -lacs_csapi -lacs_apgcc -lxerces-c -lxerces-depdom -lacs_dsd -lacs_apbm -lacs_apbmpip
LIBS += -lrt -lpthread -lstdc++ -ldl 

VPATH += $(SRCDIR) $(OUTDIR) $(INCEXTDIR) $(INCINTDIR) inc $(OBJDIR)

.PHONY: all CFLAGS += $(GCOV_FLAGS)
all:	$(OUTDIR)/$(NSS_UFBS_APPNAME)

$(OUTDIR)/$(NSS_UFBS_APPNAME): $(NSS_UFBS_OBJS)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(NSS_UFBS_CMDNAME)'
	$(SILENT)$(CC) $(CFLAGS) -o $(NSS_UFBS_APEXE) $(NSS_UFBS_OBJS) $(LDFLAGS) $(LIBSDIR) $(LIBS)
	$(call stripp,$(NSS_UFBS_APPNAME))
	$(SEPARATOR_STR)
	$(NEW_LINE)

#$(OUTDIR)/$(APBM_HWICONF_APPNAME): APP_NAME := $(APBM_HWICONF_CMDNAME)
#$(OUTDIR)/$(APBM_HWICONF_APPNAME): OUTPUT_FILE := $(OUTDIR)/$(APBM_HWICONF_CMDNAME)
#$(OUTDIR)/$(APBM_HWICONF_APPNAME): OBJ_FILES := $(APBM_HWICONF_OBJS)
#$(OUTDIR)/$(APBM_HWICONF_APPNAME): $(APBM_HWICONF_OBJS)
#$(call build_application,$(APP_NAME),$(OUTPUT_FILE),$(OBJ_FILES))

.PHONY: clean
clean:
	$(RM) -r $(OBJDIR)/*.obj
	$(RM) -r $(OBJDIR)/*.d

.PHONY: distclean

distclean: clean
	$(RM) -r $(OUTDIR)/$(NSS_UFBS_CMDNAME)

####################
# $(call build_application,AppName,OutpuFile,ObjectFiles)
define build_application
$(NEW_LINE)
$(SEPARATOR_STR)
$(SILENT)$(ECHO) 'Building Application: $1'
$(SILENT)$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $2 $3 $(LDFLAGS) $(LIBSDIR) $(LIBS)
$(SEPARATOR_STR)
$(NEW_LINE)
endef
