#
# spec file for package openssh
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

# Copyright  (c)  2015  Ericsson LM
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# please send bugfixes or comments to paolo.palmieri@ericsson.com
#

# Default values for additional components
%define _build_x11_askpass_	0

# Define the UID/GID to use for privilege separation
%define _sshd_gid_	65
%define _sshd_uid_	71

# The openssh portable version
%define _version_ %{_prNr}
%define version 7.2p2

# The version of x11-ssh-askpass to use
%define _xversion_	1.2.4.1

# Allow the ability to override defaults with -D enable_xxx=1
%{?enable_x11_askpass:%define _build_x11_askpass_ 1}

# SuSE default values for installation directory paths
%define _prefixdir_ /usr
%define _bindir_ %{_prefixdir_}/bin
%define _sbindir_ %{_prefixdir_}/sbin
%define _mandir_ %{_prefixdir_}/share/man
%define _mansubdir_ man
%define _libdir_ %{_prefixdir_}/lib
%define _libexecdir_ %{_libdir_}/ssh
%define _privsepdir_ /var/lib/empty
%define _sshdhomedir_ /var/lib/sshd
%define _sysconfdir_ /etc
%define _sysconfsshdir_ %{_sysconfdir_}/ssh
%define _sysconfpamdir_ %{_sysconfdir_}/pam.d
%define _sysconfinitdir_ %{_sysconfdir_}/init.d

%define _admtemplatedir_ /var/adm/fillup-templates

%define _cnzdir_ %{_cxcdir}/../
%define _portabledir_ %{_cnzdir_}/portable_caa

Summary:   OpenSSH, a free Secure Shell (SSH) protocol implementation
Name:      %{_name}
Version:   %{_prNr}
URL:       http://www.openssh.com/
Release:   %{_rel}
Source0:	openssh-%{version}.tar.gz
Source1:	x11-ssh-askpass-%{_xversion_}.tar.gz
License:      BSD3c(or similar) ; MIT License (or similar)
Group:        Productivity/Networking/SSH
BuildRoot: %_tmppath
PreReq:     pwdutils %insserv_prereq  %fillup_prereq coreutils
Obsoletes: ssh
Provides:  ssh
Requires:     /bin/netstat
Conflicts:    nonfreessh
AutoReqProv:  on
Vendor:    Ericsson LM
Packager:  Nunziante Gaito <nunziante.gaito@ericsson.com>

#
# (Build[ing] Prereq[uisites] only work for RPM 2.95 and newer.)
# building prerequisites -- stuff for
#   OpenSSL (openssl-devel),
#   TCP Wrappers (tcpd-devel),
#   and Gnome (glibdev, gtkdev, and gnlibsd)
#
BuildPrereq:	openssl
BuildPrereq:	zlib-devel
#BuildPrereq:	tcpd-devel
#BuildPrereq:	glibdev
#BuildPrereq:	gtkdev
#BuildPrereq:	gnlibsd


%package	askpass
Summary:	A passphrase dialog for OpenSSH and the X window System.
Group:		Productivity/Networking/SSH
Requires:	openssh = %{_version_}
Obsoletes:	ssh-extras
Provides:	openssh:%{_libexecdir_}/ssh-askpass
License:    BSD3c(or similar) ; MIT License (or similar)

%if %{_build_x11_askpass_}
BuildPrereq:	XFree86-devel
%endif


%description
Ssh (Secure Shell) is a program for logging into a remote machine and for
executing commands in a remote machine.  It is intended to replace
rlogin and rsh, and provide secure encrypted communications between
two untrusted hosts over an insecure network.  X11 connections and
arbitrary TCP/IP ports can also be forwarded over the secure channel.

OpenSSH is OpenBSD's rework of the last free version of SSH, bringing it
up to date in terms of security and features, as well as removing all
patented algorithms to seperate libraries (OpenSSL).

This package includes all files necessary for both the OpenSSH
client and server.


%description askpass
Ssh (Secure Shell) is a program for logging into a remote machine and for
executing commands in a remote machine.  It is intended to replace
rlogin and rsh, and provide secure encrypted communications between
two untrusted hosts over an insecure network.  X11 connections and
arbitrary TCP/IP ports can also be forwarded over the secure channel.

OpenSSH is OpenBSD's rework of the last free version of SSH, bringing it
up to date in terms of security and features, as well as removing all
patented algorithms to seperate libraries (OpenSSL).

This package contains an X Window System passphrase dialog for OpenSSH.


%pre
getent group sshd >/dev/null || %{_sbindir_}/groupadd -o -r sshd
getent passwd sshd >/dev/null || %{_sbindir_}/useradd -r -g sshd -d %{_sshdhomedir_} -s /bin/false -c "SSH daemon" sshd


%install
#rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT%{_bindir_}
install -d $RPM_BUILD_ROOT%{_sbindir_}
install -d $RPM_BUILD_ROOT%{_libexecdir_}
install -d $RPM_BUILD_ROOT%{_sysconfsshdir_}
install -d -m 0755 $RPM_BUILD_ROOT%{_privsepdir_}
install -d -m 0755 $RPM_BUILD_ROOT%{_sshdhomedir_}
install -d -m 0755 $RPM_BUILD_ROOT%{_sysconfpamdir_}
install -d -m 0755 $RPM_BUILD_ROOT%{_sysconfinitdir_}
install -d -m 0755 $RPM_BUILD_ROOT%{_admtemplatedir_}

install -m 0755 %{_cxcdir}/bin/ssh $RPM_BUILD_ROOT%{_bindir_}/ssh
install -m 0755 %{_cxcdir}/bin/scp $RPM_BUILD_ROOT%{_bindir_}/scp
install -m 0755 %{_cxcdir}/bin/ssh-add $RPM_BUILD_ROOT%{_bindir_}/ssh-add
install -m 0755 %{_cxcdir}/bin/ssh-agent $RPM_BUILD_ROOT%{_bindir_}/ssh-agent
install -m 0755 %{_cxcdir}/bin/ssh-keygen $RPM_BUILD_ROOT%{_bindir_}/ssh-keygen
install -m 0755 %{_cxcdir}/bin/ssh-keyscan $RPM_BUILD_ROOT%{_bindir_}/ssh-keyscan
install -m 0755 %{_cxcdir}/bin/sshd $RPM_BUILD_ROOT%{_sbindir_}/sshd
install -m 4711 %{_cxcdir}/bin/ssh-keysign $RPM_BUILD_ROOT%{_libexecdir_}/ssh-keysign
install -m 0755 %{_cxcdir}/bin/ssh-pkcs11-helper $RPM_BUILD_ROOT%{_libexecdir_}/ssh-pkcs11-helper
install -m 0755 %{_cxcdir}/bin/sftp $RPM_BUILD_ROOT%{_bindir_}/sftp
install -m 0755 %{_cxcdir}/bin/sftp-server $RPM_BUILD_ROOT%{_libexecdir_}/sftp-server

rm -f $RPM_BUILD_ROOT%{_bindir_}/slogin
ln -s ssh $RPM_BUILD_ROOT%{_bindir_}/slogin

# Configuration installation
install -m 0644 %{_cxcdir}/suse/ssh_config $RPM_BUILD_ROOT%{_sysconfsshdir_}/
install -m 0644 %{_cxcdir}/suse/sshd_config $RPM_BUILD_ROOT%{_sysconfsshdir_}/
if [ -f $RPM_BUILD_ROOT%{_sysconfsshdir_}/primes ]
then
	echo "moving $RPM_BUILD_ROOT%{_sysconfsshdir_}/primes to $RPM_BUILD_ROOT%{_sysconfsshdir_}/moduli"
	mv "$RPM_BUILD_ROOT%{_sysconfsshdir_}/primes" "$RPM_BUILD_ROOT%{_sysconfsshdir_}/moduli"
else
	install -m 0644 %{_cxcdir}/suse/moduli $RPM_BUILD_ROOT%{_sysconfsshdir_}/
fi

# Check configuration is ok
#$RPM_BUILD_ROOT%{_sbindir_}/sshd -t -f $RPM_BUILD_ROOT%{_sysconfsshdir_}/sshd_config

install -m 0644 %{_cxcdir}/suse/sshd.pamd $RPM_BUILD_ROOT%{_sysconfpamdir_}/sshd
install -m 0755 %{_cxcdir}/suse/sshd.init $RPM_BUILD_ROOT%{_sysconfinitdir_}/sshd
install -m 0644 %{_cxcdir}/suse/sysconfig.ssh $RPM_BUILD_ROOT%{_admtemplatedir_}/

# install shell script to automate the process of adding your public key to a remote machine
install -m 0755 %{_portabledir_}/src/contrib/ssh-copy-id $RPM_BUILD_ROOT%{_bindir_}/

sed -i -e s@%{_prefixdir_}/libexec@%{_libexecdir_}@g $RPM_BUILD_ROOT%{_sysconfsshdir_}/sshd_config


%post
#%{_bindir_}/ssh-keygen -A
%{fillup_and_insserv -n ssh sshd}


%preun
%stop_on_removal sshd


%postun
%restart_on_update sshd
%{insserv_cleanup}


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root)
#%doc ChangeLog OVERVIEW README* PROTOCOL*
#%doc TODO CREDITS LICENCE
%attr(0755,root,root) %dir %{_libexecdir_}
%attr(0755,root,root) %dir %{_sysconfsshdir_}
%attr(0755,root,root) %dir %{_privsepdir_}
%attr(0755,root,root) %dir %{_sshdhomedir_}

%attr(0644,root,root) %config(noreplace) %{_sysconfsshdir_}/ssh_config
%attr(0644,root,root) %config(noreplace) %{_sysconfsshdir_}/sshd_config
%attr(0644,root,root) %config(noreplace) %{_sysconfsshdir_}/moduli
%attr(0644,root,root) %config(noreplace) %{_sysconfpamdir_}/sshd
%attr(0755,root,root) %config(noreplace) %{_sysconfinitdir_}/sshd
%attr(0644,root,root) %config(noreplace) %{_admtemplatedir_}/sysconfig.ssh

%attr(0755,root,root) %{_bindir_}/ssh-keygen
%attr(0755,root,root) %{_bindir_}/scp
%attr(0755,root,root) %{_bindir_}/ssh
%attr(0755,root,root) %{_bindir_}/ssh-agent
%attr(0755,root,root) %{_bindir_}/ssh-add
%attr(0755,root,root) %{_bindir_}/ssh-keyscan
%attr(0755,root,root) %{_bindir_}/sftp
%attr(0755,root,root) %{_sbindir_}/sshd
%attr(0755,root,root) %{_libexecdir_}/sftp-server
%attr(4711,root,root) %{_libexecdir_}/ssh-keysign
%attr(0755,root,root) %{_libexecdir_}/ssh-pkcs11-helper
%attr(-,root,root) %{_bindir_}/slogin
%attr(0755,root,root) %{_bindir_}/ssh-copy-id


%changelog

* Thu Mar 07 2024 - AC/DC 11.0.1
- Implemented the version 11.0.1. This version has the LDE baseline openssh-7.2p2-81.12.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.27

* Mon Jan 22 2024 - AC/DC 10.0.1
- Implemented the version 10.0.1. This version has the LDE baseline openssh-7.2p2-81.8.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.26

* Thu Aug 03 2023 - AC/DC 9.0.1
- Implemented the version 9.0.1. This version has the LDE baseline openssh-7.2p2-81.4.2.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.25

* Thu Jan 19 2023 - AC/DC 8.0.1
- Implemented the version 8.0.1. This version has the LDE baseline openssh-7.2p2-78.16.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.24

* Wed May 31 2021 - AC/DC 6.0.1
- Implemented the version 6.0.1. This version has the LDE baseline openssh-7.2p2-78.10.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.17

* Wed Nov 11 2020 - AC/DC 5.0.1 
- Implemented the version 5.0.1. This version has the LDE baseline openssh-7.2p2-74.54.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.15

* Fri Mar 13 2020 - Eagles 4.0.1 
- Implemented the version 4.0.1. This version has the LDE baseline openssh-7.2p2-74.45.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.11

* Mon Mar 04 2019 - RollingStones
- Implemented the version 3.0.2. This version has the LDE baseline openssh-7.2p2-74.39.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.8

* Wed Sep 13 2017 - AC/DC
- Implemented the version 3.0.1. This version has the LDE baseline openssh-7.2p2-74.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the LDE 4.3.

* Wed Jul 27 2016 - Turing
- Implemented the version 2.0.2. This version has the LDE baseline openssh-6.6p1-42.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the SLES12 LDE.

* Tue Nov 03 2015 - Sunrise
- Implemented the version 2.0.1. This version has the LDE baseline openssh-6.6p1-29.1.src.rpm
- to which we have applied the APG-specific changes. it has been compiled with the SLES12 LDE.

* Thu Apr 30 2015 - Turing
- Implemented the version 1.1.0. This version has the LDE baseline openssh-6.2p2p-0.13.1.src.rpm
- to which we have applied the APG-specific changes.

* Mon Apr 23 2012 - Caravaggio
- Initial implementation
