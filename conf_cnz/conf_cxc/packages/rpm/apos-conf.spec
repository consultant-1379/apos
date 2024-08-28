##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Spec file for configuration of APOS
#
##
#
# Please send bugfixes or comments to paolo.palmieri@ericsson.com
#
##

# The following 2 lines disable the automatic resolution of "Requires" and "Provides" tags

%define __find_requires %{nil}
%define __find_provides %{nil}

%define packer %(finger -lp $(echo "$USER") | head -n 1 | cut -d: -f 3)
%define _topdir /var/tmp/%(echo "$USER")/rpms
%define _tmppath %_topdir/tmp
%define _target $RPM_BUILD_ROOT/opt/ap/apos/conf
%define _target_etc $RPM_BUILD_ROOT/opt/ap/apos/etc
%define _apos_vob_rootdir %{_cxcdir}/../..
%define _mipath /cluster/mi/installation
%define _usr_sys_path /usr/lib/systemd/system
%define _usr_scr_path /usr/lib/systemd/scripts

%define name            APOS_OSCONFBIN
%define version         %{_prNr}
%define release         %{_rel}

Name:                   %{name}
Summary:                APOS configuration package.
Version:                %{version}
Release:                %{release}
Prefix:                 /usr
License:                Ericsson Proprietary
Vendor:                 Ericsson LM
Packager:               %packer
Group:                  APOS/Configuration
BuildRoot:              %_tmppath

%define _requires_cbas brf-cmw-adapter-cxp9018859 brf-coordinator-cxp9018859 brf-eia-cxp9024651 brf-participant-proxy-cxp9018859 com-access-management-cxp9028493 com-cli-cxp9028493 com-cli-pipe-cxp9028493 com-access-management-cxp9028493 com-cli-cxp9028493 com-cli-pipe-cxp9028493 com-comea-cxp9028493 com-cxp9028493 com-file-management-cxp9028493 com-fm-cxp9028493 com-maf-cxp9028493 com-maf-optional-cxp9028493 com-netconf-cxp9028493 com-notification-service-cxp9028493 com-passwd-cxp9028493 com-pm-cxp9028493 com-poco-cxp9028493 com-sshd-manager-cxp9028493 com-subshell-cxp9028493 com-tls-proxy-cxp9028493 com-util-cxp9028493 coremw-common-cxp9020355 coremw-opensaf-cxp9020355 coremw-sc-cxp9020355 lde-scaling-cmw-cxp9020125 lde-imm-cxp9020125 lde-prompt-cxp9020125 opensaf opensaf-amf-director opensaf-amf-libs opensaf-amf-nodedirector opensaf-ckpt-director opensaf-ckpt-libs opensaf-ckpt-nodedirector opensaf-clm-libs opensaf-clm-nodeagent opensaf-clm-server opensaf-controller opensaf-imm-director opensaf-imm-libs opensaf-imm-nodedirector opensaf-libs opensaf-log-libs opensaf-log-server opensaf-ntf-libs opensaf-ntf-server opensaf-pm-director opensaf-pm-libs opensaf-pm-nodedirector opensaf-smf-director opensaf-smf-libs opensaf-smf-nodedirector opensaf-tools sec-acs-cxp9026450 sec-cert-agent-cxp9027891 sec-cert-manager-cxp9027891 sec-crypto-cxp9027895 sec-la-ldap-cxp9026994 sec-la-oi-cxp9026994 sec-la-sm-cxp9026994 sec-ldap-cxp9028981 sec-ldap-sm-cxp9028981 sec-secm-cxp9028976 sec-secm-ln-cxp9028976 com-comsa-cxp9028493 com-tlsd-cxp9028493 com-vsftpd-manager-cxp9028493 com-vsftpd-cxp9028493

%define _requires_pkgs acct, acl, alsa-lib, apache, apache2, apache2-prefork, apache2-utils, apache2-worker,  boost-license, boost-license1_54_0, cdrdao, cdrkit-cdrtools-compat, crzip, dvd+rw-tools, flex, ftp-server, httpd, http_daemon, icedax, ipsec-tools, lftp, lftp-beta, libao, libao-plugins4, libao4, libapr-util1, libapr1, libboost_atomic1_54_0, libboost_chrono1_54_0, libboost_date_time1_54_0, libboost_filesystem1_54_0, libboost_graph1_54_0, libboost_graph_parallel1_54_0, libboost_iostreams1_54_0, libboost_locale1_54_0, libboost_log1_54_0, libboost_math1_54_0, libboost_mpi1_54_0, libboost_program_options1_54_0, libboost_python1_54_0, libboost_random1_54_0, libboost_regex1_54_0, libboost_serialization1_54_0, libboost_signals1_54_0, libboost_system1_54_0, libboost_test1_54_0, libboost_thread1_54_0, libboost_timer1_54_0, libboost_wave1_54_0, libburn4, libdnet1, libflac, libFLAC8, libgnutls28, libgobject-2_0-0, libhogweed2, libibverbs1, libicu, libicu52_1, libicu52_1-data, libkate1, liblua5_2, libnettle4, libogg0, liboggkate1, libp11-kit0, libpulse0, libsndfile, libsndfile1, libspeex, libspeex1, libtasn1, libtasn1-6, libmspack0, libvmtools0, libvorbis, libvorbis0, libvorbisenc2, libvorbisfile3, libxerces-c-3_1, lsscsi, lua-libs, openldap2-back-meta, openmpi-libs, open-vm-tools, php, php-api, php-date, php-filter, php-hash, php-pcre, php-reflection, php-session, php-simplexml, php-spl, php-xml, php-zend-abi, php5, php5-hash, postfix, pulseaudio-libs, quota, racoon, rsh, rsh-server, sg3_utils, smtp_daemon, strongswan, suse_help_viewer, suse_maintenance_mmn_0, tcpd, unzip, vorbis-tools, vsftpd, wodim, Xerces-c, zend, zip

%define _requires_3pp libACE, openssh

# Manual dependencies
Requires: %{_requires_cbas}, %{_requires_pkgs}, %{_requires_3pp}, APOS_OSCMDBIN

%description
Configuration package for APOS.

%prep

%build

%pre
if [ $1 == 1 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during installation phase"
fi
if [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} preinstall script during upgrade phase"
fi


%install
echo "This is the %{name}-%{version} package %{release} install script"
mkdir -p %{_target}/
mkdir -p %{_target}/apos_common_res
mkdir -p %{_target}/vdir/
mkdir -p %{_target}/vsftpd/
mkdir -p %{_target_etc}/templates/
mkdir -p %{_target_etc}/models/
mkdir -p %{_target_etc}/enm_models/
mkdir -p %{_target_etc}/deploy/default_rp_key

# Copy of the files in the bin and apos_common_res folders (only first level: no recursive copy)
if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/bin/ | wc -l) -gt 0 ]; then
	install -m 555 $(find %{_apos_vob_rootdir}/conf_cnz/bin/ -maxdepth 1 -type f) %{_target}/
	install -m 555 $(find %{_apos_vob_rootdir}/conf_cnz/bin/apos_common_res -maxdepth 1 -type f) %{_target}/apos_common_res
fi

# Copy of the update scripts
if [ -d %{_apos_vob_rootdir}/conf_cnz/bin/update ]; then
  mkdir -p %{_target}/update
  LIST=$(find %{_apos_vob_rootdir}/conf_cnz/bin/update -maxdepth 1 -type d | tail -n +2)
  for DIR in $LIST; do
    DEST_DIR=$(echo $DIR | awk -F'/' '{print $NF}')
    mkdir -p %{_target}/update/$DEST_DIR
	  if [ $(find $DIR -maxdepth 1 -type f | wc -l) -gt 0 ]; then
		  install -m 554 $(find $DIR -maxdepth 1 -type f) %{_target}/update/$DEST_DIR
	  fi
  done
fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf/ | wc -l) -gt 0 ]; then
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/GEP1_66-apos_disks.rules %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/GEP2_66-apos_disks.rules %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/GEP5_66-apos_disks.rules %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/GEP7_66-apos_disks.rules %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/VM_66-apos_disks.rules %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/hwtype.dat %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/hwinfo.dat %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/apos_ver.conf %{_target}/
    install -m 644 %{_apos_vob_rootdir}/conf_cnz/conf/serial_grub.cfg %{_target}/
    install -m 644 %{_apos_vob_rootdir}/conf_cnz/conf/vga_grub.cfg %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/fbs.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcom_authorization_agent.cfg %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcom_cli_agent.cfg %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/sec.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/sd_folder.list %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/sd_subsystem.list %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/siteparam.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/vsftpd.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/apos_ftp_state.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/welcomemessage.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/simucliss.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/sd_folder_ap2.list %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/sd_subsystem_ap2.list %{_target}/
    install -m 555 %{_apos_vob_rootdir}/conf_cnz/conf/enlarged_ddisk_impacts.sh %{_target}/
    install -m 555 %{_apos_vob_rootdir}/conf_cnz/conf/config_params.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/template_rsyslog.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/template_lde_streaming_messages.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/template_lde_streaming_auth.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/template_lde_streaming_kernel.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/apg_rsyslog_global_template.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/apg-log-stream-template.conf %{_target}/ 
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcli_extension_subshell.conf %{_target}/	
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcli_extension_subshell_header.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcli_extension_subshell_tail.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcom_tls_proxy.cfg %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/libcom_tlsd_manager.cfg %{_target}/
		install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/ldap_aa.conf %{_target}/
    install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf/apg_sw_activation_table.yaml %{_target}/
    install -m 644 %{_apos_vob_rootdir}/conf_cnz/conf/logm_info.conf %{_target}/	

fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf/vdir/ | wc -l) -gt 0 ]; then
	install -m 644 %{_apos_vob_rootdir}/conf_cnz/conf/vdir/* %{_target}/vdir/
fi
if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf/vsftpd/ | wc -l) -gt 0 ]; then
	install -m 644 %{_apos_vob_rootdir}/conf_cnz/conf/vsftpd/* %{_target}/vsftpd/
fi
if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/templates/ | wc -l) -gt 0 ]; then
	install -m 444 %{_apos_vob_rootdir}/conf_cnz/templates/* %{_target_etc}/templates/
fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/ | wc -l) -gt 0 ]; then
	install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/*_imm_*.xml %{_target_etc}/models/
fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/ | wc -l) -gt 0 ]; then
        install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/*_mp.xml %{_target_etc}/models/
fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/ | wc -l) -gt 0 ]; then
        install -m 444 %{_apos_vob_rootdir}/conf_cnz/conf_cxc/conf/*_ENM_*.xml %{_target_etc}/enm_models/
fi

if [ $(ls -1A %{_apos_vob_rootdir}/conf_cnz/deploy/etc/ | wc -l)  -gt 0 ]; then
        install -m 660 %{_apos_vob_rootdir}/conf_cnz/deploy/etc/ssh_key_rp %{_target_etc}/deploy/default_rp_key/
fi

# Automatic tarballs creation
pushd %{_apos_vob_rootdir}/conf_cnz/deploy/
./tarme.sh || exit 1
popd

mkdir -p %{_target_etc}/deploy/
#
# For the list of files to be deployed the content of the file 
# %{_apos_vob_rootdir}/conf_cnz/deploy/files will be parsed.
#
LIST=$(<%{_apos_vob_rootdir}/conf_cnz/deploy/files)
for ITEM in $LIST; do
	FILE=$(echo $ITEM | awk -F\| '{ print $1 }')
	MODE=$(echo $ITEM | awk -F\| '{ print $2 }')
	if [ -f %{_apos_vob_rootdir}/conf_cnz/deploy/${FILE} ]; then
		if [ ! -d %{_target_etc}/deploy/$( dirname $FILE ) ]; then
			mkdir -p %{_target_etc}/deploy/$( dirname $FILE )
		fi
		install -m ${MODE} %{_apos_vob_rootdir}/conf_cnz/deploy/${FILE} %{_target_etc}/deploy/${FILE}
	fi
done


%files
%defattr(-,root,root)
/opt/ap/apos/conf/apos_cba_workarounds.sh
/opt/ap/apos/conf/apos_blacklistconf.sh
/opt/ap/apos/conf/apos_comconf.sh
/opt/ap/apos/conf/apos_cleanup.sh
/opt/ap/apos/conf/apos_common.sh
/opt/ap/apos/conf/apos_common_res/mac_addr_op.sh
/opt/ap/apos/conf/apos_common_res/cust_nics_op.sh
/opt/ap/apos/conf/apos_common_res/monitor_exec.sh
/opt/ap/apos/conf/apos_common_res/servicemgmt.sh
/opt/ap/apos/conf/apos_conf.sh
/opt/ap/apos/conf/apos_crmconf.sh
/opt/ap/apos/conf/apos_deploy.sh
/opt/ap/apos/conf/apos_drbdconf.sh
/opt/ap/apos/conf/apos_drbd_status
/opt/ap/apos/conf/apos_failoverd_conf.sh
/opt/ap/apos/conf/apos_finalize.sh
/opt/ap/apos/conf/apos_finalize_system_conf.sh
/opt/ap/apos/conf/apos_ftpconf.sh
/opt/ap/apos/conf/apos_is-datadisk.sh
/opt/ap/apos/conf/apos_netconf.sh
/opt/ap/apos/conf/apos_fuseconf.sh
/opt/ap/apos/conf/apos_guest.sh
/opt/ap/apos/conf/apos_grub_update_users.sh
/opt/ap/apos/conf/apos_hwinfo.sh
/opt/ap/apos/conf/apos_hwtype.sh
/opt/ap/apos/conf/apos_insserv.sh
/opt/ap/apos/conf/apos_iptables.sh
/opt/ap/apos/conf/apos_ldapconf.sh
/opt/ap/apos/conf/apos_logindenial.sh
/opt/ap/apos/conf/apos_mkdir.sh
/opt/ap/apos/conf/apos_mkdir_sd.sh
/opt/ap/apos/conf/apos_models_conf.sh
/opt/ap/apos/conf/apos_postinstall.sh
/opt/ap/apos/conf/apos_rootlock.sh
/opt/ap/apos/conf/apos_secacs-toolkit.sh
/opt/ap/apos/conf/apos_sec-ldapconf.sh
/opt/ap/apos/conf/apos_system_conf.sh
/opt/ap/apos/conf/apos_sysconf.sh
/opt/ap/apos/conf/apos_skelconf.sh
/opt/ap/apos/conf/apos_smartdisk.sh
/opt/ap/apos/conf/apos_udevconf.sh
/opt/ap/apos/conf/apos_update.sh
/opt/ap/apos/conf/apos_vdirconf.sh
/opt/ap/apos/conf/aposcfg_appendgroup.sh
/opt/ap/apos/conf/aposcfg_axe_sysroles.sh
/opt/ap/apos/conf/aposcfg_audit-rules.sh
/opt/ap/apos/conf/aposcfg_auditd.sh
/opt/ap/apos/conf/aposcfg_axe_info.sh
/opt/ap/apos/conf/aposcfg_bash-bashrc-local.sh
/opt/ap/apos/conf/aposcfg_boot-local.sh
/opt/ap/apos/conf/aposcfg_common-account.sh
/opt/ap/apos/conf/aposcfg_common-auth.sh
/opt/ap/apos/conf/aposcfg_common-session.sh
/opt/ap/apos/conf/aposcfg_common-password.sh
/opt/ap/apos/conf/apos_password_hardenrules.sh
/opt/ap/apos/conf/aposcfg_device-map.sh
/opt/ap/apos/conf/aposcfg_group.sh
/opt/ap/apos/conf/aposcfg_login-defs.sh
/opt/ap/apos/conf/aposcfg_menu-lst.sh
/opt/ap/apos/conf/aposcfg_rp_sshkey_mgmt.sh
/opt/ap/apos/conf/aposcfg_motd.sh
/opt/ap/apos/conf/aposcfg_nscd-conf.sh
/opt/ap/apos/conf/aposcfg_opasswd.sh
/opt/ap/apos/conf/aposcfg_profile-local.sh
/opt/ap/apos/conf/aposcfg_profile-local_AP2.sh
/opt/ap/apos/conf/aposcfg_profile.sh
/opt/ap/apos/conf/aposcfg_rsh.sh
/opt/ap/apos/conf/aposcfg_sec-conf.sh
/opt/ap/apos/conf/aposcfg_securetty.sh
/opt/ap/apos/conf/aposcfg_sshd_config.sh
/opt/ap/apos/conf/aposcfg_syncd-conf.sh
/opt/ap/apos/conf/aposcfg_sysctl-conf.sh
/opt/ap/apos/conf/aposcfg_syslog-conf.sh
/opt/ap/apos/conf/aposcfg_rsyslog_service.sh
/opt/ap/apos/conf/apos_vlanqos.sh
/opt/ap/apos/conf/apos_snrinit_rebuild.sh
/opt/ap/apos/conf/apos_subsystem_wrapper.sh
/opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh
/opt/ap/apos/conf/apos_add_default_ipv6_gw.sh
/opt/ap/apos/conf/apos_kernel_parameter_change.sh
/opt/ap/apos/conf/apos_certgrp.sh
# placeholder for the (optional) update scripts
# /opt/ap/apos/conf/update/CXC-VERSION/from<RSTATE>.sh
/opt/ap/apos/conf/update/CXC1371465/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371465/fromR1F.sh
/opt/ap/apos/conf/update/CXC1371465/fromR2A.sh
/opt/ap/apos/conf/update/CXC1371465/fromR2B.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499/fromR2A.sh
/opt/ap/apos/conf/update/CXC1371544/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371544/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371544/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371544_5/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A13.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A14.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A15.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1A16.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_5/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_6/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_7/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A10.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A11.sh
/opt/ap/apos/conf/update/CXC1371499_8/fromR1A12.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1A10.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_9/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_10/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_11/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A07.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A08.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A09.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A10.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A11.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1A12.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_12/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_13/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1A06.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_14/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_15/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_16/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_17/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_17/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_17/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_17/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_17/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1A02.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1A03.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1A04.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1A05.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1B.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1C.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1D.sh
/opt/ap/apos/conf/update/CXC1371499_18/fromR1E.sh
/opt/ap/apos/conf/update/CXC1371499_19/fromR1A01.sh
/opt/ap/apos/conf/update/CXC1371499_19/fromR1A02.sh
/opt/ap/apos/conf/GEP1_66-apos_disks.rules
/opt/ap/apos/conf/GEP2_66-apos_disks.rules
/opt/ap/apos/conf/GEP5_66-apos_disks.rules
/opt/ap/apos/conf/GEP7_66-apos_disks.rules
/opt/ap/apos/conf/VM_66-apos_disks.rules
/opt/ap/apos/conf/hwtype.dat
/opt/ap/apos/conf/hwinfo.dat
/opt/ap/apos/conf/apos_ver.conf
/opt/ap/apos/conf/config_params.conf
/opt/ap/apos/conf/serial_grub.cfg
/opt/ap/apos/conf/vga_grub.cfg
/opt/ap/apos/conf/fbs.conf
/opt/ap/apos/conf/libcom_cli_agent.cfg
/opt/ap/apos/conf/libcom_authorization_agent.cfg
/opt/ap/apos/conf/sd_folder.list
/opt/ap/apos/conf/sd_subsystem.list
/opt/ap/apos/conf/siteparam.conf
/opt/ap/apos/conf/template_rsyslog.conf
/opt/ap/apos/conf/template_lde_streaming_messages.conf
/opt/ap/apos/conf/template_lde_streaming_kernel.conf
/opt/ap/apos/conf/template_lde_streaming_auth.conf
/opt/ap/apos/conf/apg_rsyslog_global_template.conf
/opt/ap/apos/conf/apg-log-stream-template.conf
/opt/ap/apos/conf/vsftpd.conf
/opt/ap/apos/conf/vdir/vd-conf
/opt/ap/apos/conf/vsftpd/userdeny
/opt/ap/apos/conf/vsftpd/vsftpd.conf
/opt/ap/apos/conf/vsftpd/vsftpd-APIO_1.conf
/opt/ap/apos/conf/vsftpd/vsftpd-APIO_2.conf
/opt/ap/apos/conf/welcomemessage.conf
/opt/ap/apos/conf/apos_ftp_state.conf
/opt/ap/apos/conf/sd_folder_ap2.list
/opt/ap/apos/conf/sd_subsystem_ap2.list
/opt/ap/apos/conf/enlarged_ddisk_impacts.sh
/opt/ap/apos/conf/sec.conf
/opt/ap/apos/conf/simucliss.conf
/opt/ap/apos/conf/libcli_extension_subshell.conf
/opt/ap/apos/conf/libcli_extension_subshell_header.conf
/opt/ap/apos/conf/libcli_extension_subshell_tail.conf
/opt/ap/apos/conf/libcom_tls_proxy.cfg
/opt/ap/apos/conf/libcom_tlsd_manager.cfg
/opt/ap/apos/conf/ldap_aa.conf
/opt/ap/apos/conf/apg_sw_activation_table.yaml
/opt/ap/apos/conf/apg_sw_activation_check.py
/opt/ap/apos/conf/apos_cfgd
/opt/ap/apos/conf/logm_info.conf
/opt/ap/apos/etc/models/c_AxeNbiFolders_imm_classes.xml
/opt/ap/apos/etc/models/o_AxeNbiFoldersNbiFoldersInstance_imm_objects.xml
/opt/ap/apos/etc/models/AxeNbiFolders_mp.xml
/opt/ap/apos/etc/models/APZIM_NetworkConfiguration_imm_classes.xml
/opt/ap/apos/etc/models/APZIM_NetworkConfiguration_imm_objects.xml
/opt/ap/apos/etc/models/APG_Roles_Rules_imm_objects.xml
/opt/ap/apos/etc/models/c_AxeFunctions_imm_classes.xml
/opt/ap/apos/etc/models/o_AxeFunctionsInstance_imm_objects.xml
/opt/ap/apos/etc/models/AxeFunctions_mp.xml
/opt/ap/apos/etc/models/AxeInfo_imm_classes.xml
/opt/ap/apos/etc/enm_models/MSC_ENM_Roles_Rules.xml
/opt/ap/apos/etc/enm_models/HLR_ENM_Roles_Rules.xml
/opt/ap/apos/etc/enm_models/IPSTP_ENM_Roles_Rules.xml
/opt/ap/apos/etc/templates/sshd_config_template
/opt/ap/apos/etc/deploy/cluster/hooks/after-booting-from-disk.tar.gz
/opt/ap/apos/etc/deploy/cluster/hooks/post-installation.tar.gz
/opt/ap/apos/etc/deploy/cluster/hooks/pre-installation.tar.gz
/opt/ap/apos/etc/deploy/etc/audit/rules.d/901-apg-users.rules
/opt/ap/apos/etc/deploy/etc/nscd.conf
/opt/ap/apos/etc/deploy/etc/nsswitch.conf
/opt/ap/apos/etc/deploy/etc/10-apg-rsyslog-rule
/opt/ap/apos/etc/deploy/etc/02-lde-syslog-logstream-list.conf
/opt/ap/apos/etc/deploy/default_rp_key/ssh_key_rp
/opt/ap/apos/etc/deploy/etc/openldap/slapd.conf
/opt/ap/apos/etc/deploy/etc/openldap/schema/euac-extended.schema
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-account-failure
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-account-success
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-auth-failure
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-auth-success
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-auth-role2group
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-lockout-tsadmin
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-lockout-tsgroup
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-password-local
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-session-heading
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-session-success
/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-common-banner
/opt/ap/apos/etc/deploy/etc/systemd/system/dhcpd.service.d/lde.conf
/opt/ap/apos/etc/deploy/etc/ssh/sshd_config_4422
/opt/ap/apos/etc/deploy/etc/ssh/sshd_config_22
/opt/ap/apos/etc/deploy/etc/ssh/sshd_config_830
/opt/ap/apos/etc/deploy/etc/ssh/sshd_config_mssd
/opt/ap/apos/etc/deploy/etc/sysconfig/atftpd
/opt/ap/apos/etc/deploy/etc/sysconfig/atftpd_AP2
/opt/ap/apos/etc/deploy/etc/sysconfig/auditd
/opt/ap/apos/etc/deploy/etc/sysconfig/openldap
/opt/ap/apos/etc/deploy/etc/dhcpd.conf.local
/opt/ap/apos/etc/deploy/etc/dhcpd.conf.local_vm
/opt/ap/apos/etc/deploy/etc/ntp.conf.local
/opt/ap/apos/etc/deploy/etc/chrony.conf.local
/opt/ap/apos/etc/deploy/etc/smartd.conf
/opt/ap/apos/etc/deploy/etc/sudoers.d/APG-comgroup_drbd
/opt/ap/apos/etc/deploy/etc/sudoers.d/APG-tsgroup_drbd
/opt/ap/apos/etc/deploy/etc/sudoers.d/APG-tsadmin
/opt/ap/apos/etc/deploy/etc/sudoers.d/APG-comgroup_md
/opt/ap/apos/etc/deploy/etc/sudoers.d/APG-tsgroup_md
/opt/ap/apos/etc/deploy/etc/services_drbd
/opt/ap/apos/etc/deploy/etc/services_md
/opt/ap/apos/etc/deploy/etc/bindresvport.blacklist
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_dhcpd-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_ntp-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_drbd-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_drbd-config_10g
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_drbd-config_VM
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_exports-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_ftp-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_grub-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_ip-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_logrotd-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_rhosts-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_secacs-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_sshd-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_syslog-config
/opt/ap/apos/etc/deploy/usr/lib/lde/config-management/apos_rp-hosts-config
/opt/ap/apos/etc/deploy/usr/lib/lde/failoverd-helpers/apg-defaults
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-atftps.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-auditd.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-clearchipwdog.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-dhcpd.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apos-finalize-system-conf.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apos-system-conf.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-ldap.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apos-drbd.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apg-drbd-meta-convert
/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apos-recovery-conf.sh
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-atftpd@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-atftps.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-clearchipwdog.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-dhcpd.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-ldap.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-netconf-beep@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-netconf-beep.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-rsh@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-rsh.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-nbi@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-nbi.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-APIO_1@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-APIO_1.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-APIO_2@.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apg-vsftpd-APIO_2.socket
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-drbd.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-early-system-config.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-finalize-system-config.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-system-config.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/auditd.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/dhcpd.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/smartd.service
/opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-recovery-conf.service
/opt/ap/apos/etc/deploy/usr/share/filem/internal_filem_root.conf
/opt/ap/apos/etc/deploy/usr/share/filem/nbi_filem_root.conf
/opt/ap/apos/etc/deploy/etc/systemd/system/lde-sshd@sshd_config_22.service.d/apg_sshd.conf
/opt/ap/apos/etc/deploy/etc/systemd/system/lde-sshd@sshd_config_4422.service.d/apg_sshd.conf
/opt/ap/apos/etc/deploy/etc/systemd/system/lde-sshd@sshd_config_830.service.d/apg_sshd.conf
/opt/ap/apos/etc/deploy/etc/systemd/system/lde-sshd@sshd_config_mssd.service.d/apg_sshd.conf
/opt/ap/apos/etc/deploy/etc/modprobe.d/lde-disable-unused-filesystems.conf
%doc

%post

storage_api='/usr/share/pso/storage-paths/config'
storage_path=$(cat $storage_api)
is_vm=''
is_vm_install=''
if [ -f /cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf ];  then
  is_vm=$(cat /cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf | grep -i installation_hw | awk -F "=" '{print $2}')
fi
if [ "$is_vm" == "VM" ];  then
  is_vm_install="true"
fi

if [ -f $storage_path/apos/aptype.conf ]; then
        ap_type=$( cat $storage_path/apos/aptype.conf )
fi

if [[ -z "$ap_type" && -f %{_mipath}/ap_type ]]; then
        ap_type=$( cat %{_mipath}/ap_type)
fi

if [ "$ap_type" == "AP2" ]; then
        rm %{_target_etc}/deploy/etc/sysconfig/atftpd
        mv %{_target_etc}/deploy/etc/sysconfig/atftpd_AP2 %{_target_etc}/deploy/etc/sysconfig/atftpd
fi


if [ "$ap_type" == "AP1" ]; then
    rm %{_target_etc}/deploy/etc/sysconfig/atftpd_AP2
fi

cmd_hwtype='/opt/ap/apos/conf/apos_hwtype.sh'
is_cee=''
HW_TYPE=$( $cmd_hwtype --verbose | grep 'system-manufacturer' | awk -F '=' '{print $2}')
if [[ "$HW_TYPE" =~ ^openstack.* ]]; then
  is_cee="true"
fi

if [ "$is_vm_install" != "true" ];  then
  if [ "$is_cee" == "true" ]; then
    # Script to start apos-recovery-conf.service
		if [ ! -f %{_usr_sys_path}/apos-recovery-conf.service ]; then 
		  install -m 644 /opt/ap/apos/etc/deploy/usr/lib/systemd/system/apos-recovery-conf.service %{_usr_sys_path}/
			if [ $? -ne 0 ]; then
			  echo "Failed to copy apos-recovery-conf.service to /usr/lib/systemd/system folder"
				exit 1
			fi 

			install -m 755 /opt/ap/apos/etc/deploy/usr/lib/systemd/scripts/apos-recovery-conf.sh %{_usr_scr_path}/
			if [ $? -ne 0 ]; then
			  echo "Failed to copy apos-recovery-conf.sh to /usr/lib/systemd/scripts folder"
				exit 1
			fi

			systemctl enable apos-recovery-conf.service
			if [ $? -ne 0 ]; then
			  echo "Failed to enable apos-recovery-conf.service"
				exit 1
			fi 
    fi 
		
    /usr/bin/systemctl start apos-recovery-conf.service
    if [ $? -ne 0 ]; then
      echo "apos-recovery-conf.service ended with errors"
      exit 1
    else
      echo -e "\nINFO: apos-recovery-conf.service is started successfully"
    fi
  fi
fi

if [ $1 == 1 ]; then
  echo "This is the %{name}-%{version} package %{release} postinstall script during installation phase"
  echo -e "\nINFO: Running APOS configuration..." 
  if [ "$is_vm_install" != "true" ];  then
      # Running APOS configuration routines
    /opt/ap/apos/conf/apos_conf.sh	                                        
    if [ $? -ne 0 ]; then                                                        
      echo "apos_conf.sh ended with errors"                                      
      exit 1                                                                     
    else                                                                         
      echo -e "\nINFO: APOS configuration is done successfully"              
    fi
  fi    
fi
if [ $1 == 2 ]; then
	echo "This is the %{name}-%{version} package %{release} postinstall script during upgrade phase"
	export OLD_APOS_CONF_NAME='unknown'
	export OLD_APOS_CONF_VERSION
	export OLD_APOS_CONF_RELEASE='unknown'
	if rpm -q %{name} &>/dev/null; then
		OLD_APOS_CONF=$( rpm -q %{name}| grep -Ev '%{version}-%{release}\.x86_64$' | sed 's@\.x86_64$@@g' )
		OLD_APOS_CONF_NAME=$( echo "${OLD_APOS_CONF}" | awk -F- '{print $1}' )
		OLD_APOS_CONF_VERSION=$( echo "${OLD_APOS_CONF}" | awk -F- '{print $2}' )
		OLD_APOS_CONF_RELEASE=$( echo "${OLD_APOS_CONF}" | awk -F- '{print $NF}' )
	fi
	echo "upgrading from ${OLD_APOS_CONF_NAME}-${OLD_APOS_CONF_VERSION}-${OLD_APOS_CONF_RELEASE}"	
  /opt/ap/apos/conf/apos_update.sh ${OLD_APOS_CONF_VERSION} ${OLD_APOS_CONF_RELEASE}
	if [ $? -ne 0 ]; then
		echo "apos_update.sh ended with errors"
		exit 1
	else
		echo -e "\nINFO: APOS configuration is done successfully"
	fi
fi

if [ "$is_vm_install" != "true" ];  then
  # Script for cleaning-up apos directories according to installation parameters.
  /opt/ap/apos/conf/apos_cleanup.sh                                             
  if [ $? -ne 0 ]; then                                                         
    echo "apos_cleanup.sh ended with errors"                                    
    exit 1                                                                      
  else                                                                          
    echo -e "\nINFO: APOS cleanup is done successfully"                         
  fi
fi

%preun
if [ $1 == 0 ]; then
	echo "This is the %{name}-%{version} package %{release} preuninstall script during uninstall phase"
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
* Tue Apr 12 2022 - P S SOUMYA (at) tcs.com
- OSCONFBIN - added apos_certgrp.sh
* Thu Mar 03 2022 - pravalika.p (at) tcs.com
- OSCONFBIN - added chrony.conf.local for chrony support
* Mon Oct 26 2020 - gvl.sowjanya (at) tcs.com
- OSCONFBIN - added 901-apg-users.rules for SLES12 SP5 audit rules NBC
* Tue Apr 21 2020 - bipin.p (at) tcs.com
- OSCONFBIN - added ping6 and traceroute6 for IPv6 support
* Fri Sep 28 2018 - pranshu.sinha (at) tcs.com
- OSCONFBIN - added handling for SNR in SWM2.0
* Mon Jan 23 2017 - franco.dambrosio (at) ericsson.com
- OSCONFBIN - added apos_guest.sh
* Fri Dec 02 2016 - antonio.buonocunto (at) ericsson.com
- OSCONFBIN - added aposcfg_axeinfo.sh
* Thu Dec 01 2016 - alessio.cascone (at) ericsson.com
- OSCONFBIN - added AxeInfo model deployment.
