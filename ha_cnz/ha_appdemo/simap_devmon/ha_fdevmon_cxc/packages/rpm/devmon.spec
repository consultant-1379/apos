#
# spec file for configuration of package apache
#
# Copyright  (c)  2010  Ericsson LM
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

Name:      %{_name}
Summary:   Installation package for HA.
Version:   %{_prNr}
Release:   %{_rel}
License:   Ericsson Proprietary
Vendor:    Ericsson LM
Packager:  %packer
Group:     Application
BuildRoot: %_tmppath
Requires: APOS_OSCONFBIN

%define apos_fdevmoncxc_bin_path %{_cxcdir}/bin
%define apos_fdevmoncxc_conf_path %{_cxcdir}/conf

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build

%description
Installation package for HA.

%pre
if [ $1 == 1 ]
then
	echo "This is the %{_name} package %{_rel} pre-install script during installation phase"
fi
if [ $1 == 2 ]
then
	echo "This is the %{_name} package %{_rel} pre-install script during upgrade phase"
fi

%install
echo "This is the %{_name} package %{_rel} install script"
echo "copying the files required"

mkdir -p $RPM_BUILD_ROOT%APOSBINdir
mkdir -p $RPM_BUILD_ROOT/usr/lib64
mkdir -p $RPM_BUILD_ROOT%APOSCONFdir
mkdir -p $RPM_BUILD_ROOT%APOSLIBdir

#datadisk monitor process 
cp %apos_fdevmoncxc_bin_path/apos_ha_devmond $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond
cp %apos_fdevmoncxc_bin_path/apos_ha_devmon_clc $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmon_clc
cp %apos_fdevmoncxc_conf_path/ha_apos_ha_devmon_objects.xml $RPM_BUILD_ROOT%APOSCONFdir/ha_apos_ha_devmon_objects.xml

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
	echo "cleaning up devmon layer"

	rm -f %APOSCONFdir/ha_apos_ha_devmon_objects.xml
	rm -f %APOSBINdir/apos_ha_devmon_clc
	rm -f %APOSBINdir/apos_ha_devmond
fi

if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-uninstall script during upgrade phase"
fi

%files
%defattr(-,root,root)
%attr(0755,root,root) %APOSCONFdir/ha_apos_ha_devmon_objects.xml
%attr(0755,root,root) %APOSBINdir/apos_ha_devmon_clc
%attr(0755,root,root) %APOSBINdir/apos_ha_devmond

%changelog
* Tue Aug 02 2011 - s.malangsha (at) tcs.com
- Initial implementation

