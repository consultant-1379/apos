#
# spec file for configuration of package apache
#
# Copyright  (c)  2013  Ericsson AB
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

%define apos_hacxc_bin_path %{_cxcdir}/bin
%define apos_hacxc_conf_path %{_cxcdir}/conf
%define _storage_api /usr/share/pso/storage-paths/config

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build

%description
Installation package for HA Agent

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
	rm -f %APOSBINdir/nodeState
    rm -f %APOSBINdir/apos_ha_srvcntl
    rm -f %APOSBINdir/apos_ha_scsi_operations
    rm -f %APOSBINdir/apos_ha_rdeagentd
    rm -f %APOSCONFdir/apos_ha_rdeagent.conf
    rm -f %APOSBINdir/apos_ha_operations
    rm -f %APOSCONFdir/apos_ha_agentd.conf
    rm -f %APOSBINdir/apos_ha_rdeagent_clc
fi

%install
echo "This is the %{_name} package %{_rel} install script"
mkdir -p $RPM_BUILD_ROOT%APOSBINdir
mkdir -p $RPM_BUILD_ROOT/usr/lib64
mkdir -p $RPM_BUILD_ROOT%APOSCONFdir
mkdir -p $RPM_BUILD_ROOT%APOSLIBdir

#copy the data for HA Agent
cp %apos_hacxc_bin_path/nodeState $RPM_BUILD_ROOT%APOSBINdir/nodeState
cp %apos_hacxc_bin_path/apos_ha_srvcntl $RPM_BUILD_ROOT%APOSBINdir/apos_ha_srvcntl
cp %apos_hacxc_bin_path/apos_ha_scsi_operations $RPM_BUILD_ROOT%APOSBINdir/apos_ha_scsi_operations
cp %apos_hacxc_bin_path/apos_ha_operations_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_md
cp %apos_hacxc_bin_path/apos_ha_rdeagentd_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_md
cp %apos_hacxc_conf_path/apos_ha_rdeagent.conf  $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_rdeagent.conf
cp %apos_hacxc_bin_path/apos_ha_rdeagentd_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_drbd
cp %apos_hacxc_bin_path/apos_ha_operations_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_drbd
cp %apos_hacxc_conf_path/apos_ha_agentd.conf  $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_agentd.conf
cp %apos_hacxc_bin_path/apos_ha_rdeagent_clc $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagent_clc

%post

if [ $1 == 1 ]
then
	echo "This is the %{_name} package %{_rel} post-install script during installation phase"
	datadisk_replication_type='NULL'
	storage_path=$(cat %{_storage_api})
	if [ -f $storage_path/apos/datadisk_replication_type ]; then
		datadisk_replication_type=$( cat $storage_path/apos/datadisk_replication_type)
	fi

	if [ "$datadisk_replication_type" == 'NULL' ]; then
		hwtype=$(/opt/ap/apos/conf/apos_hwtype.sh)
		if [[ "$hwtype" == 'GEP4' || "$hwtype" == 'GEP5' || "$hwtype" == 'GEP7' || "$hwtype" == 'VM' ]]; then
			datadisk_replication_type='DRBD'
		elif [[ "$hwtype" == 'GEP1' || "$hwtype" == 'GEP2' ]]; then
			datadisk_replication_type='MD'
		fi
	fi

	if [ "$datadisk_replication_type" == 'DRBD' ]; then
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations 2>/dev/dull
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd 2>/dev/dull
		rm -f $RPM_BUILD_ROOT%APOSBINdir/nodeState
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_srvcntl
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_scsi_operations
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_md
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_md
		rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_rdeagent.conf
	fi

	if [ "$datadisk_replication_type" == 'MD' ]; then
		mkdir -p '/storage/system/config/ha/nodes/1/'
		mkdir -p '/storage/system/config/ha/nodes/2/'
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations 2>/dev/dull
		mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd 2>/dev/dull
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_drbd
		rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_drbd
		rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_agentd.conf
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
	rm -f %APOSBINdir/nodeState
    rm -f %APOSBINdir/apos_ha_srvcntl
    rm -f %APOSBINdir/apos_ha_scsi_operations
    rm -f %APOSBINdir/apos_ha_rdeagentd
    rm -f %APOSCONFdir/apos_ha_rdeagent.conf
    rm -f %APOSBINdir/apos_ha_operations
    rm -f %APOSCONFdir/apos_ha_agentd.conf
    rm -f %APOSBINdir/apos_ha_rdeagent_clc
fi

if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-uninstall script during upgrade phase"
fi

%posttrans
	echo "This is the %{_name} package %{_rel} post-trans phase"
	datadisk_replication_type='NULL'
    storage_path=$(cat %{_storage_api})
    if [ -f $storage_path/apos/datadisk_replication_type ]; then
        datadisk_replication_type=$( cat $storage_path/apos/datadisk_replication_type)
    fi

    if [ "$datadisk_replication_type" == 'NULL' ]; then
        hwtype=$(/opt/ap/apos/conf/apos_hwtype.sh)
        if [[ "$hwtype" == 'GEP4' || "$hwtype" == 'GEP5' || "$hwtype" == 'GEP7' || "$hwtype" == 'VM' ]]; then
            datadisk_replication_type='DRBD'
        elif [[ "$hwtype" == 'GEP1' || "$hwtype" == 'GEP2' ]]; then
            datadisk_replication_type='MD'
        fi
    fi

    if [ "$datadisk_replication_type" == 'DRBD' ]; then
        mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations 2>/dev/dull
        mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_drbd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd 2>/dev/dull
        rm -f $RPM_BUILD_ROOT%APOSBINdir/nodeState
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_srvcntl
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_scsi_operations
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_md
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_md
        rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_rdeagent.conf
    fi

    if [ "$datadisk_replication_type" == 'MD' ]; then
        mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations 2>/dev/dull
        mv $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd 2>/dev/dull
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd_drbd
        rm -f $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations_drbd
        rm -f $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_agentd.conf
    fi

%files
%defattr(-,root,root)
%attr(0755,root,root) %APOSBINdir/nodeState
%attr(0755,root,root) %APOSBINdir/apos_ha_srvcntl
%attr(0755,root,root) %APOSBINdir/apos_ha_scsi_operations
%attr(0755,root,root) %APOSBINdir/apos_ha_operations_md
%attr(0755,root,root) %APOSBINdir/apos_ha_rdeagentd_md
%attr(0755,root,root) %APOSCONFdir/apos_ha_rdeagent.conf
%attr(0755,root,root) %APOSBINdir/apos_ha_rdeagentd_drbd
%attr(0755,root,root) %APOSBINdir/apos_ha_operations_drbd
%attr(0755,root,root) %APOSCONFdir/apos_ha_agentd.conf
%attr(0755,root,root) %APOSBINdir/apos_ha_rdeagent_clc

%changelog
* Thu Jul 04 2013 - tanu.a (at) tcs.com
- Initial implementation

