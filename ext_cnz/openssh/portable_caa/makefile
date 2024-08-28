# **********************************************************************
#
# Short description:
# Makefile template for OpenSSH Private Implementation
# **********************************************************************
#
# Ericsson AB 2010 All rights reserved.
# The information in this document is the property of Ericsson.
# Except as specifically authorized in writing by Ericsson, the receiver of this
# document shall keep the information contained herein confidential and shall protect
# the same in whole or in part from disclosure and dissemination to third parties.
# Disclosure and disseminations to the receivers employees shall only be made
# on a strict need to know basis.F
#
# **********************************************************************
#
# Rev        Date         Name      What
# -----      -------      --------  --------------------------
#            2010-02-19   teiggam   Created
#            2010-07-30   xnicmut   Adjusted
#            2010-11-19   xgencol   Adjusted
#            2015-11-02   enungai   Changes to support the new version Openssh 6.6 p1 
#            2019-03-11   xpraupp   Changes to support the new version Openssh 7_2 p2
#            2020-03-13   xdakanj   Changes to support the new version OPenssh 7_2 P2
#            2020-11-12   xbippol   Changes to support the new version OPenssh 7_2 P2
# **********************************************************************

# uncomment if you run a non bourne compatable shell. Ie. csh
#SHELL = /usr/bin/sh

# BEGIN: GIT INTRO.
CURDIR = $(shell pwd)
REPO_NAME = apos
APOS_ROOT = $(shell echo $(CURDIR) | sed 's@'/$(REPO_NAME)'.*@'/$(REPO_NAME)'@g')
COMMON_ROOT = $(APOS_ROOT)/common

include $(COMMON_ROOT)/common.mk

#LDE_VERSION=4_8
DX_VERSION=1_13

MODULE_NAME = OpenSSH_P2
export MODULE_NAME

MODULE_VERSION = 7_2_P2
export MODULE_VERSION

#LDFLAGS := -L${AFS_SDK}/LDE/${LDE_VERSION}/lib64 -L${AFS_SDK}/LDE/${LDE_VERSION}/lib
#GCC := ${AFS_SDK}/dx_btd/${DX_VERSION}/compilers/bin/x86_64-dx-linux-gnu-gcc
#CC := ${GCC}
#AFS_SDK ?= /app/APG43L/SDK

CC=${AFS_SDK}/dx_btd/${DX_VERSION}/compilers/bin/x86_64-dx-linux-gnu-gcc
LD=${AFS_SDK}/dx_btd/${DX_VERSION}/compilers/bin/x86_64-dx-linux-gnu-gcc
CFLAGS=-g -O2 -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wsizeof-pointer-memaccess -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -DERICSSON_PATCH_ENABLED=1 -ftrapv -fno-builtin-memset -fstack-protector-all -fPIE 
CPPFLAGS=-I. -I$(srcdir) ${APGINCLUDE} -DLDAP_DEPRECATED $(PATHS) -DHAVE_CONFIG_H
LIBS=-lcrypto -ldl -lldap -llber -lutil -lz  -lcrypt -lresolv
K5LIBS=
GSSLIBS=
SSHLIBS=
SSHDLIBS= -laudit -lpam
LIBEDIT=
AR=${AFS_SDK}/dx_btd/${DX_VERSION}/compilers/bin/x86_64-dx-linux-gnu-ar
AWK=${AFS_SDK}/LDE/${LDE_VERSION}/bin/gawk
RANLIB=${AFS_SDK}/dx_btd/${DX_VERSION}/compilers/bin/x86_64-dx-linux-gnu-ranlib
INSTALL=${AFS_SDK}/LDE/${LDE_VERSION}/usr/bin/install -c
PERL=${AFS_SDK}/LDE/${LDE_VERSION}/usr/bin/perl
SED=${AFS_SDK}/LDE/${LDE_VERSION}/bin/sed
ENT=
XAUTH_PATH=/usr/bin/xauth
LDFLAGS=-L. -Lopenbsd-compat/ -L${AFS_SDK}/LDE/${LDE_VERSION}/lib64 -L${AFS_SDK}/LDE/${LDE_VERSION}/lib -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -fstack-protector-all -pie
EXEEXT:=
MANFMT=/usr/bin/nroff -mandoc

export CC
export LD
export AR
export AWK
export RANLIB
export INSTALL
export PERL
export SED
export XAUTH_PATH
export EXEEXT
export MANFMT

OPENSSH_ROOT_DIR := src/

OPENSSH_TARGETS := ssh${EXEEXT} sshd${EXEEXT} ssh-add${EXEEXT} ssh-keygen${EXEEXT}\
	ssh-keyscan${EXEEXT} ssh-keysign${EXEEXT} ssh-pkcs11-helper${EXEEXT} ssh-agent${EXEEXT}\
	scp${EXEEXT} sftp-server${EXEEXT} sftp${EXEEXT} ssh-ldap-helper${EXEEXT}

OPENSSH_TARGETS_FULL := ${OPENSSH_ROOT_DIR}ssh${EXEEXT} ${OPENSSH_ROOT_DIR}sshd${EXEEXT}\
	${OPENSSH_ROOT_DIR}ssh-add${EXEEXT} ${OPENSSH_ROOT_DIR}ssh-keygen${EXEEXT}\
	${OPENSSH_ROOT_DIR}ssh-keyscan${EXEEXT} ${OPENSSH_ROOT_DIR}ssh-keysign${EXEEXT}\
	${OPENSSH_ROOT_DIR}ssh-pkcs11-helper${EXEEXT} ${OPENSSH_ROOT_DIR}ssh-agent${EXEEXT}\
	${OPENSSH_ROOT_DIR}scp${EXEEXT} ${OPENSSH_ROOT_DIR}sftp-server${EXEEXT}\
	${OPENSSH_ROOT_DIR}sftp${EXEEXT} ${OPENSSH_ROOT_DIR}ssh-ldap-helper${EXEEXT}

#	${OPENSSH_ROOT_DIR}cavstest-ctr${EXEEXT} ${OPENSSH_ROOT_DIR}cavstest-kdf${EXEEXT}

APG_TARGETS := ${OUTDIR}/ssh${EXEEXT} ${OUTDIR}/sshd${EXEEXT} ${OUTDIR}/ssh-add${EXEEXT}\
	${OUTDIR}/ssh-keygen${EXEEXT} ${OUTDIR}/ssh-keyscan${EXEEXT} ${OUTDIR}/ssh-keysign${EXEEXT}\
	${OUTDIR}/ssh-pkcs11-helper${EXEEXT} ${OUTDIR}/ssh-agent${EXEEXT} ${OUTDIR}/scp${EXEEXT}\
	${OUTDIR}/sftp-server${EXEEXT} ${OUTDIR}/sftp${EXEEXT} ${OUTDIR}/ssh-ldap-helper${EXEEXT}

#	${OUTDIR}/cavstest-ctr${EXEEXT} ${OUTDIR}/cavstest-kdf${EXEEXT}

TARGETS := ${APG_TARGETS}

LIBCOMPAT_A := ${LIB_INT}/libopenbsd-compat.a
LIBSSH_A := ${LIB_INT}/libssh.a

.PHONY: all
all: make_openssh copy_targets

.PHONY: make_openssh
make_openssh:
	(cd ${OPENSSH_ROOT_DIR} && $(MAKE))

.PHONY: copy_targets
copy_targets:
	${CP} -f ${OPENSSH_ROOT_DIR}openbsd-compat/libopenbsd-compat.a ${LIBCOMPAT_A}
	${CP} -f ${OPENSSH_ROOT_DIR}libssh.a ${LIBSSH_A}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh${EXEEXT} ${OUTDIR}/ssh${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}sshd${EXEEXT} ${OUTDIR}/sshd${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-add${EXEEXT} ${OUTDIR}/ssh-add${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-keygen${EXEEXT} ${OUTDIR}/ssh-keygen${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-keyscan${EXEEXT} ${OUTDIR}/ssh-keyscan${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-keysign${EXEEXT} ${OUTDIR}/ssh-keysign${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-pkcs11-helper${EXEEXT} ${OUTDIR}/ssh-pkcs11-helper${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-agent${EXEEXT} ${OUTDIR}/ssh-agent${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}scp${EXEEXT} ${OUTDIR}/scp${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}sftp-server${EXEEXT} ${OUTDIR}/sftp-server${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}sftp${EXEEXT} ${OUTDIR}/sftp${EXEEXT}
	${CP} -f ${OPENSSH_ROOT_DIR}ssh-ldap-helper${EXEEXT} ${OUTDIR}/ssh-ldap-helper${EXEEXT}

.PHONY: clean
clean:
	(cd ${OPENSSH_ROOT_DIR} && $(MAKE) clean)

#	${RM} -r ${OBJDIR}/*.obj
#	${RM} -r ${OBJDIR}/*.d
#	${RM} -r ${OBJDIR}/openbsd-compat/*.obj
#	${RM} -r ${OBJDIR}/openbsd-compat/*.d

#	$(RM) -r openbsd-compat/$(OBJDIR)/*.obj
#	$(RM) -r openbsd-compat/$(OBJDIR)/*.d

.PHONY: distclean
distclean: clean
	${RM} -r ${LIB_INT}/*
	${RM} -r ${LIB_EXT}/*
	${RM} -r ${OUTDIR}/ssh${EXEEXT}
	${RM} -r ${OUTDIR}/sshd${EXEEXT}
	${RM} -r ${OUTDIR}/scp${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-add${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-agent${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-keygen${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-keysign${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-pkcs11-helper${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-keyscan${EXEEXT}
	${RM} -r ${OUTDIR}/sftp-server${EXEEXT}
	${RM} -r ${OUTDIR}/sftp${EXEEXT}
	${RM} -r ${OUTDIR}/ssh-ldap-helper${EXEEXT}

