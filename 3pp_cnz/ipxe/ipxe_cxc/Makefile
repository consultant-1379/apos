# **********************************************************************
#
# Short description:
# Makefile for iPXE ISO
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
#
# **********************************************************************

CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

CXC_NAME := IPXE
CXC_NR := CXC1371529_19
CXC_VER := R1A

#IPXE MAKEFILE PARAMETERS
SCRIPT_DIR := scripts
BIN_DIR := bin
OUT_DIR := bin
ISO_BIN := ipxe.iso
KKPXE_BIN := undionly.kkpxe

#APZ IPXE MAKEFILE PARAMETERS
IPXE_VM_SCRIPT := ipxe_vm.ipxe
IPXE_VM := IPXE_VM_$(CXC_NR)_$(CXC_VER).iso
VPXE_SCRIPT := vpxelinux.ipxe
VPXE := vpxelinux.0
IPXE_SRC_DIR := ipxe_caa
IPXE_CXC_DIR := ipxe_cxc

.PHONY: all
all: ipxe_vm

#Create ipxe_vm 
.PHONY: ipxe_vm
ipxe_vm:
	@$(SILENT)cd ../$(IPXE_SRC_DIR); \
	$(MAKE) EMBED=$(SCRIPT_DIR)/$(IPXE_VM_SCRIPT) $(BIN_DIR)/$(ISO_BIN); \
	if [ $$? != 0 ]; \
		then $(ECHO) "Error: please see the printout !!! $$?"; \
		exit 3; \
	else \
		cp $(BIN_DIR)/$(ISO_BIN) ../$(IPXE_CXC_DIR)/$(OUT_DIR)/$(IPXE_VM); \
		exit 0; \
	fi; \

#Create vpxelinux.0
#.PHONY: vpxelinux
#vpxelinux:
#	@$(SILENT)rm $(OUT_DIR)/$(VPXE); \
#	$(SILENT)cd src; \
#	$(MAKE) EMBED=$(SCRIPT_DIR)/$(VPXE_SCRIPT)  $(BIN_DIR)/$(KKPXE_BIN); \
#	if [ $$? != 0 ]; \
#		then $(ECHO) "Error: please see the printout !!! $$?"; \
#		exit 3; \
#	else \
#		cp $(BIN_DIR)/$(KKPXE_BIN) ../$(OUT_DIR)/$(VPXE); \
#		exit 0; \
#	fi; \

.PHONY: clean
clean:
	@$(SILENT)cd ../$(IPXE_SRC_DIR); \
	$(MAKE) veryclean; \
	if [ $$? != 0 ]; \
		then $(ECHO) "Error: please see the printout !!! $$?"; \
		exit 3; \
	else \
		exit 0; \
	fi; \
# DO NOT DELETE THIS LINE -- make depend needs it

