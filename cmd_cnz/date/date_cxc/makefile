# **********************************************************************
#
# Short description:
# Makefile for date at CXC level
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
# R1A        2012-06-28   UABTSO    Created
# R1A        2018-03-06   EGINSAN   Adaptation to SwM2.0
#
# **********************************************************************
CXC_NR ?= CXC137???_6
CXC_VER ?= R1A1
CXC_OLD_VER ?=R1A0
CXC_NAME ?= date
BLOCK_NAME=$(CXC_NAME)

# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk 
CXCPATH = $(APOS_ROOT)/cmd_cnz/date/date_cxc
CXCDIR=$(CXCPATH)
CAA_DIRS = $(APOS_ROOT)/cmd_cnz/date/datecmd_caa

.PHONY: all
all:
	@for i in $(CAA_DIRS) ; do \
	(echo "+++++++++++++++++" ; \
	echo "cd $$i" ; \
	cd $$i ; \
	$(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) all) ;\
	if [ $$? != 0 ];\
	then  $(ECHO) "Error:Please see the printout!!!";\
	exit $$?;\
	fi;\
	echo "+++++++++++++++++" ; \
	done
# !!! "make release" shouldn't be executed since the rpm creation buildscript might need a change ??check

.PHONY: release
release: all rpm_package sdp_package tar_package ap_sdk documentation metrics

.PHONY: nightbuild
nightbuild: prebuild distclean all rpm_package sdp_package documentation metrics undobuild

.PHONY: rpm_package
rpm_package:
	$(call rpm_file_creation,clh.spec,$(CXC_NAME),$(CXC_NR),$(CXC_VER))

.PHONY: sdp_package
sdp_package:
	$(call sdp_creation_US3,$(CXCPATH),$(CXC_NAME),$(CXC_VER),$(CXC_OLD_VER),$(CXC_NR))

.PHONY: tar_package
tar_package:
	$(call tar_creation,$(BLOCK_NAME),$(CXC_NR),$(CXC_VER))


.PHONY: documentation
documentation:
	$(SILENT)$(ECHO) ' Removing ./docgen directory'
	$(SILENT)$(RM) -r -f ./docgen
	$(SILENT)$(ECHO) ' Creating ./docgen directory'
	$(SILENT)mkdir ./docgen
	$(SILENT)$(DOXYGEN) $(DOXYGENFILECONFIG)

.PHONY: metrics
metrics:
	@for i in $(CAA_DIRS) ; do \
                (echo "+++++++++++++++++" ; \
                 echo "cd $$i" ; \
                cd $$i ; \
                $(MAKE) $(MFLAGS) metrics ) ;\
                echo "+++++++++++++++++" ; \
        done

.PHONY: clean
clean:
	@for i in $(CAA_DIRS) ; do \
                (echo "+++++++++++++++++" ; \
                 echo "cd $$i" ; \
                 cd $$i ; \
                 $(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) clean ) ;\
                 echo "+++++++++++++++++" ; \
        done

.PHONY: distclean
distclean:
	@for i in $(CAA_DIRS) ; do \
                (echo "+++++++++++++++++" ; \
                 echo "cd $$i" ; \
                 cd $$i ; \
                 $(MAKE) $(MFLAGS) CXCDIR=$(CXCPATH) distclean ) ;\
                 echo "+++++++++++++++++" ; \
        done

.PHONY: ap_sdk
ap_sdk:
	$(SILENT)$(ECHO) 'AP SDK updating ...'
	$(SILENT)$(ECHO) '**********************************'
	$(SILENT)$(ECHO) '****** NOT YET IMPLEMENTED *******'
	$(SILENT)$(ECHO) '**********************************'

.PHONY: help
help:
	$(SILENT)$(ECHO) 'Cleaning targets'\
        $(SILENT)$(ECHO) '  clean         - Removes intermediary files generated during the compilation'\
        $(SILENT)$(ECHO) '  distclean     - Removes anything generated during the compilation, to start allow a fresh start'\
        $(SILENT)$(ECHO) 'Other generic targets'\
        $(SILENT)$(ECHO) '  all           - Build all targets'\
        $(SILENT)$(ECHO) '  release       - Build all targets and create rpm, sdp, ...'\
        $(SILENT)$(ECHO) '  Execute "make" or "make all" to build all targets '\
        $(SILENT)$(ECHO) '  make BUILD_VERBOSE=0|1 [targets] 0 => quiet build (default), 1 => verbose build'\
        $(SILENT)$(ECHO) '  make COVERAGE=0|1 [targets] 0 => no coverage (default), 1 => coverage options'\
        $(SILENT)$(ECHO) '  make LINT=0|1   [targets] Check all c source with $$CHECK )'\

.PHONY: print_build_envs
print_build_envs:
	$(SILENT)$(ECHO) ' Build Verbose is $(V)'
	$(SILENT)$(ECHO) ' Build Verbose is $(SILENT)'
	$(SILENT)$(ECHO) ' Build Verbose is $(quiet)'
	$(SILENT)$(SEPARATOR_STR)
	$(SILENT)$(ECHO) $(AS)
	$(SILENT)$(ECHO) $(LD)
	$(SILENT)$(ECHO) $(CC)
	$(SILENT)$(ECHO) $(CPP)
	$(SILENT)$(ECHO) $(NM)
	$(SILENT)$(ECHO) $(STRIP)
	$(SILENT)$(ECHO) $(OBJCOPY)
	$(SILENT)$(ECHO) $(OBJDUMP)
	$(SILENT)$(ECHO) $(AWK)
	$(SILENT)$(ECHO) $(PERL)
	$(SILENT)$(ECHO) $(AS)
	$(SILENT)$(ECHO) $(RM)
	$(SILENT)$(ECHO) $(TOUCH)
	$(SILENT)$(ECHO) $(CHECK)
	$(SILENT)$(ECHO) $(LINT)
	$(SILENT)$(ECHO) $(DOXYGEN)
	$(SILENT)$(ECHO) $(CCCC)
	$(SILENT)$(ECHO) $(SLOCCOUNT)
	$(SILENT)$(ECHO) $(CONFIG_SHELL)
	$(SILENT)$(ECHO) $(PWD)
	$(SILENT)$(SEPARATOR_STR)

.PHONY: debug
debug:  print_build_envs
	$(SILENT)$(ECHO) $(srctree)
	$(SILENT)$(ECHO) $(objtree)
	$(SILENT)$(ECHO) $(src)
	$(SILENT)$(ECHO) $(obj)
	$(SILENT)$(ECHO) $(VPATH)
	$(SILENT)$(ECHO) $(CXCPATH)
