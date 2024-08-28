# **********************************************************************
#
# Short description:
# Makefile template for LDAP availability check binary
# **********************************************************************
#
# Ericsson AB 2016 All rights reserved.
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
#  A         2016-03-14   ealocae   Created
# **********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

MODULE_NAME = LDAP_CHECK
MODULE_VERSION = 1_0
MODULE_SEARCH = ./$(SRCDIR) ./$(INCDIR)
export DOXYGEN_OUTPUT
export MODULE_NAME
export MODULE_VERSION
export MODULE_SEARCH

# Setting the application name and path
OUTDIR = ./bin
APP_FILENAME = check_ldap_availability
APP_FILENAME_DBG = $(APP_FILENAME)_dbg

# List of the application object files
OBJECT_FILES = \
	$(OBJDIR)/common.obj \
	$(OBJDIR)/configuration_reader.obj \
	$(OBJDIR)/ldap_connector.obj \
	$(OBJDIR)/main.obj


# Dependencies list
CMD_DEPS := $(OBJECT_FILES:.obj=.d)

# List of include paths
CINCLUDES = -I"$(INCDIR)"
CINCLUDES += -I$(LOTC_SDK_INC) -I$(LOTC_SDK_CPP) -I$(LOTC_SDK_CPP)/x86_64-suse-linux

# List of compilers flags
EXTRA_DEFINES += 
CFLAGS += $(EXTRA_DEFINES) 
CFLAGS += -Wall -Wextra -Wcomments -g -std=c++11

# List of loader flags
LDFLAGS +=

# List of libraries path
LIBSDIR += -L$(LOTC_SDK_LIB)

# List of libraries to be added at linking time
LIBS += -lldap

VPATH += $(SRCDIR) $(OUTDIR) $(INCEXTDIR) $(INCINTDIR) $(INCDIR) $(OBJDIR)

# Compilation targets
.PHONY: all CFLAGS += $(GCOV_FLAGS)
all: $(OUTDIR)/$(APP_FILENAME)

$(OUTDIR)/$(APP_FILENAME): $(OBJECT_FILES)
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Creating Application: $(APP_FILENAME)'
	$(SILENT)$(CC) $(CFLAGS) -o $(OUTDIR)/$(APP_FILENAME) $(OBJECT_FILES) $(LDFLAGS) $(LIBSDIR) $(LIBS)
	$(call stripp,$(APP_FILENAME))
	$(SEPARATOR_STR)
	$(NEW_LINE)

.PHONY: clean
clean:
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Cleaning object files...'
	$(SILENT)$(RM) -r $(OBJDIR)/*.obj
	$(SILENT)$(ECHO) 'Cleaning dependencies files...'
	$(SILENT)$(RM) -r $(OBJDIR)/*.d
	$(SEPARATOR_STR)
	$(NEW_LINE)

.PHONY: distclean
distclean: clean
	$(NEW_LINE)
	$(SEPARATOR_STR)
	$(SILENT)$(ECHO) 'Cleaning binary files...'
	$(SILENT)$(RM) -r $(OUTDIR)/$(APP_FILENAME) $(DEBUGDIR)/$(APP_FILENAME_DBG)
	$(SEPARATOR_STR)
	$(NEW_LINE)


