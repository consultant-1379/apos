# **********************************************************************
#
# Short description:
# Makefile for sinetcc command
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
#            2016-11-08   ealocae   Updated to use the right compiler version
#            2016-03-02   xclaele   Created
# **********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CC = /app/vbuild/SLED11-x86_64/gcc/4.8.4/bin/gcc
CFLAGS += -m32 -Wall
VPATH = sinetcc/src
OUTDIR = ../tinycore_cxc/bin
CMD_NAME = sinetcc
CORE_NAME = core.gz
CMD_BIN = $(OUTDIR)/$(CMD_NAME)

all: $(CMD_NAME)

.c:
	@echo Compiling $<
	$(CC) $(CFLAGS) $< -g -o $(CMD_BIN)
	
clean:
	@echo Nothing to clean

