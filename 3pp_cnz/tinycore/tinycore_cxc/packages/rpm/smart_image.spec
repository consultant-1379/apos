#
# spec file for configuration of package apache
#
# Copyright  (c)  2015  Ericsson LM
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# please send bugfixes or comments to paolo.palmieri@ericsson.com
#

Name:      %{_name}
Summary:   Installation package for Smart Image.
Version:   %{_prNr}
Release:   %{_rel}
License:   Ericsson Proprietary
Vendor:    Ericsson LM
Packager:  %packer
Group:     Library
BuildRoot: %_tmppath
Requires: APOS_OSCONFBIN

#BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build

%define _SMART_IMAGE default/

%define tinycore_cxc_bin %{_cxcdir}/bin

%description
Installation package for Smart Image.

%pre


%install
echo "Installing Smart Image package"

mkdir -p $RPM_BUILD_ROOT/opt/ap/apos/conf/tinycore

cp -avrf %tinycore_cxc_bin/smart_image/%_SMART_IMAGE $RPM_BUILD_ROOT/opt/ap/apos/conf/tinycore/

%post
if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-install script during installation phase"
fi
if [ $1 == 2 ]
then
        echo "This is the %{_name} package %{_rel} post-install script during upgrade phase"
fi

%preun
if [ $1 == 0 ]
then
        echo "This is the %{_name} package %{_rel} pre-uninstall script during uninstall phase"		
fi
if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} pre-uninstall script during upgrade phase"
fi

%postun
if [ $1 == 0 ]
then
        echo "This is the %{_name} package %{_rel} post-uninstall script during uninstall phase"	
		rm -rf /opt/ap/apos/conf/tinycore/
fi

if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-uninstall script during upgrade phase"
fi


%files
%defattr(-,root,root)
/opt/ap/apos/conf/tinycore/%_SMART_IMAGE

%changelog
* Thu Mar 03 2016 - claudio.elefante (at) itslab.it
- Initial implementation
