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

%define apos_devmoncxc_bin_path %{_cxcdir}/bin
%define apos_devmoncxc_conf_path %{_cxcdir}/conf
%define _storage_api /usr/share/pso/storage-paths/config

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build

%description
Installation package for HA devmon.

%pretrans
	echo "This is the %{_name} package %{_rel} pre-trans phase"
	
%pre
if [ $1 == 1 ]
then
	echo "This is the %{_name} package %{_rel} pre-install script during installation phase"
fi
if [ $1 == 2 ]
then
	echo "This is the %{_name} package %{_rel} pre-install script during upgrade phase"
	rm -f %APOSBINdir/apos_ha_devmond
	rm -f %APOSBINdir/apos_ha_devmon_clc
	rm -f %APOSCONFdir/apos_ha_devmond.conf
fi

%install
echo "This is the %{_name} package %{_rel} install script"
mkdir -p $RPM_BUILD_ROOT%APOSBINdir
mkdir -p $RPM_BUILD_ROOT/usr/lib64
mkdir -p $RPM_BUILD_ROOT%APOSCONFdir
mkdir -p $RPM_BUILD_ROOT%APOSLIBdir

#datadisk monitor process 
cp %apos_devmoncxc_bin_path/apos_ha_devmond_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_md
cp %apos_devmoncxc_bin_path/apos_ha_devmond_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_drbd
cp %apos_devmoncxc_bin_path/apos_ha_devmon_clc $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmon_clc
cp %apos_devmoncxc_conf_path/apos_ha_devmond.conf $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_devmond.conf

%post
if [ $1 == 1 ]
then
	echo "This is the %{_name} package %{_rel} post-install script during installation phase"
	datadisk_replication_type='NULL'
	storage_path=$(cat %{_storage_api})
	if [ -f "$storage_path"/apos/datadisk_replication_type ]; then
		datadisk_replication_type=$( cat "$storage_path"/apos/datadisk_replication_type)
	fi
	
	if [ "$datadisk_replication_type" == "NULL" ]; then
		hwtype=$(/opt/ap/apos/conf/apos_hwtype.sh)
		if [[ "$hwtype" == "GEP4" || "$hwtype" == "GEP5" || "$hwtype" == "GEP7" || "$hwtype" == "VM" ]]; then
			datadisk_replication_type='DRBD'
		elif [[ "$hwtype" == "GEP1" || "$hwtype" == "GEP2" ]]; then
			datadisk_replication_type='MD'
		fi
	fi
	
	if [ "$datadisk_replication_type" == 'DRBD' ]; then
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond 2>/dev/null
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_md
	fi

	if [ "$datadisk_replication_type" == 'MD' ]; then
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond 2>/dev/null
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_drbd
		rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_devmond.conf
	fi

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
	rm -f %APOSCONFdir/apos_ha_devmond.conf
	rm -f %APOSBINdir/apos_ha_devmon_clc
	rm -f %APOSBINdir/apos_ha_devmond
fi

if [ $1 == 1 ]
then
	echo "This is the %{_name} package %{_rel} post-uninstall script during upgrade phase"
fi

%posttrans
	echo "This is the %{_name} package %{_rel} post-trans phase"
	datadisk_replication_type='NULL'
	storage_path=$(cat %{_storage_api})
	if [ -f "$storage_path"/apos/datadisk_replication_type ]; then
		datadisk_replication_type=$( cat "$storage_path"/apos/datadisk_replication_type)
	fi

	if [ "$datadisk_replication_type" == "NULL" ]; then
		hwtype=$(/opt/ap/apos/conf/apos_hwtype.sh)
		if [[ "$hwtype" == "GEP4" || "$hwtype" == "GEP5" || "$hwtype" == "GEP7" || "$hwtype" == "VM" ]]; then
			datadisk_replication_type='DRBD'
		elif [[ "$hwtype" == "GEP1" || "$hwtype" == "GEP2" ]]; then
			datadisk_replication_type='MD'
		fi
	fi
	
	if [ "$datadisk_replication_type" == 'DRBD' ]; then
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond 2>/dev/null
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_md
	fi

	if [ "$datadisk_replication_type" == 'MD' ]; then
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond 2>/dev/null
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_devmond_drbd
		rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_devmond.conf
	fi

%files
%defattr(-,root,root)
%attr(0755,root,root) %APOSCONFdir/apos_ha_devmond.conf
%attr(0755,root,root) %APOSBINdir/apos_ha_devmon_clc
%attr(0755,root,root) %APOSBINdir/apos_ha_devmond_md
%attr(0755,root,root) %APOSBINdir/apos_ha_devmond_drbd

%changelog
* Thu Jun 04 2013 - tanu.a (at) tcs.com
- Initial implementation

