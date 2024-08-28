##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Spec file for installation of libboost
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
%define _topdir /var/tmp/%(echo "$USER")/rpms/libboost
%define _tmppath %_topdir/tmp
%define _target $RPM_BUILD_ROOT/opt/ap/apos/lib64

%define version		1.44.0
%define maj_version	`echo %{version} | sed "s/\\..*$//g"`
%define folder_version	`echo "boost_"%{version} | tr '.' '_'`
%define release		0.6

Name:      libboost
Summary:   Installation package for BOOST framework.
Version:   %{version}
Release:   %{release}
License:   Ericsson Proprietary
Vendor:    Ericsson LM
Packager:  %packer
Group:     Library
BuildRoot: %_tmppath


%description
Installation package for BOOST Framework.


%pre


%install
mkdir -p %{_target}
FVER=%{folder_version}
if [ `ls -1A /vobs/IO_Developments/BOOST_SDK/$FVER/lib/ | wc -l` -gt 0 ]; then
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_date_time.so.%{version} %{_target}/libboost_date_time.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_filesystem.so.%{version} %{_target}/libboost_filesystem.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_graph.so.%{version} %{_target}/libboost_graph.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_iostreams.so.%{version} %{_target}/libboost_iostreams.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_c99.so.%{version} %{_target}/libboost_math_c99.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_c99f.so.%{version} %{_target}/libboost_math_c99f.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_c99l.so.%{version} %{_target}/libboost_math_c99l.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_tr1.so.%{version} %{_target}/libboost_math_tr1.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_tr1f.so.%{version} %{_target}/libboost_math_tr1f.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_math_tr1l.so.%{version} %{_target}/libboost_math_tr1l.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_prg_exec_monitor.so.%{version} %{_target}/libboost_prg_exec_monitor.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_program_options.so.%{version} %{_target}/libboost_program_options.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_python.so.%{version} %{_target}/libboost_python.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_random.so.%{version} %{_target}/libboost_random.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_regex.so.%{version} %{_target}/libboost_regex.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_serialization.so.%{version} %{_target}/libboost_serialization.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_signals.so.%{version} %{_target}/libboost_signals.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_system.so.%{version} %{_target}/libboost_system.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_thread.so.%{version} %{_target}/libboost_thread.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_unit_test_framework.so.%{version} %{_target}/libboost_unit_test_framework.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_wave.so.%{version} %{_target}/libboost_wave.so.%{version}
	install -m 554 /vobs/IO_Developments/BOOST_SDK/%{folder_version}/lib/libboost_wserialization.so.%{version} %{_target}/libboost_wserialization.so.%{version}
fi


%post
echo "Creating symbolic links"
cd /usr/lib64
ln -sf %{_target}/libboost_date_time.so.%{version} libboost_date_time.so.%{maj_version}
ln -sf %{_target}/libboost_date_time.so.%{version} libboost_date_time.so
ln -sf %{_target}/libboost_filesystem.so.%{version} libboost_filesystem.so.%{maj_version}
ln -sf %{_target}/libboost_filesystem.so.%{version} libboost_filesystem.so
ln -sf %{_target}/libboost_graph.so.%{version} libboost_graph.so.%{maj_version}
ln -sf %{_target}/libboost_graph.so.%{version} libboost_graph.so
ln -sf %{_target}/libboost_iostreams.so.%{version} libboost_iostreams.so.%{maj_version}
ln -sf %{_target}/libboost_iostreams.so.%{version} libboost_iostreams.so
ln -sf %{_target}/libboost_math_c99.so.%{version} libboost_math_c99.so.%{maj_version}
ln -sf %{_target}/libboost_math_c99.so.%{version} libboost_math_c99.so
ln -sf %{_target}/libboost_math_c99f.so.%{version} libboost_math_c99f.so.%{maj_version}
ln -sf %{_target}/libboost_math_c99f.so.%{version} libboost_math_c99f.so
ln -sf %{_target}/libboost_math_c99l.so.%{version} libboost_math_c99l.so.%{maj_version}
ln -sf %{_target}/libboost_math_c99l.so.%{version} libboost_math_c99l.so
ln -sf %{_target}/libboost_math_tr1.so.%{version} libboost_math_tr1.so.%{maj_version}
ln -sf %{_target}/libboost_math_tr1.so.%{version} libboost_math_tr1.so
ln -sf %{_target}/libboost_math_tr1f.so.%{version} libboost_math_tr1f.so.%{maj_version}
ln -sf %{_target}/libboost_math_tr1f.so.%{version} libboost_math_tr1f.so
ln -sf %{_target}/libboost_math_tr1l.so.%{version} libboost_math_tr1l.so.%{maj_version}
ln -sf %{_target}/libboost_math_tr1l.so.%{version} libboost_math_tr1l.so
ln -sf %{_target}/libboost_prg_exec_monitor.so.%{version} libboost_prg_exec_monitor.so.%{maj_version}
ln -sf %{_target}/libboost_prg_exec_monitor.so.%{version} libboost_prg_exec_monitor.so
ln -sf %{_target}/libboost_program_options.so.%{version} libboost_program_options.so.%{maj_version}
ln -sf %{_target}/libboost_program_options.so.%{version} libboost_program_options.so
ln -sf %{_target}/libboost_python.so.%{version} libboost_python.so.%{maj_version}
ln -sf %{_target}/libboost_python.so.%{version} libboost_python.so
ln -sf %{_target}/libboost_random.so.%{version} libboost_random.so.%{maj_version}
ln -sf %{_target}/libboost_random.so.%{version} libboost_random.so
ln -sf %{_target}/libboost_regex.so.%{version} libboost_regex.so.%{maj_version}
ln -sf %{_target}/libboost_regex.so.%{version} libboost_regex.so
ln -sf %{_target}/libboost_serialization.so.%{version} libboost_serialization.so.%{maj_version}
ln -sf %{_target}/libboost_serialization.so.%{version} libboost_serialization.so
ln -sf %{_target}/libboost_signals.so.%{version} libboost_signals.so.%{maj_version}
ln -sf %{_target}/libboost_signals.so.%{version} libboost_signals.so
ln -sf %{_target}/libboost_system.so.%{version} libboost_system.so.%{maj_version}
ln -sf %{_target}/libboost_system.so.%{version} libboost_system.so
ln -sf %{_target}/libboost_thread.so.%{version} libboost_thread.so.%{maj_version}
ln -sf %{_target}/libboost_thread.so.%{version} libboost_thread.so
ln -sf %{_target}/libboost_unit_test_framework.so.%{version} libboost_unit_test_framework.so.%{maj_version}
ln -sf %{_target}/libboost_unit_test_framework.so.%{version} libboost_unit_test_framework.so
ln -sf %{_target}/libboost_wave.so.%{version} libboost_wave.so.%{maj_version}
ln -sf %{_target}/libboost_wave.so.%{version} libboost_wave.so
ln -sf %{_target}/libboost_wserialization.so.%{version} libboost_wserialization.so.%{maj_version}
ln -sf %{_target}/libboost_wserialization.so.%{version} libboost_wserialization.so
echo "Done"


%preun


%postun
echo "Removing symbolic links"
rm -f /usr/lib64/libboost_date_time.so
rm -f /usr/lib64/libboost_date_time.so.%{maj_version}
rm -f /usr/lib64/libboost_filesystem.so
rm -f /usr/lib64/libboost_filesystem.so.%{maj_version}
rm -f /usr/lib64/libboost_graph.so
rm -f /usr/lib64/libboost_graph.so.%{maj_version}
rm -f /usr/lib64/libboost_iostreams.so
rm -f /usr/lib64/libboost_iostreams.so.%{maj_version}
rm -f /usr/lib64/libboost_math_c99.so
rm -f /usr/lib64/libboost_math_c99.so.%{maj_version}
rm -f /usr/lib64/libboost_math_c99f.so
rm -f /usr/lib64/libboost_math_c99f.so.%{maj_version}
rm -f /usr/lib64/libboost_math_c99l.so
rm -f /usr/lib64/libboost_math_c99l.so.%{maj_version}
rm -f /usr/lib64/libboost_math_tr1.so
rm -f /usr/lib64/libboost_math_tr1.so.%{maj_version}
rm -f /usr/lib64/libboost_math_tr1f.so
rm -f /usr/lib64/libboost_math_tr1f.so.%{maj_version}
rm -f /usr/lib64/libboost_math_tr1l.so
rm -f /usr/lib64/libboost_math_tr1l.so.%{maj_version}
rm -f /usr/lib64/libboost_prg_exec_monitor.so
rm -f /usr/lib64/libboost_prg_exec_monitor.so.%{maj_version}
rm -f /usr/lib64/libboost_program_options.so
rm -f /usr/lib64/libboost_program_options.so.%{maj_version}
rm -f /usr/lib64/libboost_python.so
rm -f /usr/lib64/libboost_python.so.%{maj_version}
rm -f /usr/lib64/libboost_random.so
rm -f /usr/lib64/libboost_random.so.%{maj_version}
rm -f /usr/lib64/libboost_regex.so
rm -f /usr/lib64/libboost_regex.so.%{maj_version}
rm -f /usr/lib64/libboost_serialization.so
rm -f /usr/lib64/libboost_serialization.so.%{maj_version}
rm -f /usr/lib64/libboost_signals.so
rm -f /usr/lib64/libboost_signals.so.%{maj_version}
rm -f /usr/lib64/libboost_system.so
rm -f /usr/lib64/libboost_system.so.%{maj_version}
rm -f /usr/lib64/libboost_thread.so
rm -f /usr/lib64/libboost_thread.so.%{maj_version}
rm -f /usr/lib64/libboost_unit_test_framework.so
rm -f /usr/lib64/libboost_unit_test_framework.so.%{maj_version}
rm -f /usr/lib64/libboost_wave.so
rm -f /usr/lib64/libboost_wave.so.%{maj_version}
rm -f /usr/lib64/libboost_wserialization.so
rm -f /usr/lib64/libboost_wserialization.so.%{maj_version}
echo "Done"


%files
%defattr(-,root,root)
/opt/ap/apos/lib64/libboost_date_time.so.%{version}
/opt/ap/apos/lib64/libboost_filesystem.so.%{version}
/opt/ap/apos/lib64/libboost_graph.so.%{version}
/opt/ap/apos/lib64/libboost_iostreams.so.%{version}
/opt/ap/apos/lib64/libboost_math_c99.so.%{version}
/opt/ap/apos/lib64/libboost_math_c99f.so.%{version}
/opt/ap/apos/lib64/libboost_math_c99l.so.%{version}
/opt/ap/apos/lib64/libboost_math_tr1.so.%{version}
/opt/ap/apos/lib64/libboost_math_tr1f.so.%{version}
/opt/ap/apos/lib64/libboost_math_tr1l.so.%{version}
/opt/ap/apos/lib64/libboost_prg_exec_monitor.so.%{version}
/opt/ap/apos/lib64/libboost_program_options.so.%{version}
/opt/ap/apos/lib64/libboost_python.so.%{version}
/opt/ap/apos/lib64/libboost_random.so.%{version}
/opt/ap/apos/lib64/libboost_regex.so.%{version}
/opt/ap/apos/lib64/libboost_serialization.so.%{version}
/opt/ap/apos/lib64/libboost_signals.so.%{version}
/opt/ap/apos/lib64/libboost_system.so.%{version}
/opt/ap/apos/lib64/libboost_thread.so.%{version}
/opt/ap/apos/lib64/libboost_unit_test_framework.so.%{version}
/opt/ap/apos/lib64/libboost_wave.so.%{version}
/opt/ap/apos/lib64/libboost_wserialization.so.%{version}


%changelog
* Thu Jan 19 2012 - paolo.palmieri (at) ericsson.com
- Changed version to 1.44.0-0.5 to track build with new LOTC and DX starting from APOS R1A14.
* Tue Oct 18 2011 - paolo.palmieri (at) ericsson.com
- Added the new boost iostreams lib and changed version to 1.44.0-0.4.
* Tue Feb 08 2011 - paolo.palmieri (at) ericsson.com
- Added all boost related libs and changed version to 1.44.0-0.3.
* Mon Jan 24 2011 - paolo.palmieri (at) ericsson.com
- Moved to /opt/ap/apos/lib64/ and changed version to 1.44.0-0.2.
* Fri Jan 21 2011 - francesco.rainone (at) ericsson.com
- Initial implementation of release 0.1
