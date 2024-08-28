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

%define apos_hacxc_bin_path %{_cxcdir}/../../../ha_agent_cxc/bin
%define apos_hacxc_conf_path %{_cxcdir}/../../../ha_agent_cxc/conf
%define apos_hafagent_bin_path %{_cxcdir}/bin

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

# copy node_state.sh
cp %apos_hacxc_bin_path/nodeState  $RPM_BUILD_ROOT%APOSBINdir/nodeState

# copy apos_ha_service_control
cp %apos_hacxc_bin_path/apos_ha_srvcntl  $RPM_BUILD_ROOT%APOSBINdir/apos_ha_srvcntl

#copy apg rde agent stuff here
cp %apos_hacxc_bin_path/apos_ha_rdeagent_clc $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagent_clc
cp %apos_hacxc_bin_path/apos_ha_scsi_operations $RPM_BUILD_ROOT%APOSBINdir/apos_ha_scsi_operations
cp %apos_hacxc_bin_path/apos_ha_operations_md $RPM_BUILD_ROOT%APOSBINdir/apos_ha_operations
cp %apos_hafagent_bin_path/apos_ha_rdeagentd $RPM_BUILD_ROOT%APOSBINdir/apos_ha_rdeagentd
#cp %apos_hacxc_bin_path/apos_ha_shutdownagent.sh $RPM_BUILD_ROOT%APOSBINdir/apos_ha_shutdownagent.sh
#cp %apos_hacxc_bin_path/apos_ha_nodeupgrade.sh $RPM_BUILD_ROOT%APOSBINdir/apos_ha_nodeupgrade.sh

cp %apos_hacxc_conf_path/apos_ha_rdeagent.conf  $RPM_BUILD_ROOT%APOSCONFdir/apos_ha_rdeagent.conf

%post
if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-install script during installation phase"
fi
if [ $1 == 2 ]
then
        echo "This is the %{_name} package %{_rel} post-install script during upgrade phase"
fi

#install the data disk status script
/opt/ap/apos/bin/apos_ha_operations --update-diskstatus

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
	echo "cleaning up ha layer"

	rm -f %APOSCONFdir/apos_ha_rdeagent.conf
	rm -f %APOSBINdir/apos_ha_rdeagent_clc
	rm -f %APOSBINdir/apos_ha_rdeagentd
	rm -f %APOSBINdir/apos_ha_scsi_operations
	rm -f %APOSBINdir/apos_ha_operations
	rm -f %APOSBINdir/nodeState
	rm -f %APOSBINdir/apos_ha_srvcntl
	#rm -f %APOSBINdir/apos_ha_shutdownagent.sh
	#rm -f %APOSBINdir/apos_ha_nodeupgrade.sh
fi

if [ $1 == 1 ]
then
        echo "This is the %{_name} package %{_rel} post-uninstall script during upgrade phase"
fi

%files
%defattr(-,root,root)
%attr(0755,root,root) %APOSCONFdir/apos_ha_rdeagent.conf
%attr(0755,root,root) %APOSBINdir/apos_ha_rdeagent_clc
%attr(0755,root,root) %APOSBINdir/apos_ha_rdeagentd
%attr(0755,root,root) %APOSBINdir/apos_ha_scsi_operations
%attr(0755,root,root) %APOSBINdir/apos_ha_operations
%attr(0755,root,root) %APOSBINdir/nodeState
#%attr(0755,root,root) %APOSBINdir/apos_ha_shutdownagent.sh
#%attr(0755,root,root) %APOSBINdir/apos_ha_nodeupgrade.sh
%attr(0755,root,root) %APOSBINdir/apos_ha_srvcntl

%changelog
* Tue Aug 02 2011 - s.malangsha (at) tcs.com
- Initial implementation

