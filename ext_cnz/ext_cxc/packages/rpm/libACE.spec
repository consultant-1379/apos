##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Spec file for installation of libACE
#
##

# The following 2 lines disable the automatic resolution of "Requires" and "Provides" tags
%define __find_requires %{nil}
%define __find_provides %{nil}

%define packer %(finger -lp `echo "$USER"` | head -n 1 | cut -d: -f 3)
#%define _topdir /var/tmp/%(echo "$USER")/rpms/libACE
%define _topdir /var/tmp/%(echo "$USER")/rpms
%define _tmppath %_topdir/tmp
%define _builddir $RPM_BUILD_ROOT
#%define _target /opt/ap/apos/lib64
%define _target /opt/ap/apos/lib64
%define _link_target /usr/lib64

%define a_version	%(echo $LIBACE_A_VER)
%define b_version	%(echo $LIBACE_B_VER)
%define c_version	%(echo $LIBACE_C_VER)
%define version 	%{a_version}.%{b_version}.%{c_version}
%define release		%(echo $LIBACE_REL)

Name:      libACE
Summary:   Installation package for ACE framework.
Version:   %{version}
Release:   %{release}
License:   Ericsson Proprietary
Vendor:    Ericsson LM
Packager:  %packer
Group:     Library
BuildRoot: %_tmppath
#BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build


%description
Installation package for ACE Framework.


%install
mkdir -p %{_builddir}/%{_target}
install -m 554 /app/APG43L/SDK/3pp/ACE/%{a_version}_%{b_version}_%{c_version}/ACE_wrappers/ace/libACE.so.%{version} %{_builddir}/%{_target}/libACE.so.%{version}
# install -m 554 /app/APG43L/SDK/3pp/ACE/6_1_6/ACE_wrappers/ace/libACE.so.6.1.6 /var/tmp/eginsan/rpms//opt/ap/apos/lib64/libACE.so.6.1.6


%files
%defattr(-,root,root)
/opt/ap/apos/lib64/libACE.so.%{version}


%pre
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during installation phase"
elif [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during upgrade phase"
fi


%post
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} postinstall script during installation phase"
	echo "Creating libACE symbolic links"
	pushd %{_link_target} &>/dev/null
	ln -sf %{_target}/libACE.so.%{version} libACE.so.%{version}
	ln -sf %{_target}/libACE.so.%{version} libACE.so.%{a_version}
	ln -sf %{_target}/libACE.so.%{version} libACE.so
	popd &>/dev/null
elif [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} postinstall script during upgrade phase"	
	echo "Updating libACE symbolic links"
	pushd %{_link_target} &>/dev/null
	rm -f libACE.so*
	ln -sf %{_target}/libACE.so.%{version} libACE.so.%{version}
	ln -sf %{_target}/libACE.so.%{version} libACE.so.%{a_version}
	ln -sf %{_target}/libACE.so.%{version} libACE.so
	popd &>/dev/null
fi


%preun
if [ $1 == 0 ]; then
	echo "This is the %{name}-%{version} package %{release} preuninstall script during uninstall phase"
elif [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} preuninstall script during upgrade phase"
fi


%postun
if [ $1 == 0 ]; then
	echo "This is the %{name}-%{version} package %{release} postuninstall script during uninstall phase"
elif [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} postuninstall script during upgrade phase"
fi


%changelog
* Wed May 08 2013 - phaninder.g (at) tcs.com
- Changed version to 6.1.6
* Mon Apr 15 2013 - francesco.rainone (at) ericsson.com
- Changes in symlinks handling.
* Wed Feb 13 2013 - francesco.rainone (at) ericsson.com
- Changed version to 6.1.6
* Mon Oct 29 2012 - francesco.rainone (at) ericsson.com
- Symlink handling updated.
* Tue Sep 25 2012 - francesco.rainone (at) ericsson.com
- Changed version to 6.1.4
* Wed Aug 08 2012 - gerardo.petti (at) ericsson.com
- Changed version to 6.1.3
* Thu Jan 19 2012 - paolo.palmieri (at) ericsson.com
- Changed version to 5.8.1-0.5 to track build with new LOTC and DX starting from APOS R1A14.
* Tue Oct 18 2011 - paolo.palmieri (at) ericsson.com
- Changed version to 5.8.1-0.4 to track build with new LOTC and DX.
* Mon Jan 24 2011 - paolo.palmieri (at) ericsson.com
- Moved to /opt/ap/apos/lib64/ and changed version to 5.8.1-0.3.
* Mon Dec 20 2010 - paolo.palmieri (at) ericsson.com
- Change version from 5.8.1-0.1 to 5.8.1-0.2 on LOTC 3.0.7 (PRA)
* Fri Nov 05 2010 - paolo.palmieri (at) ericsson.com
- Change version from 5.8.0 to 5.8.1-0.1 on LOTC 3.0.3
* Wed Aug 11 2010 - giovanni.gambardella (at) ericsson.com
- Change version from 5.7.0 to 5.8.0
* Tue Jul 01 2010 - giovanni.gambardella (at) ericsson.com
- Initial implementation
