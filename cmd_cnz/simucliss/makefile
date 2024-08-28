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
#            2014-01-28   estevol   Created
# **********************************************************************
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

DOXYGENFILECONFIG := $(COMMON_ROOT)/doxygen_common.conf

MODULE_NAME = SIMUCLISS
MODULE_VERSION = 2_0
MODULE_SEARCH = ./$(SRCDIR) ./inc
export DOXYGEN_OUTPUT
export MODULE_NAME
export MODULE_VERSION
export MODULE_SEARCH


OUTDIR = ./bin

CREATEDIR := $($(mkdir) -p $(OBJDIR))


## Object files
#NCGET_FILES = /vobs/cm4ap/ntacs/apbm_cnz/apbmadm_caa/obj
#NCGET_MOREHEADERFILES = /vobs/cm4ap/ntacs/apbm_cnz/apbmadm_caa/inc

CMD_OBJS = \
	$(OBJDIR)/simucliss.obj \


## Dependencies

CMD_DEPS := $(CMD_OBJS:.obj=.d)

ifeq "$(wildcard $(OBJDIR))" ""
	-include $(shell mkdir -p $(OBJDIR))
endif

ifneq ($(MAKECMDGOALS),clean)
	-include $(CMD_DEPS)
endif

## Application Command Names
CMD_APPNAME := simucliss

#APBM_HWICONF_CMDNAME := $(APBM_HWICONF_APPNAME)
CMD_NAME := $(CMD_APPNAME)


CMD_NAME_DBG := $(CMD_APPNAME)_dbg


## here you can add own lib paths
LIBSDIR = -L$(LOTC_SDK_LIB)

## here you can add own compiler flags
CFLAGS += -Wno-empty-body

# here you can add own linker flags
LDFLAGS += 

EXTRA_DEFINES += -DBS_DEBUG
EXTRA_DEFINES += -g 

# here you can add more defines
EXTRA_CFLAGS += -Wextra $(EXTRA_DEFINES)

# here you can add own Include paths and/or other includes before those included by common.mk file
CINCLUDES = -I"inc"
CINCLUDES += -I$(ACE_SDK_INC) 
CINCLUDES += -I$(LOTC_SDK_INC)
CINCLUDES += -I$(LOTC_SDK_INC)/c++/4.3
CINCLUDES += -I$(LOTC_SDK_INC)/c++/4.3/x86_64-suse-linux

CMD_APEXE = $(OUTDIR)/$(CMD_NAME)

# here you can add own libs
LIBS = -lstdc++ -lrt -lpthread -lreadline

VPATH += $(SRCDIR) $(OUTDIR) $(INCEXTDIR) $(INCINTDIR) inc $(OBJDIR)

CFLAGS += $(GCOV_FLAGS)

.PHONY: all 
all:	$(OUTDIR)/$(CMD_APPNAME) \
		
$(OUTDIR)/$(CMD_APPNAME): $(CMD_OBJS)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(CMD_NAME)'
	$(SILENT)$(CC) $(CFLAGS) -o $(CMD_APEXE) $(CMD_OBJS) $(LDFLAGS) $(LIBSDIR) $(LIBS)
	$(call stripp,$(CMD_APPNAME))
	$(SEPARATOR_STR)
	$(NEW_LINE)


.PHONY: clean
clean:
	$(RM) -r $(OBJDIR)/*.obj
	$(RM) -r $(OBJDIR)/*.d

.PHONY: distclean

distclean: clean
	$(RM) -r $(OUTDIR)/$(CMD_NAME)


####################
# $(call build_application,AppName,OutpuFile,ObjectFiles)
#define build_application
#$(NEW_LINE)
#$(SEPARATOR_STR)
#$(SILENT)$(ECHO) 'Building Application: $1'
#$(SILENT)$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $2 $3 $(LDFLAGS) $(LIBSDIR) $(LIBS)
#$(SEPARATOR_STR)
#$(NEW_LINE)
#endef
