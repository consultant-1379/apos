#!/bin/csh
#\
exec ath $0

# The line(s) above enable this script to be executed from a file manager
# on Unix. They must end with LF (not by CRLF).

###########################################################################
# This is a Tcl/Expect test case script.
###########################################################################
# Copyright 2007 Ericsson AB
# All rights reserved.

###########################################################################
# :Title        SFTP sessions
# -------------------------------------------------------------------------
# :TestAct      ST
# :SubSys       ACS
# :TestObj      Characteristics Verifications
# :Prepared     HIL/XBR/BCS Mike Claussen
# :Approved     EAB/FTE/RX (Tomas Borg)
# :Date         2007-04-01
# :Req          105 65-0383/00533
# :Ref          Char TS 62/152 41-APZ 212 55/1 Uen PA4, TC 4
# :TCLTCS       -
# :TCLTCI       -
# :RegTest      -
# :Scope        Requirement Based
# :OS           WinNT, Win2003
# :APZ          No
# :NrOfAPGs     1
# :NrOfBCs      0


###########################################################################
# :Revision Information
# ---------------------
# Ver   Rev     When    By       Description
# 1     PA1     080401  xbrmicl  First draft based on sftp script
#       PA2     080704  eirfjun  Added support for unix, moved code up and
#                                down and added comments
#       PA3     101028  teipgia  Converted to ATH 2.0 Added REQ number
#                                Requirement modified to 50 + 10 sessions
###########################################################################
# :Test Case Specification
# ------------------------
# The objective of this test case is to perform measurements to see if it is possible
# to open 50 (former 70) SSH sessions and 10 (former 30) sftp sessions in parallel at the same time.
#
# 1. Verify that 50 (former 70) parallel SSH sessions can be established.
#
# 2. Open 10 (former 30) SFTP sessions as possible.
#
# 3. Measure the average AP CPU load for 10 minutes period.
#
# 3. Present the result as:
#    - Requirement compliance statement (test case failed if non-compliance).
#    - Average CPU and memory consumtion for 100 open sessions.

###########################################################################
# Sourcing ATH framework
###########################################################################
 package require ATH

#**************************************************************************
# :Preparations
#**************************************************************************
ath_display "Preparations"

#--------------------------------------------------------------------------
# Configurable parameters
#--------------------------------------------------------------------------
print "Declaring configurable parameters...\n"
#set TestCase "70 ssh and 30 sftp sessions"
set TestCase "50 ssh and 10 sftp sessions"
set sshsessions 255;     # The number of ssh sessions sessions to use.
set sftpsessions 10;     # The number of sftp sessions sessions to use.

#--------------------------------------------------------------------------
# Global variables
#--------------------------------------------------------------------------
print "Declaring global variables...\n"
set nsshsessions 0;        # The number of sessions actually used.
set nsftpsessions 0;        # The number of sessions actually used.
set remarks ""
set tc_completed 0
set sftp_session_spawn_id {}

set SSHSession() 0


#--------------------------------------------------------------------------
# Procedures
#--------------------------------------------------------------------------
print "Declaring procedures...\n\n"

# -----------------------------------------------------------------------------
# Waits for X minutes and prints the progress every minute
# -----------------------------------------------------------------------------
proc WaitMinutes {wait_minutes} {
#     This procedure is used for making script to sleep. Used when some events
#     are to be triggered, traffic to be increased etc
    set ONE_MINUTE [expr 1000 * 60]
    set waited_minutes 0
    while {$waited_minutes < $wait_minutes} {
        send_user "Waiting... $waited_minutes ($wait_minutes) minutes\n"
        after $ONE_MINUTE
        set waited_minutes [expr $waited_minutes + 1]
    }
}

proc Round {value decimals} {
    # This procedure takes a value with "." as decimal separator
    # and returns the value with the specified number of decimals.
    set p [string first "." $value]
    if {$p >= 0} {
        if {$decimals == 0} {set pos2 [expr $p - 1]
        } else {set pos2 [expr $p + $decimals]}
        set v [string range $value 0 $pos2]
    } else {set v $value}
    return $v
}

proc connect_sftp_session args {
    # This procedure is called to handle SFTP session connections
    global nsftpsessions
    global spawn_id
    global general_session
    global sftp_session_spawn_id
    global attempted_connections
    print "\n\nConnecting sftp session #[expr $nsftpsessions + 1]\n"
    AutoFail OFF
    ath_connect_sftp $SUT::APG1
    print "spawn_id: \"$spawn_id\"\n"
    ath_login_sftp $SUT::APG1_USER $SUT::APG1_PW
    if {$ATH::ReturnCode == 0} {
        incr nsftpsessions
        lappend sftp_session_spawn_id $spawn_id;    # Save session id:s
    } else {
        if {$ATH::ReturnCode != 0} {
            print "SFTP session connection failed\n"
            ath_tc_failed "Failed to open SFTP session # $nsftpsessions"
        }

    }
    incr attempted_connections
    AutoFail ON
}

#**************************************************************************
# :Execution
#**************************************************************************
ath_display "Execution"
AutoFail ON

# ACTION: Executing PreCheck if not already executed
#    ath_display "Executing PreCheck if not already executed"

#    if {!$PP::PrePostCheck} {
#        set PP::PrePostCheck 1
#        ath_use "PP_PrePostCheck_1_A.tcl"
#        set PP::Verbose 1
#        set PP::cmdlist {}
#        lappend PP::cmdlist "mml allip" 0 0 "-" none
#        PP::PreCheck
#    }

#--------------------------------------------------------------------------
print "General Preparations...\n\n"
#--------------------------------------------------------------------------
# ACTION: Check that test plant specific variables have been set by a
#         configuration file. Otherwise, prompt for variable values.
    ath_display "Checking SUT-specific config file parameters"
    ath_check_parameter "SUT::APG1"      "Enter the name of APG1: "
    ath_check_parameter "SUT::APG1_USER" "Enter the Telnet logon user ID for APG1: "
    ath_check_parameter "SUT::APG1_PW"   "Enter the Telnet logon password for APG1: "

# ACTION: Source used procedure scripts
    ath_display "Sourcing used procedure scripts"
#    ath_use "PROC_CHAR_1_PA2.tcl"
#    ath_use "PROC_PERF_1_PA3.tcl"
#    ath_use "PROC_ALH_1_PA6.tcl"
#    ath_use "PROC_MSP_1_PA3.tcl"; # Required by PROC_PERF_1_PA3.tcl
    package require CHAR
    package require PERF
    package require ALH
    package require MSP

	# ACTION: Establish a telnet session to the SUT
#    ath_display "Connecting a telnet session to the SUT"
#    ath_connect_telnet $SUT::APG1
#    ath_login_telnet $SUT::APG1_USER $SUT::APG1_PW
#    set general_session $spawn_id

	# ACTION: Check prerequisites
#   ath_display "Checking prerequisities for characteristics measurements"
#   CHAR::CheckGeneralPreRequisites

	# ACTION: Prepare the performance monitor
#    ath_display "Preparing the performance monitor"
#    PERF::Setup

	# ACTION: Start the performance monitor with reports in 1 second intervals (required sessions)
#    ath_display "Starting the performance monitor with reports in 1 second intervals"
#    PERF::Start {\Processor(_Total)\% Processor Time} {\Memory\Available MBytes} -si 1

#--------------------------------------------------------------------------
# Global variables
#--------------------------------------------------------------------------

ath_connect_ssh $SUT::APG1 -P 4422
ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
print "\n"
print "\n"
print "\n"
print "\n"
ath_send "netstat -antp | grep :4422"
print "\n"
print "\n"
print "\n"
print "\n"
ath_send "cat /proc/stat | head -n 5"
print "\n"
print "\n"
print "\n"
print "\n"
ath_send "free -m"
print "\n"
print "\n"
print "\n"
print "\n"
ath_send "rpm -qa | grep ssh"
print "\n"
print "\n"
print "\n"
print "\n"
#ath_send "prcstate"
#ath_send "exit"




# ACTION: Open the SSH sessions
    for {set i 1} {$i <= $sshsessions} {incr i} {

        # ACTION: Open an SSH session (port 4422).
        AutoFail OFF
        ath_connect_ssh $SUT::APG1 -P 4422
		ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
		ath_send_p "Password:" "su"
        ath_send "Administrator1@"

        if {$ATH::ReturnCode != 0} {
            ath_tc_failed "Failed to open session $i"
        }
        ath_display "Opening MSS session $i of $sshsessions, spawn_id is \"$spawn_id\""
#       set SSHSession($i) $spawn_id;
#		ath_display "$SSHSession($i)"
        set nsshsessions $i
        ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
#		ath_display $spawn_id
		set SSHSession($i) $spawn_id;
		ath_display "$SSHSession($i)"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
        ath_display "Opened SSH session $i of $sshsessions, spawn_id is \"$spawn_id\""
		print "\n"
		print "\n"
		print "\n"
		print "\n"
		ath_send "prcstate -l"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
		ath_send "faillog"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
		ath_send "ps aux | grep ssh"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
		
#		connession opened (soket....)
		ath_send "netstat -antp | grep :4422"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
#		load cpu %(kernel)
		ath_send "cat /proc/stat | head -n 5"
		print "\n"
		print "\n"
		print "\n"
		print "\n"
#		System Usage memory
		ath_send "free -m" 
		print "\n"
		print "\n"
		print "\n"
		print "\n"
        if {$ATH::ReturnCode != 0} {
            print "SSH session logging failed\n"
            ath_tc_failed "Failed to open SSH session # $i of $sshsessions"
        }

    }

    print "\nNumber of SSH sessions made: $nsshsessions\n\n"

     # ACTION: Connect minimum number of required SFTP sessions, one session every 10 seconds
#    ath_display "Connecting $sftpsessions SFTP sessions, one session every 10 seconds"
     # As sftp-connection establishment may take various long time depending on the AP CPU load
     # We're better off making the connections through procedures calls in 10 second intervals,
     # rather than through a loop with delays.

#    set delay 0
#    set attempted_connections 0
    # Initiate no. calls to connect_sftp_session with 10 seconds delay between each call.
    # The procedure calls will be put in a "job buffer" and executed by a background
    # process after the delay time.
#    for {set i 1} {$i <= $sftpsessions} {incr i} {
#        set delay 10000; # Milliseconds
    #    after $delay [list connect_sftp_session]
#        after $delay
#        connect_sftp_session
#    }

    # ACTION: Wait for all sessions to have been attempted to be connected
#    incr delay 300000
#    set timeoutid [after $delay [list ath_tc_failed "Timeout waiting for $sftpsessions SFTP sessions to be established"]]
#    while {$attempted_connections < $sftpsessions} {vwait attempted_connections}
#    after cancel $timeoutid

    # ACTION: Check that all sftp connections were successful
#    print "\n"
#    if {$nsftpsessions == $sftpsessions} {
#        ath_display "$nsftpsessions sftp sessions are successfully established"
#    } else {
#        ath_tc_failed "Only $nsftpsessions of required $sftpsessions were successfully connected"
#    }

    # ACTION: Get the AP local measurement start time (required sessions)
#    ath_display "Getting the AP local measurement start time"
#    if {$spawn_id != $general_session} {
#        set spawn_id $general_session;  # Return to the telnet session
#        print "\n\nBack on the telnet session...\n"
#    }
#    set start_time [PERF::GetRemoteTime]
#    print "AP local measurement start time is \"$start_time\"\n"
	# COMMENT: We need to collect a few performance measurement reports to calculate
	#          the average CPU-load and free memory when having 30 sessions connected.
	#          For the graphs from session 1 and up we'll collect all measurement
	#          reports after having stopped the performance monitor.

	# ACTION: Wait for a few performance monitor reports (required sessions)
#    ath_display "Waiting 10 minutes for performance monitor reports"
#    WaitMinutes 10

	# ACTION:  Get the local measurement stop time (required sessions)
#    ath_display "Getting the AP local measurement stop time (required sessions)"
#    set stop_time [PERF::GetRemoteTime]
#    print "AP local measurement stop time is \"$stop_time\"\n"

	# ACTION: Stop the performance monitor (required sessions)
#    ath_display "Stopping the performance monitor (required sessions)"
#    print "Performance measurement collection period: $start_time to $stop_time\n"
#    set PERF::Verbose 1
#    PERF::Stop $start_time $stop_time

	# ACTION: Calculate the average performance measurements (required sessions)
#    set req_cpu_av [Round [lindex $PERF::Result 0] 0]
#    set req_cpu_min [Round [lindex $PERF::MinResult 0] 0]
#    set req_cpu_max [Round [lindex $PERF::MaxResult 0] 0]
#    set req_mem_av [Round [lindex $PERF::Result 1] 0]
#    set req_mem_min [Round [lindex $PERF::MinResult 1] 0]
#    set req_mem_max [Round [lindex $PERF::MaxResult 1] 0]
#    ath_display "Measurement results for $sftpsessions SFTP sessions:"
#    print "CPU-load(%): Average=$req_cpu_av, Min=$req_cpu_min, Max=$req_cpu_max\n"
#    print "Mem.Avail(MB): Average=$req_mem_av, Min=$req_mem_min, Max=$req_mem_max\n"

	# ACTION: Print compliance statement
#    if {[string length $remarks] > 0} {append remarks "\n"}
#    if {$nsftpsessions >= $sftpsessions} {
#        append remarks "Requirement fulfilled."
#    } else {
#        append remarks "Requirement not fulfilled."
#    }

	# ACTION: Report the measurement result
#    ath_display "Reporting the measurement result"
#    set result {}
#    lappend result "$TestCase"
#    lappend result "SFTP Sessions"
#    lappend result "SFTP sessions required: $sftpsessions"
#    lappend result "Established SFTP sessions: $nsftpsessions"
#    lappend result "SSH Sessions"
#    lappend result "SSH sessions required: $sshsessions"
#    lappend result "Established SSH sessions: $nsshsessions"
#    lappend result "CPU-load(%): Average=$req_cpu_av, Min=$req_cpu_min, Max=$req_cpu_max"
#    lappend result "Mem.Avail(MB): Average=$req_mem_av, Min=$req_mem_min, Max=$req_mem_max"


#    set Result ""
#    foreach res $result {append Result "$res\n"}
#    set Result [string trimright $Result]
#    ath_display "Measurement result:\n$Result"

#    if {[info exists ATH::TC_Comment]} {set ATH::TC_Comment "Measurement result:\n$Result"}


#**************************************************************************
# Report Test Case Result
#**************************************************************************
# ACTION: Report test case result.

    if {$nsshsessions < $sshsessions} {
        ath_tc_failed "Failed to open required SSH sessions"
    } else {
        print "\nSuccessfully connected $nsshsessions of $sshsessions\n\n"
    }


#    set tc_completed 1
#    if {$nsftpsessions >= $sftpsessions} {
#        # Requirement fulfilled
#        ath_tc_passed
#    } else {
        # We wont reach this far as ath_tc_failed has already been called
#        ath_tc_failed "Requirement not fulfilled."
#    }





ath_tc_passed

#**************************************************************************
# :CleanUp
#**************************************************************************
proc CleanUp args {
    print "CleanUp(): Cleaning up...\n"
    AutoFail OFF

    #Global variables
    global sftp_session_spawn_id
    global spawn_id
    global nsftpsessions
    global nsshsessions
    global SSHSession
    global Result
    global tc_completed
	global ps_aux_grep_ssh
    set session 0

    # Close any open ssh sessions
    ath_display "Closing any open ssh sessions"
    for {set i 1} {$i <= [expr $nsshsessions]} {incr i} {
            set spawn_id $SSHSession($i)
            ath_display "Closing SSH session $i of $nsshsessions, spawn_id is \"$spawn_id\""
			print "\n"
			print "\n"
			print "\n"
			print "\n"
#		connession opened (soket....)
			ath_send "netstat -antp | grep :4422"
			print "\n"
			print "\n"
			print "\n"
			print "\n"

#		load cpu %(kernel)
			ath_send "cat /proc/stat | head -n 5"
			print "\n"
			print "\n"
			print "\n"
			print "\n"

#		System Usage memory
			ath_send "free -m"
			print "\n"
			print "\n"
			print "\n"
			print "\n"
            ath_send "exit"
    }
	
#ath_connect_ssh $SUT::APG1 -P 4422
#ath_login_ssh $SUT::APG1_USER $SUT::APG1_PW
#ath_send "faillog -r"
#ath_send "ps aux | grep ssh"
#ath_send "ps -A | grep ssh"


#ath_display $ATH::LastResponse
#ath_display $ps_aux_grep_ssh


#print "\n"
#ath_match $ps_aux_grep_ssh $ATH::LastResponse
#print "\n"

#set val1 $ATH::ReturnCode

#if { $val1 == 0} { ath_display "all SSH sessions have been closed"} else {
#                                         ath_tc_failed "not all SSH sessions have been closed" }

#ath_send "exit"
    # Close any open sftp sessions
#    ath_display "Closing any open sftp sessions"
#    foreach sid $sftp_session_spawn_id {
#        incr session
#        print "\nClosing sftp session $session of $nsftpsessions, spawn_id \"$sid\"\n"
#        set spawn_id $sid
#        ath_send_ftp "bye"
#        print "\n"
    }

    # Connect a telnet session
#    ath_display "Connecting a telnet session"
#    ath_connect_telnet $SUT::APG1
#    ath_login_telnet $SUT::APG1_USER $SUT::APG1_PW

    # Execute CHAR::GeneralCleanUp
#    ath_display "Executing CHAR::GeneralCleanUp"
#    CHAR::GeneralCleanUp

    # Print the measurement result at the end of the logfile
    if {$tc_completed} {
        ath_display "Measurement result:\n$Result"
    }

    print "CleanUp(): Done.\n"
}


###########################################################################
# :References
###########################################################################
# [1] -

