 ###########################################################################
# This is a Tcl Package Script

 ###########################################################################
# Copyright 2010 Ericsson AB
# All rights reserved.

 ###########################################################################
# :DocNo        n/nnn nn-abc nnn nnn Uen
# :DocType      Tcl Package Script
# :Prepared     teimgal
# :Approved     
# :Date         2012-07-06
# :SubSys       APG
# :Subject      SSH
# :OS           All
# :APZ          No
# :APG          Yes

 ###########################################################################
# :Revision Information
# ---------------------
#   When            By         				   Description
#2012-07-06    Massimo Galdi			Procedures file creation 

 ###########################################################################
# :Package Specification
# ----------------------
# This script provides procedures for SSH.
#
#


package provide PRC 1.0

proc check_revision {src} {
#REVISION parameter definited info ATH .config
set rev $SUT::REVISION
#ath_display "Config Revision : $rev"
sleep 3

#splitting revision informations cr = config reviosion
set fr1 [lrange [split $rev "."] 0 0] 
set fr2 [lrange [split $rev "."] 1 1] 
set fr3 [lrange [split $rev "."] 2 2] 

#ath_display "File Revision : $src"
#splitting file revision fr = file revision
set cr1 [lrange [split $src "."] 0 0] 
set cr2 [lrange [split $src "."] 1 1] 
set cr3 [lrange [split $src "."] 2 2] 

#matching revisions
if { $cr1 == $fr1 && $cr2 == $fr2 && $cr3 == $fr3  } {
	ath_display "SAME Revision!!!"
	sleep 2
} elseif { $cr1 > $fr1 && $cr2 > $fr2 && $cr3 > $fr3 } {
	ath_display "NEW Revision!!!"
} else {
	ath_tc_failed "OLD Revision!!!"
}
}

 #############################################################################################
#Get prc state of node
#--------------------------------------------------------------------------------------------
proc get_prcstate {} {

  global spawn_id
  set ATH::ReturnCode 0
  set org_autofail $ATH::AutoFail
  set org_spawnid $spawn_id

  ath_send_p "Password:" "su"
  ath_send "Administrator1@"
  ath_send "prcstate"
  set output $ATH::LastResponse
 
  regsub -linestop {^.*\n} $output {} output
  regsub -linestop {.*[\n]?$} $output {} output

  set p [expr [string first "\n" $output] - 1]
  set prcstate [string trim [string range $output 0 $p]]
    
  ath_display "INTO FUNCTION: $prcstate"
 
  # close $spawn_id
  set spawn_id $org_spawnid
  set ATH::LastResponse $prcstate
}

proc invalid_usage {} {

set pattern ":
:
Usage* ispprint* *a *l*n*s*r *d*g*t starttime*x endtime*
       ispprint* *c *g*
       ispprint* *h
:"
return $pattern

}

proc start_ISPservice {} {

#-------------------------------------------------------------------------------------------
ath_display "Starting ISP_Service"
#-------------------------------------------------------------------------------------------
ath_connect_ssh -P 4422 $SUT::APG1
ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
ath_send "cd /opt/ap/acs/bin"
ath_send "export LD_LIBRARY_PATH=../lib64"
ath_send "./prcispd &"
sleep 2

}
proc ath_check_required_parameters {} {

ath_check_parameter "SUT::APG1" "Enter APG43 ON LINUX name or IP-address: "
ath_check_parameter "SUT::APG1_USER" "Enter username: "
ath_check_parameter "SUT::APG1_PW" "Enter password: "
ath_check_parameter "SUT::APG1B_USER" "Enter username: "
ath_check_parameter "SUT::APG1B_PW" "Enter password: "
ath_check_parameter "SUT::REVISION" "Revision: "

}
proc connect_to_active_node {} { 

#-------------------------------------------------------------------------------------------
ath_display "Connect SSH"
#-------------------------------------------------------------------------------------------

global activenode

ath_connect_ssh -P 4422 $SUT::APG1A
ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
get_prcstate
set state $ATH::LastResponse

set pass "passive"
set activenode $SUT::APG1A

if {$state == $pass} {
                      ath_connect_ssh -P 4422 $SUT::APG1B
					  ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
					  ath_send_p "Password:" "su"
                      ath_send "Administrator1@"
					  set activenode $SUT::APG1B}
}

proc connect_to_active_node_as_cpadmin {} { 

#-------------------------------------------------------------------------------------------
ath_display "Connect SSH"
#-------------------------------------------------------------------------------------------

global activenode

ath_connect_ssh -P 4422 $SUT::APG1A
ath_login_ssh "cpadmin" "cpadmin"

get_prcstate
set state $ATH::LastResponse
ath_display $state
set pass "passive"
set activenode $SUT::APG1A

if {$state == $pass} {
                      ath_connect_ssh -P 4422 $SUT::APG1B
					  ath_login_ssh "cpadmin" "cpadmin"
					  set activenode $SUT::APG1B}
					  
}

proc connect_to_active_node_on_COM_CLI {} { 

#-------------------------------------------------------------------------------------------
ath_display "Connect SSH"
#-------------------------------------------------------------------------------------------
ath_connect_ssh -P 4422 $SUT::APG1A
ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW

get_prcstate
set state $ATH::LastResponse
ath_display $state
set pass "passive"

ath_connect_ssh -P 22 $SUT::APG1A
ath_login_ssh $SUT::COMCLI_USER $SUT::COMCLI_PW

set active $SUT::APG1A

if {$state == $pass} {
                      ath_connect_ssh -P 22 $SUT::APG1B
                      ath_login_ssh $SUT::COMCLI_USER $SUT::COMCLI_PW
					  set active $SUT::APG1B}
					  
					  
					  
}

proc connect_to_sftp {} { 

#-------------------------------------------------------------------------------------------
ath_display "Connect sftp"
#-------------------------------------------------------------------------------------------

ath_connect_ssh -P 4422 $SUT::APG1A
ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW

get_prcstate
set state $ATH::LastResponse
ath_display $state
set pass "passive"



if {$state == $pass} {
                      ath_connect_sftp $SUT::APG1B
                      ath_login_sftp $SUT::COMCLI_USER $SUT::COMCLI_PW} else {
					  ath_connect_sftp $SUT::APG1A
                      ath_login_sftp $SUT::COMCLI_USER $SUT::COMCLI_PW
					  }
}					  
					  

# :proc Public
###########################################################################
proc ath_connect_sftp_max args {
#######################################################################
# :Description
# ...
#
# :Arguments
# ...
#
# :Input
# -
#
# :Output
# -
#
# :Example
# ...
#
# :Returns
# -
#
# :Code
#######################################################################
   #if {$ATH::DEBUG} {CheckForUnhandledPrompts}
   if {![info exists SSH::App]} {package require SSH}
   set ATH::ReturnCode 0
   global spawn_id

   if {$::tcl_platform(platform) == "windows"} {
       ath_display "windows"
#       append cmd "exp_spawn \"" $SSH::sftp "\" " $args
        append cmd "sftp cpadmin@141.137.32.197"
       print "\n$cmd\n"
       eval $cmd
   } else {
       # Save the host name for the ath_login_sftp procedure
      if {[regexp {^-} [lindex $args 0]]} {
         set SSH::host [lindex $args end]
         set SSH::args [lrange $args 0 end-1]
      } else {
         # If the first argument is not an sftp option, it must be the hostname
         #  (This is crude but might be good enough)
         set SSH::host [lindex $args 0]
         set SSH::args [lrange $args 1 end]
      }
      #regsub -- {-P} $SSH::args "-p" SSH::args
   }

   return $ATH::ReturnCode
}



					  
					  




					  
proc connect_to_passive_node {} { 

#-------------------------------------------------------------------------------------------
ath_display "Connect SSH"
#-------------------------------------------------------------------------------------------
ath_connect_ssh -P 4422 $SUT::APG1B
ath_login_ssh $SUT::APG1B_USER $SUT::APG1B_PW

get_prcstate
set state $ATH::LastResponse
ath_display $state
set active "active"

if {$state == $active} {
                      ath_connect_ssh -P 4422 $SUT::APG1A
                      ath_login_ssh $SUT::APG1A_USER $SUT::APG1A_PW}
}
proc preparation_cmd {} {
#-------------------------------------------------------------------------------------------
ath_display "PREPARATION"
#-------------------------------------------------------------------------------------------

#ath_send "export LD_LIBRARY_PATH=/opt/ap/acs/lib64/"
#ath_send "cd /opt/ap/acs/bin"
ath_display "READY TO START"
}

  proc clean_process {} {
  ath_connect_ssh -P 4422 $SUT::APG1A
	ath_login_ssh $SUT::APG1A_USER $SUT::APG1A_PW
	ath_send "pkill -9 prcispd"
   }

 ############################################################################
#heading Local time
#ISP log analysis from 2010-10-14 11:50:54 to 2010-12-14 10:36:03 (Local time) 

proc heading {} {
set heading ":
ISP log analysis from * * to * * \(Local Time\)
:"
return $heading
}
 ############################################################################

  ############################################################################
#heading -t Local time
#ISP log analysis from 2010-12-01 23:59:00 to 2011-01-15 09:29:03 (Local time) 

# -t 101201-2359 
proc headingt {} {
set headingt ":
ISP log analysis from 2010-12-01 * to * * \(Local time\)
:"
return $headingt
}
 ############################################################################
 
   ############################################################################
#heading -x Local time
#ISP log analysis from 2010-12-01 23:59:00 to 2011-01-15 09:29:03 (Local time) 

# -x 101221-1010 
proc headingx {} {
set headingx ":
ISP log analysis from * * to 2010-12-21 * \(Local time\)
:"
return $headingx
}
 ############################################################################
 
 
  ############################################################################
#heading -t -x Local time
#ISP log analysis from 2010-12-01 23:59:00 to 2011-01-15 09:29:03 (Local time) 

# -t 101201-2359  -x 101221-1010
proc headingtx {} {
set headingtx ":
ISP log analysis from * * to * * **
:"
return $headingtx
}
 ############################################################################
#\(Local time\)
 ############################################################################
#heading UTC
#ISP log analysis from 2010-12-07 15:21:29 to 2010-12-15 09:29:03 (UTC) 

proc headingutc {} {
set headingutc ":
ISP log analysis from * * to * * \(UTC\)*
:"
return $headingutc
}
 ############################################################################
 
  ############################################################################
#heading -t UTC
#ISP log analysis from 2010-12-25 23:59:00 to 2011-01-15 09:29:03 (UTC) 

# -t 101201-2359  

proc headingutct {} {
set headingutct ":
ISP log analysis from * * to * * \(UTC\)*
:"
return $headingutct
}
 ############################################################################
 
    ############################################################################
#heading -x UTC
#ISP log analysis from 2010-12-01 23:59:00 to 2011-01-15 09:29:03 (Local time) 

# -x 101221-1010 

proc headingutcx {} {
set headingutcx ":
ISP log analysis from * * to * * \(UTC\)*
:"
return $headingutcx
}
 ############################################################################
 
  ############################################################################
#heading -t -x UTC
#ISP log analysis from 2010-12-25 23:59:00 to 2011-01-15 09:29:03 (UTC) 

# -t 101201-2359  -x 101221-1010  

proc headingutctx {} {
set headingutctx ":
ISP log analysis from 2010-12-01 * to 2010-12-21 * \(UTC\)*
:"
return $headingutctx
}
 ############################################################################

 
 
 
 
 
 ############################################################################
#                              ispprint -a
#
#
#AP State
#
#           State                                               Time
 #-------------------------------------------------------------------
#total time                                               1462:45:08 
#           down                                             2:30:53
#           degraded (non redundant)                         8:36:31
#           degraded (redundant)                            26:37:08
#           up (non redundant)                             392:34:35
#           up (redundant)                                 349:49:30
#           unknown                                        682:36:29

proc ispprinta {} {
set ispprinta ":
AP State

           State                                               Time
**
total time **
:"
return $ispprinta
}


#**
#           State                                               Time
#          
#:
#total time**  
 ############################################################################


 ############################################################################
#                           ispprint -a -r
#
#
#AP State
#
#           State   Reason                                      Time
 #-------------------------------------------------------------------
#total time                                               1463:51:33
#           down                                             2:30:53
#                   ordered                                  0:10:05
#                   spontaneous                              2:20:48
#           degraded (non redundant)                         8:36:31
#                   ordered                                  5:56:38
#                   spontaneous                              2:39:52
#           degraded (redundant)                            26:37:08
#                   ordered                                 10:59:32
#                   spontaneous                             15:37:36
#           up (non redundant)                             392:34:35
#                   ordered                                  5:32:10
#                   spontaneous                            387:02:24
#           up (redundant)                                 350:55:54
#           unknown                                        682:36:29
#                   ordered                                  7:19:46
#                   spontaneous                            675:16:42           
#
#
proc ispprintar {} {
set ispprintar ":

AP State

           State   Reason                                      Time
**
total time **
:"   
return $ispprintar
}     
 ############################################################################



 ############################################################################
#                       ispprint -a -r -d
#
#
#AP State
#
#           State   Reason   Details                            Time
 #-------------------------------------------------------------------
#total time                                               1464:28:46
#           down                                             2:30:53
#                   ordered                                  0:10:05
#                            function change (FCH)           0:02:18
#                            manually reboot                 0:07:46
#                   spontaneous                              2:20:48
#                            failover                        0:00:37
#                            unknown                         2:20:10
#           degraded (non redundant)                         8:36:31
#                   ordered                                  5:56:38
#                            function change (FCH)           2:58:53
#                            manually reboot                 2:57:45
#                   spontaneous                              2:39:52
#                            failover                        2:03:51
#                            fault                           0:17:00
#                            PRC_Eva                         0:00:05
#                            PRC: Resource failed            0:00:00
#                            unknown                         0:18:55
#           degraded (redundant)                            26:37:08
#                   ordered                                 10:59:32
#                            function change (FCH)           0:20:47
#                            soft function change (SFC)      0:00:41
#                            manually reboot                10:38:04
#                   spontaneous                             15:37:36
#                            failover                        0:03:27
#                            fault                           0:41:03
#                            PRC_Eva                         0:00:00
#                            unknown                        14:53:05
#           up (non redundant)                             392:34:35
#                   ordered                                  5:32:10
#                            function change (FCH)           0:24:07
#                            manually reboot                 5:06:31
#                            Manual shut down                0:01:31
#                   spontaneous                            387:02:24
#                            failover                        0:34:22
#                            PRC_Eva                         0:02:01
#                            PRC: Resource failed            0:02:19
#                            unknown                       386:23:40
#           up (redundant)                                 351:33:08
#           unknown                                        682:36:29
#                   ordered                                  7:19:46
#                            function change (FCH)           1:04:48
#                            soft function change (SFC)      0:01:30
#                            manually reboot                 6:09:58
#                            Manual shut down                0:03:30
#                   spontaneous                            675:16:42
#                            failover                        0:00:03
#                            fault                          17:33:23
#                            PRC_Eva                         0:00:00
#                            PRC: Resource failed            0:03:09
#                            unknown                       657:40:06   


proc ispprintard {} {
set ispprintard ":

AP State

           State   Reason  Details                                      Time
**
total time **                           
:"              
return $ispprintard
}     

 ############################################################################
   
    

 #############################################################################           
#                   ispprint -a -l (solo la printout -l)
#
#Run Level
#
#Node       Level                                               Time
 #-------------------------------------------------------------------
#A                                                        1463:09:19
#           0                                             1072:12:58
#           1                                                4:48:25
#           2                                                0:20:41
#           3                                                0:17:36
#           4                                               27:27:06
#           5                                              358:02:31
#
#B                                                        1463:09:19
#           0                                                2:51:32
#           1                                               28:38:14
#           2                                                0:30:32
#           3                                                0:44:19
#           4                                               10:55:58
#           5                                             1419:28:42 
    
proc ispprintl {} {
set ispprintl ":
Run Level

Node       Level                                                         Time
:"
return $ispprintl
}     
 #############################################################################    




 
 #############################################################################    
#                   ispprint -a -l -r (solo la printout -l)
# 
#Run Level
#
#Node       Level   Reason                                      Time
 #-------------------------------------------------------------------
#A                                                        1464:44:18
#           0                                             1072:12:59
#                   ordered                                679:47:28
#                   spontaneous                            392:25:31
#           1                                                4:48:24
#                   ordered                                  2:26:49
#                   spontaneous                              2:21:35
#           2                                                0:20:41
#                   ordered                                  0:20:07
#                   spontaneous                              0:00:33
#           3                                                0:17:36
#                   ordered                                  0:01:06
#                   spontaneous                              0:16:30
#           4                                               27:27:06
#                   ordered                                 26:01:31
#                   spontaneous                              1:25:35
#           5                                              359:37:29
#
#B                                                        1464:44:18
#           0                                                2:51:32
#                   ordered                                  1:44:22
#                   spontaneous                              1:07:10
#           1                                               28:38:14
#                   ordered                                  7:55:06
#                   spontaneous                             20:43:08
#           2                                                0:30:32
#                   ordered                                  0:28:39
#                   spontaneous                              0:01:53
#           3                                                0:44:19
#                   ordered                                  0:00:40
#                   spontaneous                              0:43:39
#           4                                               10:55:58
#                   ordered                                  8:54:09
#                   spontaneous                              2:01:48
#           5                                             1421:03:40                                  

proc ispprintlr {} {
set ispprintlr ":  
Run Level

Node        Level    Reason                                       Time
:"
return $ispprintlr
}     
 ##############################################################################    

 ##############################################################################    
#                   ispprint -a -l -r -d (solo la printout -l)
#Run Level
#
#Node       Level   Reason   Details                            Time
 #-------------------------------------------------------------------
#A                                                         166:49:27
#           0                                                0:23:43
#                   ordered                                  0:18:00
#                            function change (FCH)           0:02:54
#                            manually reboot                 0:15:05
#                   spontaneous                              0:05:43
#                            unknown                         0:05:43
#           1                                                1:29:05
#                   ordered                                  0:23:15
#                            function change (FCH)           0:03:19
#                            manually reboot                 0:19:12
#                            Manual shut down                0:00:43
#                   spontaneous                              1:05:49
#                            unknown                         1:05:49
#           2                                                0:04:14
#                   ordered                                  0:03:52
#                            function change (FCH)           0:00:13
#                            manually reboot                 0:03:37
#                            Manual shut down                0:00:02
#                   spontaneous                              0:00:22
#                            unknown                         0:00:22
#           3                                                0:01:19
#                   ordered                                  0:00:00
#                            manually reboot                 0:00:00
#                   spontaneous                              0:01:19
#                            failover                        0:01:18
#                            unknown                         0:00:01
#           4                                               24:14:14
#                   ordered                                 24:08:05
#                            function change (FCH)           0:00:24
#                            soft function change (SFC)      0:00:41
#                            manually reboot                24:06:58
#                   spontaneous                              0:06:09
#                            failover                        0:03:45
#                            unknown                         0:02:23
#           5                                              140:36:49
#
#B                                                         166:49:27
#           0                                                1:20:32
#                   ordered                                  0:13:22
#                            function change (FCH)           0:02:06
#                            manually reboot                 0:11:15
#                   spontaneous                              1:07:10
#                            failover                        1:07:10
#           1                                                1:14:29
#                   ordered                                  1:03:58
#                            function change (FCH)           0:05:14
#                            manually reboot                 0:57:59
#                            Manual shut down                0:00:43
#                   spontaneous                              0:10:31
#                            PRC: Resource failed            0:05:17
#                            unknown                         0:05:13
#           2                                                0:02:50
#                   ordered                                  0:02:15
#                            function change (FCH)           0:00:27
#                            manually reboot                 0:01:46
#                            Manual shut down                0:00:02
#                   spontaneous                              0:00:35
#                            PRC: Resource failed            0:00:13
#                            unknown                         0:00:21
#           3                                                0:01:52
#                   ordered                                  0:00:00
#                            function change (FCH)           0:00:00
#                   spontaneous                              0:01:51
#                            failover                        0:01:32
#                            fault                           0:00:19
#                            unknown                         0:00:00
#           4                                                0:23:41
#                   ordered                                  0:07:41
#                            function change (FCH)           0:01:40
#                            manually reboot                 0:06:01
#                   spontaneous                              0:16:00
#                            failover                        0:05:17
#                            fault                           0:05:20
#                            unknown                         0:05:21
#           5                                              163:46:01
#
#                                                                        
proc ispprintlrd {} { 
set ispprintlrd ":
                                         
Run Level

Node       Level   Reason  Details                                      Time
:"
return $ispprintlrd
}                                                                       
 ###############################################################################

 ##############################################################################    
#                   ispprint -a -n (solo la printout -n)
#
#Node State
#
#Node       State                                               Time
 #-------------------------------------------------------------------
#A                                                         166:59:34
#           active                                          72:39:56
#           passive                                         93:48:01
#           unknown                                          0:31:36
#
#B                                                         166:59:34
#           active                                          94:16:30
#           passive                                         49:28:28
#           unknown                                         23:14:34

proc ispprintn {} { 
set ispprintn ":
:
Node State

Node       State                                                         Time
:"
return $ispprintn
}        
 ###############################################################################

 ##############################################################################    
#                   ispprint -a -n -r (solo la printout -n)
#Node State
#
#Node       State   Reason                                      Time
 #-------------------------------------------------------------------
#A                                                         167:04:46
#           active                                          72:40:45
#           passive                                         93:48:16
#           unknown                                          0:35:45
#                   ordered                                  0:29:23
#                   spontaneous                              0:06:21
#
#B                                                         167:04:46
#           active                                          94:20:53
#           passive                                         49:29:18
#           unknown                                         23:14:34
#                   ordered                                  1:06:32
#                   spontaneous                             22:08:01
#

proc ispprintnr {} { 
set ispprintnr ":
:
Node State

Node       State   Reason                                                Time
:"    
return $ispprintnr
}                         
 ##############################################################################   


 ##############################################################################    
#                ispprint -a -n -r -d (solo la printout -n)
#
#Node State
#
#Node       State   Reason   Details                            Time
 #-------------------------------------------------------------------
#A                                                         167:08:28
#           active                                          72:40:45
#           passive                                         93:51:58
#           unknown                                          0:35:45
#                   ordered                                  0:29:23
#                            function change (FCH)           0:03:29
#                            manually reboot                 0:25:53
#                   spontaneous                              0:06:21
#                            unknown                         0:06:21
#
#B                                                         167:08:28
#           active                                          94:24:35
#           passive                                         49:29:18
#           unknown                                         23:14:34
#                   ordered                                  1:06:32
#                            function change (FCH)           0:02:40
#                            manually reboot                 1:03:52
#                   spontaneous                             22:08:01
#                            failover                       22:04:14
#                            PRC: Resource failed            0:03:11
#                            unknown                         0:00:35


proc ispprintnrd {} { 
set ispprintnrd ":
:
Node State

Node       State   Reason  Details                                      Time
:"     
return $ispprintnrd
}           
 ###############################################################################    

 ##############################################################################    
#                ispprint -a -s (solo la printout -s)
#
#
#Service State node A
#
#Service    State                                               Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        167:26:25
#           running                                        166:31:38
#           stopped                                          0:54:46
#
#AES_TELNET_server                                         167:26:25
#           running                                        166:31:38
#           stopped                                          0:54:46
#
#FTP Publishing Service                                    167:26:25
#           running                                        166:31:38
#           stopped                                          0:54:46
#
#File Server Resource Manager                              167:26:25
#           running                                        166:31:38
#           stopped                                          0:54:46
#
#
#
#Service State node B
#
#Service    State                                               Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        167:26:25
#           running                                        143:52:04
#           stopped                                         23:34:20
#
#AES_TELNET_server                                         167:26:25
#           running                                        143:52:04
#           stopped                                         23:34:20
#
#FTP Publishing Service                                    167:26:25
#           running                                        143:52:04
#           stopped                                         23:34:20
#
#File Server Resource Manager                              167:26:25
#           running                                        143:52:04
#           stopped                                         23:34:20
#
#
#
#
#Resource State
#
#Resource   State                                               Time
 #-------------------------------------------------------------------
#ACS_ACSC_Logmaint_0                                       167:26:25
#           running                                        166:24:49
#           stopped                                          1:01:35
#
#ACS_ACSC_Logmaint_1                                       167:26:25
#           running                                        143:49:55
#           stopped                                         23:36:29
#
#ACS_ALH_Exec_0                                            167:26:25
#           running                                        166:22:08
#           stopped                                          1:04:16
#
#ACS_ALH_Exec_1                                            167:26:25
#           running                                        143:48:00
#           stopped                                         23:38:25
#
#Disks K:                                                  167:26:25
#           running                                        167:09:34
#           stopped                                          0:16:5
#
#Images                                                    167:26:25
#           running                                        167:11:39
#           stopped                                          0:14:45
#
#
#MCS_AIAP_ADM                                              167:26:25
#           running                                        142:54:51
#           stopped                                         24:28:09
#           failed                                           0:03:24
#
#
#SPOE_IP_BACKUP                                            167:26:25
#           running                                        167:19:06
#           stopped                                          0:00:56
#           failed                                           0:06:21
#
#
  

proc ispprints {} {   
set ispprints ":
Service State node **

Service    State                                                         Time
:"                                
return $ispprints
}        
 ###############################################################################





 ##############################################################################    
#                ispprint -a -s -r (solo la printout -s)
#
#
#Service State node A                                               
#                                                                   
#Service    State   Reason                                      Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        168:50:05
#           running                                        167:55:19
#           stopped                                          0:54:46
#                   ordered                                  0:45:10
#                   spontaneous                              0:09:35
#                                                                   
#                                                                   
#Service State node B                                               
#                                                                   
#Service    State   Reason                                      Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        168:50:05
#           running                                        145:10:45
#           stopped                                         23:39:20
#                   ordered                                  1:28:22
#                   spontaneous                             22:10:57
#                                                                   
# Resource State                                                     
#                                                                   
# Resource   State   Reason                                      Time
 # -------------------------------------------------------------------
# ACS_ACSC_Logmaint_0                                       168:50:05
#            running                                        167:48:30
#            stopped                                          1:01:35
#                    ordered                                  0:53:35
#                    spontaneous                              0:07:59

proc ispprintsr {} {  
set ispprintsr ":
:
Service State node SC-2-1

Service    State   Reason                                                Time**
:" 
return $ispprintsr
}                                                                        
 ##############################################################################                                                                     

 
 ###############################################################################                                                                     
#                ispprint -a -s -r -d (solo la printout -s)
#
#Service State node A
#
#Service    State   Reason   Details                            Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        169:01:56
#           running                                        168:01:57
#           stopped                                          0:59:59
#                   ordered                                  0:50:24
#                            function change (FCH)           0:04:56
#                            manually reboot                 0:45:27
#                   spontaneous                              0:09:35
#                            unknown                         0:09:35
#
#
#
#Service State node B
#
#Service    State   Reason   Details                            Time
 #-------------------------------------------------------------------
#ACS_PRC_IspService                                        169:01:56
#           running                                        145:22:36
#           stopped                                         23:39:20
#                   ordered                                  1:28:22
#                            function change (FCH)           0:04:08
#                            manually reboot                 1:24:14
#                   spontaneous                             22:10:57
#                            failover                       22:07:09
#                            PRC: Resource failed            0:03:11
#                            unknown                         0:00:35
#
#
#
#Resource State
#
#Resource   State   Reason   Details                            Time
 #-------------------------------------------------------------------
#ACS_ACSC_Logmaint_0                                       169:01:56
#           running                                        167:54:59
#           stopped                                          1:06:57
#                   ordered                                  0:58:57
#                            function change (FCH)           0:06:18
#                            manually reboot                 0:52:38
#                   spontaneous                              0:07:59
#                            unknown                         0:07:59
#                                                                       
 
proc ispprintsrd {} {  
set ispprintsrd ":
Service State node **

Service    State   Reason  Details                                      Time
:"
return $ispprintsrd
}                                                                                  
 ##############################################################################
 
 
 ###############################################################################                                                                     
#
proc usage {} {  
set usage ":: 
Usage* ispprint -a \[-l\]\[-n\]\[-s\]\[-r \[-d\]\]\[-g\]\[-t starttime\]\[-x endtime\]
       ispprint -c \[-g\]
       ispprint \[-z\] \[-m \[-g\]\[-t starttime\]\[-x endtime\]\]
       ispprint -h
	   
:" 
return $usage
}   
# 
 ###############################################################################                                                                     


 ###############################################################################                                                                     
#
proc invalidoption {} {  
 set invalidoption ": 
 * invalid option ** 
:" 
return $invalidoption
}    
# 
 ###############################################################################                                                                     
 

 
