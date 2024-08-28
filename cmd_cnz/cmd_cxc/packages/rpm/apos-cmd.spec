##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Spec file for APOS commands
#
##
#
# Please send bugfixes or comments to paolo.palmieri@ericsson.com
#
##

# The following 2 lines disable the automatic resolution of "Requires" and "Provides" tags
%define __find_requires %{nil}
%define __find_provides %{nil}

%define packer %(finger -lp `echo "$USER"` | head -n 1 | cut -d: -f 3)
#%define _topdir /var/tmp/%(echo "$USER")/rpms/apos-cmd
%define _topdir /var/tmp/%(echo "$USER")/rpms
%define _tmppath %_topdir/tmp
%define _binfolder /usr/bin
%define _target $RPM_BUILD_ROOT/opt/ap/apos/bin
%define _target_bin $RPM_BUILD_ROOT/opt/ap/apos/bin
%define _target_lib64 $RPM_BUILD_ROOT/lib64
%define _mipath /cluster/mi/installation
%define _apos_vob_rootdir %{_cxcdir}/../..

%define name 		APOS_OSCMDBIN
%define version         %{_prNr}
%define release         %{_rel}

Name: 			            %{name}
Summary: 		            APOS commands installation package.
Version: 		            %{version}
Release: 		            %{release}
Prefix: 		            /usr
License:                Ericsson Proprietary
Vendor:                 Ericsson LM
Packager:               %packer
Group:                  APOS/Configuration
BuildRoot:		          %_tmppath


%description
Commands installation package for APOS.


%prep
if [ -d $RPM_BUILD_ROOT ]; then 
  chmod 777 -R $RPM_BUILD_ROOT
fi


%build


%install
echo "This is the %{name}-%{version} package %{release} install script"
mkdir -p %{_target}/clusterconf/
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/bios/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/bios/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/cdadm/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/cdadm/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/date/date_cxc/bin/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/date/date_cxc/bin/apos_date %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/drbdr/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/drbdr/drbd_split_brain_recover %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/drbdr/ | wc -l` -gt 0 ]; then
        install -m 555 %{_apos_vob_rootdir}/cmd_cnz/drbdr/raidmgr_drbd %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ddr/ | wc -l` -gt 0 ]; then
        install -m 555 %{_apos_vob_rootdir}/cmd_cnz/ddr/raidmgr_md %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/rpskeymgmt/ | wc -l` -gt 0 ]; then
        install -m 555 %{_apos_vob_rootdir}/cmd_cnz/rpskeymgmt/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ldap/ | wc -l` -gt 0 ]; then
        install -m 554 %{_apos_vob_rootdir}/cmd_cnz/ldap/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/fqdn/ | wc -l` -gt 0 ]; then
        install -m 554 %{_apos_vob_rootdir}/cmd_cnz/fqdn/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ddr/ | wc -l` -gt 0 ]; then
        install -m 555 %{_apos_vob_rootdir}/cmd_cnz/simucliss/bin/simucliss %{_target}/
fi
if [ $(ls -1A %{_apos_vob_rootdir}/cmd_cnz/cla/bin/ | wc -l) -gt 1 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/cla/bin/check_ldap_availability %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ha/ | wc -l` -gt 0 ]; then
	install -m 554 %{_apos_vob_rootdir}/cmd_cnz/ha/apos_operations %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/net/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/net/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/os/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/os/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ps/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/ps/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/raid/ | wc -l` -gt 0 ]; then
	install -m 554 %{_apos_vob_rootdir}/cmd_cnz/raid/raidmgmt %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/rif/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/rif/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/em/ | wc -l` -gt 0 ]; then
        install -m 555 %{_apos_vob_rootdir}/cmd_cnz/em/* %{_target}/
fi	
if [ -d %{_apos_vob_rootdir}/cmd_cnz/sm/ ]; then
	mkdir -m 755 -p %{_target}/sm/
	if [[ -x %{_apos_vob_rootdir}/cmd_cnz/sm/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/sm/files.list ]]; then
		%{_apos_vob_rootdir}/cmd_cnz/sm/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/sm/sm %{_target}/sm	
	fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/gi/ ]; then
        mkdir -m 755 -p %{_target}/gi/
        if [[ -x %{_apos_vob_rootdir}/cmd_cnz/gi/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/gi/files.list ]]; then
                %{_apos_vob_rootdir}/cmd_cnz/gi/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/gi/gi %{_target}/gi
        fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/usermgmt/ ]; then
	mkdir -m 755 -p %{_target}/usermgmt/
	if [[ -x %{_apos_vob_rootdir}/cmd_cnz/usermgmt/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/usermgmt/files.list ]]; then
		%{_apos_vob_rootdir}/cmd_cnz/usermgmt/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/usermgmt/usermgmt %{_target}/usermgmt	
	fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/servicemgmt/ ]; then
	mkdir -m 755 -p %{_target}/servicemgmt/
	if [[ -x %{_apos_vob_rootdir}/cmd_cnz/servicemgmt/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/servicemgmt/files.list ]]; then
		%{_apos_vob_rootdir}/cmd_cnz/servicemgmt/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/servicemgmt/servicemgmt %{_target}/servicemgmt	
	fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/ic/ ]; then
	mkdir -m 755 -p %{_target}/ic/
	if [[ -x %{_apos_vob_rootdir}/cmd_cnz/ic/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/ic/files.list ]]; then
		%{_apos_vob_rootdir}/cmd_cnz/ic/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/ic/ic %{_target}/ic	
	fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/bspm/ ]; then
	mkdir -m 755 -p %{_target}/bspm/
	if [[ -x %{_apos_vob_rootdir}/cmd_cnz/bspm/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/bspm/files.list ]]; then
		%{_apos_vob_rootdir}/cmd_cnz/bspm/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/bspm/bspm %{_target}/bspm	
	fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/parmtool/ ]; then
  mkdir -m 755 -p %{_target}/parmtool/
  if [[ -x %{_apos_vob_rootdir}/cmd_cnz/parmtool/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/parmtool/files.list ]]; then
    %{_apos_vob_rootdir}/cmd_cnz/parmtool/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/parmtool/parmtool %{_target}/parmtool
  fi
fi
if [ -d %{_apos_vob_rootdir}/cmd_cnz/import_factoryparm/ ]; then
  mkdir -m 755 -p %{_target}/import_factoryparm/
  if [[ -x %{_apos_vob_rootdir}/cmd_cnz/import_factoryparm/install_files.sh && -r %{_apos_vob_rootdir}/cmd_cnz/import_factoryparm/files.list ]]; then
    %{_apos_vob_rootdir}/cmd_cnz/import_factoryparm/install_files.sh %{_apos_vob_rootdir}/cmd_cnz/import_factoryparm/import_factoryparm %{_target}/import_factoryparm
  fi
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/snr/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/snr/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/ts_cp/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/ts_cp/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/tz/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/tz/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/vlan/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/vlan/* %{_target}/
fi
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/clusterconf/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/clusterconf/* %{_target}/clusterconf/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/zip/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/zip/* %{_target}/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/http/ | wc -l` -gt 0 ]; then
	install -m 555 %{_apos_vob_rootdir}/cmd_cnz/http/* %{_target}/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/swmgr/ | wc -l` -gt 0 ]; then
  install -m 555 %{_apos_vob_rootdir}/cmd_cnz/swmgr/swmgr %{_target}/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/apg-adm/ | wc -l` -gt 0 ]; then
  install -m 555 %{_apos_vob_rootdir}/cmd_cnz/apg-adm/* %{_target}/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/spadm/ | wc -l` -gt 0 ]; then
  install -m 555 %{_apos_vob_rootdir}/cmd_cnz/spadm/* %{_target}/
fi

if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/wdmgr/ | wc -l` -gt 0 ]; then
  install -m 555 %{_apos_vob_rootdir}/cmd_cnz/wdmgr/* %{_target}/
fi


# handling of the nss files
mkdir -p %{_target_lib64}
install -m 555 %{_apos_vob_rootdir}/cmd_cnz/nss/nss_cxc/bin/nss_ufbs %{_target_bin}/	
install -m 555 %{_apos_vob_rootdir}/cmd_cnz/nss/nss_cxc/bin/libnss_fbs.so.2.0.2 %{_target_lib64}/	

# Copy of the files in the cliss folder
if [ `ls -1A %{_apos_vob_rootdir}/cmd_cnz/cliss | wc -l` -gt 0 ]; then
	mkdir -p %{_target_bin}/cliss
	install -m 555 $(find %{_apos_vob_rootdir}/cmd_cnz/cliss -maxdepth 1 -type f) %{_target_bin}/cliss	
fi


%files
%defattr(-,root,root)
/opt/ap/apos/bin/apos_date
/opt/ap/apos/bin/bioschg
/opt/ap/apos/bin/cdadm
/opt/ap/apos/bin/cdadm.sh
/opt/ap/apos/bin/check_ldap_availability
/opt/ap/apos/bin/ldapconfig.sh
/opt/ap/apos/bin/fqdnconfdef.sh
/opt/ap/apos/bin/rif_common
/opt/ap/apos/bin/rifls
/opt/ap/apos/bin/rifdef
/opt/ap/apos/bin/rifrm
/opt/ap/apos/bin/drbd_split_brain_recover
/opt/ap/apos/bin/apos_operations
/opt/ap/apos/bin/netdef
/opt/ap/apos/bin/netls
/opt/ap/apos/bin/nss_ufbs
/opt/ap/apos/bin/ping
/opt/ap/apos/bin/ping6
/opt/ap/apos/bin/simucliss
/opt/ap/apos/bin/traceroute
/opt/ap/apos/bin/traceroute6
/opt/ap/apos/bin/ver
/opt/ap/apos/bin/psdef
/opt/ap/apos/bin/psls
/opt/ap/apos/bin/psrm
# The following line is for the whole parmtool directory structure
/opt/ap/apos/bin/import_factoryparm
# The following line is for the whole parmtool directory structure
/opt/ap/apos/bin/parmtool
# The following line is for the whole shelfmanager directory structure
/opt/ap/apos/bin/sm
# The following line is for the whole ipmiconf directory structure
/opt/ap/apos/bin/ic
# The following line is for the whole usermgmt directory structure
/opt/ap/apos/bin/usermgmt
# The following line is for the whole servicemgmt directory structure
/opt/ap/apos/bin/servicemgmt
# The following line is for the whole bspmanager directory structure
/opt/ap/apos/bin/bspm
# The following line is for the whole gi directory structure
/opt/ap/apos/bin/gi
/opt/ap/apos/bin/clu_sync_speed
/opt/ap/apos/bin/drbd_sync_state
/opt/ap/apos/bin/get_bios_info
/opt/ap/apos/bin/pxetest
/opt/ap/apos/bin/snrinit
/opt/ap/apos/bin/raidmgmt
/opt/ap/apos/bin/swmgr
/opt/ap/apos/bin/ts_cp
/opt/ap/apos/bin/tzch
/opt/ap/apos/bin/tzls
/opt/ap/apos/bin/vlanch
/opt/ap/apos/bin/vlandef
/opt/ap/apos/bin/vlanls
/opt/ap/apos/bin/vlanrm
/opt/ap/apos/bin/chkconfigls
/opt/ap/apos/bin/dmidecode
/opt/ap/apos/bin/drbd-overview
/opt/ap/apos/bin/eri-ipmitool
/opt/ap/apos/bin/pam_tally2
/opt/ap/apos/bin/lde-brf
/opt/ap/apos/bin/lspci
/opt/ap/apos/bin/lvdisplay
/opt/ap/apos/bin/partls
/opt/ap/apos/bin/pvdisplay
/opt/ap/apos/bin/repquota
/opt/ap/apos/bin/service-status-all
/opt/ap/apos/bin/sg_mapx
/opt/ap/apos/bin/smartctl
/opt/ap/apos/bin/tcpdump
/opt/ap/apos/bin/ftp_port_20
/opt/ap/apos/bin/ssu_mem_recovery.sh
/opt/ap/apos/bin/tipc-link-stat
/opt/ap/apos/bin/vgdisplay
/opt/ap/apos/bin/raidmgr_md
/opt/ap/apos/bin/raidmgr_drbd
/opt/ap/apos/bin/unzip
/opt/ap/apos/bin/httpmgr
/opt/ap/apos/bin/spadm
/opt/ap/apos/bin/apos_httpmgr_operations.sh
/opt/ap/apos/bin/httpmgr.sh
/opt/ap/apos/bin/entry_matches.sh
/opt/ap/apos/bin/apg-adm.py
/opt/ap/apos/bin/apg-adm.sh
/opt/ap/apos/bin/rpskeymgmt
/opt/ap/apos/bin/rpskeymgmt.sh
/opt/ap/apos/bin/lock_table.yaml
/opt/ap/apos/bin/clusterconf/clu_alarm
/opt/ap/apos/bin/clusterconf/clu_bonding
/opt/ap/apos/bin/clusterconf/clu_boot
/opt/ap/apos/bin/clusterconf/clu_command
/opt/ap/apos/bin/clusterconf/clu_coredump
/opt/ap/apos/bin/clusterconf/clu_default
/opt/ap/apos/bin/clusterconf/clu_default-output
/opt/ap/apos/bin/clusterconf/clu_disable-serial
/opt/ap/apos/bin/clusterconf/clu_dns
/opt/ap/apos/bin/clusterconf/clu_host
/opt/ap/apos/bin/clusterconf/clu_interface
/opt/ap/apos/bin/clusterconf/clu_ip
/opt/ap/apos/bin/clusterconf/clu_ip6tables
/opt/ap/apos/bin/clusterconf/clu_ipmi
/opt/ap/apos/bin/clusterconf/clu_iptables
/opt/ap/apos/bin/clusterconf/clu_keymap
/opt/ap/apos/bin/clusterconf/clu_loader
/opt/ap/apos/bin/clusterconf/clu_mgmt
/opt/ap/apos/bin/clusterconf/clu_mip
/opt/ap/apos/bin/clusterconf/clu_netconsole
/opt/ap/apos/bin/clusterconf/clu_network
/opt/ap/apos/bin/clusterconf/clu_nfs
/opt/ap/apos/bin/clusterconf/clu_node
/opt/ap/apos/bin/clusterconf/clu_nodegroup
/opt/ap/apos/bin/clusterconf/clu_ntp
/opt/ap/apos/bin/clusterconf/clu_parse
/opt/ap/apos/bin/clusterconf/clu_quick-reboot
/opt/ap/apos/bin/clusterconf/clu_route
/opt/ap/apos/bin/clusterconf/clu_sc
/opt/ap/apos/bin/clusterconf/clu_shutdown-timeout
/opt/ap/apos/bin/clusterconf/clu_ssh
/opt/ap/apos/bin/clusterconf/clu_ssh.rootlogin
/opt/ap/apos/bin/clusterconf/clu_syslog
/opt/ap/apos/bin/clusterconf/clu_timezone
/opt/ap/apos/bin/clusterconf/clu_tipc
/opt/ap/apos/bin/clusterconf/clu_watchdog
/opt/ap/apos/bin/clusterconf/clusterconf
/lib64/libnss_fbs.so.2.0.2
# wrappers for commands to be run via com-cli with superuser privileges
/opt/ap/apos/bin/cliss/bioschg.sh
/opt/ap/apos/bin/cliss/date.sh
/opt/ap/apos/bin/cliss/ldapdef.sh
/opt/ap/apos/bin/cliss/fqdndef.sh
/opt/ap/apos/bin/cliss/netdef.sh
/opt/ap/apos/bin/cliss/netls.sh
/opt/ap/apos/bin/cliss/osumgr.sh
/opt/ap/apos/bin/cliss/psdef.sh
/opt/ap/apos/bin/cliss/psls.sh
/opt/ap/apos/bin/cliss/psrm.sh
/opt/ap/apos/bin/cliss/raidmgr_md.sh
/opt/ap/apos/bin/cliss/raidmgr_drbd.sh
/opt/ap/apos/bin/cliss/rifls.sh
/opt/ap/apos/bin/cliss/rifdef.sh
/opt/ap/apos/bin/cliss/rifrm.sh
/opt/ap/apos/bin/cliss/sec-encryption-key-update.sh
/opt/ap/apos/bin/cliss/snrinit.sh
/opt/ap/apos/bin/cliss/swmgr.sh
/opt/ap/apos/bin/cliss/traceroute.sh
/opt/ap/apos/bin/cliss/traceroute6.sh
/opt/ap/apos/bin/cliss/tzch.sh
/opt/ap/apos/bin/cliss/tzls.sh
/opt/ap/apos/bin/cliss/ver.sh
/opt/ap/apos/bin/cliss/vlanch.sh
/opt/ap/apos/bin/cliss/vlandef.sh
/opt/ap/apos/bin/cliss/vlanls.sh
/opt/ap/apos/bin/cliss/vlanrm.sh
/opt/ap/apos/bin/cliss/unzip.sh
/opt/ap/apos/bin/cliss/spadm.sh
/opt/ap/apos/bin/wdmgr
/opt/ap/apos/bin/wdmgr.sh

%doc 

%clean
umask 022
if [ -d $RPM_BUILD_ROOT ]; then 
 chmod 777 -R $RPM_BUILD_ROOT
 rm -rf $RPM_BUILD_ROOT
fi

%pre
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during installation phase"
fi
if [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during upgrade phase"
	
	# Removal of the link referring to the old bios_upgrade script
	if [ -L "%{_binfolder}/bios_upgrade" ]; then
		unlink "%{_binfolder}/bios_upgrade"
	fi
fi


%post

LINK_LIST="/opt/ap/apos/bin/cliss/date.sh:%{_binfolder}/apos_date
	/opt/ap/apos/bin/cliss/netdef.sh:%{_binfolder}/netdef
	/opt/ap/apos/bin/cliss/netls.sh:%{_binfolder}/netls
	/opt/ap/apos/bin/cliss/osumgr.sh:%{_binfolder}/osumgr
	/opt/ap/apos/bin/cliss/psdef.sh:%{_binfolder}/psdef
	/opt/ap/apos/bin/cliss/psls.sh:%{_binfolder}/psls
	/opt/ap/apos/bin/cliss/psrm.sh:%{_binfolder}/psrm
	/opt/ap/apos/bin/cliss/rifls.sh:%{_binfolder}/rifls
	/opt/ap/apos/bin/cliss/rifdef.sh:%{_binfolder}/rifdef
	/opt/ap/apos/bin/cliss/rifrm.sh:%{_binfolder}/rifrm
	/opt/ap/apos/bin/cliss/sec-encryption-key-update.sh:%{_binfolder}/sec-encryption-key-update
	/opt/ap/apos/bin/cliss/snrinit.sh:%{_binfolder}/snrinit
	/opt/ap/apos/bin/cliss/swmgr.sh:%{_binfolder}/swmgr
	/opt/ap/apos/bin/cliss/tzch.sh:%{_binfolder}/tzch
	/opt/ap/apos/bin/cliss/tzls.sh:%{_binfolder}/tzls
	/opt/ap/apos/bin/cliss/ver.sh:%{_binfolder}/ver
	/opt/ap/apos/bin/cliss/vlanch.sh:%{_binfolder}/vlanch
	/opt/ap/apos/bin/cliss/vlandef.sh:%{_binfolder}/vlandef
	/opt/ap/apos/bin/cliss/vlanls.sh:%{_binfolder}/vlanls
	/opt/ap/apos/bin/cliss/vlanrm.sh:%{_binfolder}/vlanrm
	/opt/ap/apos/bin/cliss/spadm.sh:%{_binfolder}/spadm
	/opt/ap/apos/bin/drbd_split_brain_recover:%{_binfolder}/drbd_split_brain_recover
	/opt/ap/apos/bin/ts_cp:%{_binfolder}/ts_cp
	/opt/ap/apos/bin/cliss/bioschg.sh:%{_binfolder}/bioschg
	/opt/ap/apos/bin/raidmgmt:%{_binfolder}/raidmgmt
	/opt/ap/apos/bin/cdadm.sh:%{_binfolder}/cdadm
        /opt/ap/apos/bin/rpskeymgmt.sh:%{_binfolder}/rpskeymgmt
	/opt/ap/apos/bin/chkconfigls:%{_binfolder}/chkconfigls
	/opt/ap/apos/bin/dmidecode:%{_binfolder}/dmidecode
	/opt/ap/apos/bin/drbd-overview:%{_binfolder}/drbd-overview
	/opt/ap/apos/bin/eri-ipmitool:%{_binfolder}/eri-ipmitool
	/opt/ap/apos/bin/pam_tally2:%{_binfolder}/pam_tally2
	/opt/ap/apos/bin/lde-brf:%{_binfolder}/lde-brf
	/opt/ap/apos/bin/lspci:%{_binfolder}/lspci
	/opt/ap/apos/bin/lvdisplay:%{_binfolder}/lvdisplay
	/opt/ap/apos/bin/partls:%{_binfolder}/partls
	/opt/ap/apos/bin/pvdisplay:%{_binfolder}/pvdisplay
	/opt/ap/apos/bin/repquota:%{_binfolder}/repquota
	/opt/ap/apos/bin/service-status-all:%{_binfolder}/service-status-all
	/opt/ap/apos/bin/sg_mapx:%{_binfolder}/sg_mapx
	/opt/ap/apos/bin/smartctl:%{_binfolder}/smartctl
	/opt/ap/apos/bin/tcpdump:%{_binfolder}/tcpdump
	/opt/ap/apos/bin/ftp_port_20:%{_binfolder}/ftp_port_20
        /opt/ap/apos/bin/ssu_mem_recovery.sh:%{_binfolder}/ssu_mem_recovery.sh
	/opt/ap/apos/bin/tipc-link-stat:%{_binfolder}/tipc-link-stat
	/opt/ap/apos/bin/vgdisplay:%{_binfolder}/vgdisplay
	/opt/ap/apos/bin/httpmgr.sh:%{_binfolder}/httpmgr
  /opt/ap/apos/bin/apg-adm.sh:%{_binfolder}/apg-adm
  /opt/coremw/bin/cmw-utility:%{_binfolder}/cmw-utility
  /opt/ap/apos/bin/wdmgr.sh:%{_binfolder}/wdmgr
	%{_target_lib64}/libnss_fbs.so.2.0.2:%{_target_lib64}/libnss_fbs.so.2"
	
	
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} postinstall script during installation phase"
	echo -e "\nINFO: Installing APOS commands..."
	
	for LINK in $LINK_LIST; do
		SOURCE=$(echo $LINK|awk -F':' '{print $1}')
		DEST=$(echo $LINK|awk -F':' '{print $2}')
		if [ -L $DEST ]; then
			unlink $DEST
		fi
		ln -s $SOURCE $DEST
	done
	
	echo -e "\nINFO: APOS commands installation is done successfully"
fi

if [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} postinstall script during upgrade phase"

	for LINK in $LINK_LIST; do
		SOURCE=$(echo $LINK|awk -F':' '{print $1}')
		DEST=$(echo $LINK|awk -F':' '{print $2}')
		if [ -L $DEST ]; then
			unlink $DEST
		fi
		ln -s $SOURCE $DEST
	done

	echo -e "\nINFO: APOS commands upgrade is done successfully"
fi

if [ -f /cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf ];  then
  is_vm=$(cat /cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf | grep -i installation_hw | awk -F "=" '{print $2}')
  if [ "$is_vm" == "VM" ];  then
    echo "VM. Importing Factory param."
    if [ -d /opt/ap/apos/bin/import_factoryparm ]; then
      echo "factoryparm path exists" 1>/tmp/factory_log_1 2>/tmp/factory_log_2
      pushd /opt/ap/apos/bin/import_factoryparm
      ./apos_import_factoryparam 1>>/tmp/factory_log_1 2>>/tmp/factory_log_2
      rm -rf parmtool
      popd
    else
      echo "import_factoryparm folder does not exist"
    fi
  else
    echo "Native. No actions needed"
  fi
else
  echo "factoryparam.conf does not exist"
fi
 
sleep 2
storage_api='/usr/share/pso/storage-paths/config'
storage_path=$(cat $storage_api)
if [ -f $storage_path/apos/datadisk_replication_type ]; then
	datadisk_replication_type=$( cat $storage_path/apos/datadisk_replication_type)
fi

if [[ -z "$datadisk_replication_type" && -f %{_mipath}/datadisk_replication_type ]]; then
	datadisk_replication_type=$( cat %{_mipath}/datadisk_replication_type)
fi

if [[ -z "$datadisk_replication_type" && -f %{_mipath}/installation_hw ]]; then
	hw_type=$( cat %{_mipath}/installation_hw)
	datadisk_replication_type="DRBD"
	if [[ "$hw_type" == "GEP1" || "$hw_type" == "GEP2"  ]]; then
		datadisk_replication_type="MD"
	fi
fi

if [ "$datadisk_replication_type" == "DRBD" ]; then
    mv %{_target}/raidmgr_drbd %{_target}/raidmgr
    mv %{_target}/cliss/raidmgr_drbd.sh %{_target}/cliss/raidmgr.sh
    rm %{_target}/raidmgr_md
    rm %{_target}/cliss/raidmgr_md.sh
    rm %{_target}/raidmgmt
    rm %{_binfolder}/raidmgmt

    ln -sf %{_target}/cliss/raidmgr.sh %{_binfolder}/raidmgr
fi

if [ "$datadisk_replication_type" == "MD" ]; then
    mv %{_target}/raidmgr_md %{_target}/raidmgr
    mv %{_target}/cliss/raidmgr_md.sh %{_target}/cliss/raidmgr.sh
    rm %{_target}/raidmgr_drbd
    rm %{_target}/cliss/raidmgr_drbd.sh

    ln -sf %{_target}/cliss/raidmgr.sh %{_binfolder}/raidmgr
fi

%preun
if [ $1 == 0 ]; then
	echo "This is the %{name}-%{version} package %{release} preuninstall script during uninstall phase"
	rm -f %{_binfolder}/apos_date
	rm -f %{_binfolder}/bioschg
	rm -f %{_binfolder}/chkconfigls
	rm -f %{_binfolder}/dmidecode
	rm -f %{_binfolder}/drbd-overview
	rm -f %{_binfolder}/eri-ipmitool
	rm -f %{_binfolder}/pam_tally2
	rm -f %{_binfolder}/lde-brf
	rm -f %{_binfolder}/lspci
	rm -f %{_binfolder}/lvdisplay
	rm -f %{_binfolder}/partls
	rm -f %{_binfolder}/pvdisplay
	rm -f %{_binfolder}/repquota
	rm -f %{_binfolder}/service-status-all
	rm -f %{_binfolder}/sg_mapx
	rm -f %{_binfolder}/smartctl
	rm -f %{_binfolder}/tcpdump
	rm -f %{_binfolder}/ftp_port_20
        rm -f %{_binfodler}/ssu_mem_recovery.sh
	rm -f %{_binfolder}/tipc-link-stat
	rm -f %{_binfolder}/vgdisplay
	rm -f %{_binfolder}/drbd_split_brain_recover
	rm -f %{_binfolder}/netdef
	rm -f %{_binfolder}/rifdef
	rm -f %{_binfolder}/rifls
	rm -f %{_binfolder}/rifrm
	rm -f %{_binfolder}/netls
	rm -f %{_binfolder}/osumgr
	rm -f %{_binfolder}/ver
	rm -f %{_binfolder}/psdef
	rm -f %{_binfolder}/psls
	rm -f %{_binfolder}/psrm
	rm -f %{_binfolder}/raidmgr
	rm -f %{_binfolder}/sec-encryption-key-update.sh
	rm -f %{_binfolder}/snrinit
	rm -f %{_binfolder}/swmgr
	rm -f %{_binfolder}/ts_cp
	rm -f %{_binfolder}/tzch
	rm -f %{_binfolder}/tzls
	rm -f %{_binfolder}/vlanch
	rm -f %{_binfolder}/vlandef
	rm -f %{_binfolder}/vlanls
	rm -f %{_binfolder}/vlanrm
	rm -f %{_binfolder}/unzip
	rm -f %{_binfolder}/httpmgr
	rm -f %{_binfolder}/apg-adm
	rm -f %{_binfolder}/spadm
	rm -f %{_binfolder}/wdmgr
        rm -f %{_binfolder}/rpskeymgmt
fi
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} preuninstall script during upgrade phase"
fi


%postun
if [ $1 == 0 ]; then
	echo "This is the %{name}-%{version} package %{release} postuninstall script during uninstall phase"
fi
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} postuninstall script during upgrade phase"
fi


%changelog
* Tue Jul 30 2021 - anjireddy.d (at) tcs.com
- Included fqdndef command for APG43L Security Enhancement SYSLOG adaption support
* Tue Apr 21 2020 - bipin.p (at) tcs.com
- Included ping6 and traceroute6 commands for IPv6 support
* Fri Oct 11 2019 - gnaneswara.b (at) tcs.com
- Removed httpproxy command (WA for sec 2.11 impacts)
* Mon Jul 01 2019 - gnaneswara.b (at) tcs.com
- include httpproxy command as part of sec 2.11 impacts
* Fri Sep 28 2018 - pranshu.sinha (at) tcs.com
- Adaptation to SWM2.0
* Wed Sep 26 2018 - naveen.g4 (at) tcs.com
- Added apg-adm command
* Tue Mar 06 2018 - gianluca.santoro (at) ericsson.com
- Adaptation to SwM2.0
* Thu Jan 19 2017 - mallikarjuna.dogiparthi (at) tcs.com
- Added swmgr command
* Wed Jun 22 2016 - b.swapnika (at) tcs.com
- implementation: removed gdb-bt command
* Fri Feb 19 2016 - antonio.nicoletti (at) ericsson.com
- implementation: added servicemgmt tool
* Mon Feb 01 2016 - antonio.nicoletti (at) ericsson.com
- implementation: added usermgmt tool
* Wed Aug 12 2015 - dharma.gondu (at) tcs.com
- Added ftp_port_20 command
* Wed Aug 12 2015 - antonio.buonocunto (at) ericsson.com
- Added localuser
* Fri Sep 19 2014 - fabrizio.paglia (at) dektech.com.au
- Added httpmgr command.
* Mon Aug 4 2014 - fabrizio.paglia (at) dektech.com.au
- Added unzip command.
* Mon Feb 24 2014 - stefano.volpe (at) ericsson.com
- Added bspmngr command.
* Mon Dec 16 2013 - giuseppe.pontillo (at) ericsson.com
- OSCMDBIN - R1A15 - implementation: added  chkconfigls, lspci, smartctl, drbd-overview, 
service-status-all, partls, tipc-link-stat, lvdisplay, pvdisplay, vgdisplay, 
eri-ipmitool, pam_tally2, dmidecode, gdb-bt, sg_mapx, repquota, tcpdump, lde-brf.
* Fri Sep 27 2013 - fabrizio.paglia (at) dektech.com.au
- Changes in apos_operations. 
* Tue Aug 27 2013 - marco.zambonelli (at) dektech.com.au
- rifdef rifrm commands added.
* Fri Jun 21 2013 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.7 implementation: fixes in raidmgmt.
* Tue Jun 04 2013 - Uppada pratap reddy (at) tcs.com
- OSCMDBIN 1.0.01 - Updated APOS version and replaced drbdmgr with ddmgr
* Fri May 24 2013 - Uppada pratap reddy (at) tcs.com
- OSCMDBIN 1.3.04 implementation: removed raidmgr script
* Tue May 14 2013 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.5 implementation: fixes in ps*, vlan* and clusterconf commands.
* Tue Apr 09 2013 - Uppada pratap reddy (at) tcs.com
- OSCMDBIN 1.3.04 implementation: added drbdmgr script
* Mon Apr 08 2013 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.4.01 implementation: bios_upgrade is now named bioschg, changes in vlanls, ts_cp.
* Tue Mar 12 2013 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.3.04 implementation: added bios_upgrade, changes in psls, psdef,ping, raidmgr, ver, shelfmngr, snrinit.
* Tue Feb 05 2013 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.3.03 implementation: added ts_cp.
* Tue Dec 18 2012 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.3.01 implementation.
* Tue Dec 04 2012 - francesco.rainone (at) ericsson.com
- OSCMDBIN 1.2.10 implementation: updated commands.
* Tue Nov 27 2012 - antonio.buonocunto (at) ericsson.com
- Apos 1.2.9 implementation: new linking mechanism.
* Thu Nov 15 2012 - francesco.rainone (at) ericsson.com
- Apos 1.2.8 implementation: ipmiconf and date.sh updated.
* Wed Oct 31 2012 - francesco.rainone (at) ericsson.com
- Apos 1.2.6 implementation: removal of clissexec binary.
* Tue Oct 30 2012 - francesco.rainone (at) ericsson.com
- Apos 1.2.6 implementation: ipmiconf command added.
* Wed Oct 17 2012 - antonio.buonocunto (at) ericsson.com
- Apos 1.2.5 implementation: raidmgr updation.
* Mon Oct 01 2012 - paolo.palmieri (at) ericsson.com
- Apos 1.2.4 implementation: adding the netls command.
* Mon Sep 03 2012 - francesco.rainone (at) ericsson.com
- Apos 1.2.2 implementation.
* Thu Aug 09 2012 - francesco.rainone (at) ericsson.com
- Apos 1.19 implementation
* Tue Jul 24 2012 - francesco.rainone (at) ericsson.com
- Apos 1.18 implementation
* Thu Jul 05 2012 - paolo.palmieri (at) ericsson.com
- Apos 1.16 implementation: merging commands from TCS branch
* Thu Jun 28 2012 - paolo.palmieri (at) ericsson.com
- Apos 1.16 adaptation
* Thu Jan 19 2012 - paolo.palmieri (at) ericsson.com
- Apos 1.14 implementation
* Tue Dec 20 2011 - francesco.rainone (at) ericsson.com
- Apos 1.13 implementation
* Wed Nov 16 2011 - francesco.rainone (at) ericsson.com
- Apos 1.12 implementation
* Mon Oct 24 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.11 implementation
* Mon Oct 17 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.10 implementation
* Thu Sep 01 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.9 implementation
* Fri Jul 29 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.8 implementation: added shelfmanager tool
* Tue Apr 05 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.5 implementation: raidmgmt fixed for mixed mode mgmt
* Tue Mar 15 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.4 implementation
* Wed Mar 09 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.3 patch: raidmgmt command patched to support same sd/dd sizes
* Wed Feb 09 2011 - paolo.palmieri (at) ericsson.com
- Apos 1.3: updated ftp command
* Thu Jan 27 2011 - francesco.rainone (at) ericsson.com
- added ftp and vdir commands
* Mon Dec 20 2010 - paolo.palmieri (at) ericsson.com
- Apos 1.2 implementation
* Mon Jul 05 2010 - sridhar.nakka (at) tcs.com
- Initial implementation
