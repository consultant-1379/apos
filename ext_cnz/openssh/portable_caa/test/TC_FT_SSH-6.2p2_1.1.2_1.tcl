####################################################################################################
# :Title script that check the functionality of OPENSSH 6.2p : SFTP functionality with user sysadmin
#
#---------------------------------------------------------------------------------------------------
# :TestAct  
# :SubSys   	
# :TestObj  	
# :Prepared 	Giuseppe Pontillo
# :Approved 
# :Date 	2013-11-05
# :Req  
# :Ref
# :TCLTCS   
# :TCLTCI   
# :RegTest  
# :Scope    
# :OS       	Linux
# :APZ  
# :NrOfAPGs 	1
# :NrOfBCs  	0
#############################################################################################
#:Revision Information
# ---------------------
# Ver   Rev 	When           By                 Description
#  1    PA1     2013-11-05     Giuseppe Pontillo  First draft
#     
#############################################################################################
# :commands to verify SFTP functionality with LDAP user sysadmin
# --------------------------------------------------------------
#     
#############################################################################################
package require ATH
package require CygwinSSH

#
ath_source "Common_SSH_1.0.0.tcl"

#ath_source PROC_Pre_Check_services.tcl

print "\n\n"

#--------------------------------------------------------------------------
# Global variables
#--------------------------------------------------------------------------

set activenode 0

#-------------------------------------------------------------------------------------------
ath_display "Description"
#-------------------------------------------------------------------------------------------

print "*************************************************************\n"
print "THIS TEST CHECKS THE FUNCTIONALITY OF OPENSSH 6.2p2\n"
print "\n"
print "SFTP functionality with user $SUT::APG1_COM_USER\n"
print "\n"
print "*************************************************************\n"

print "\n"

# set revision 0.0.0
# check_revision $revision
set empty "**
**
"

#------------------------------------------------------------------------------------------------
# Connect to ISPservice
#-------------------------------------------------------------------------------------------------

#start_ISPservice

#-------------------------------------------------------------------------------------------
ath_display "Preparation"
#-------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------
ath_display "open SSH Connection"
#-------------------------------------------------------------------------------------------
connect_to_active_node

ath_display $activenode

ath_send "cd /tmp"

ath_send "echo \"QGIUPON SSH\" > TS_USER1_SFTP_TEST.txt"

ath_send "sudo -u $SUT::APG1_TS_USER  cp /tmp/TS_USER1_SFTP_TEST.txt /data/opt/ap/nbi_fuse/sw_package/"

ath_send "sudo -u $SUT::APG1_TS_USER  ls -la /data/opt/ap/nbi_fuse/sw_package/TS_USER1_SFTP_TEST.txt"

ath_send "sudo -u $SUT::APG1_TS_USER  cat /data/opt/ap/nbi_fuse/sw_package/TS_USER1_SFTP_TEST.txt"

#ath_send "cd /data/opt/ap/nbi_fuse/"

#ath_send "touch SFTP_test.txt"

#ath_send "ls"
#-------------------------------------------------------------------------------------------
ath_display "close SSH Connection"
#-------------------------------------------------------------------------------------------

ath_send "exit"


#-------------------------------------------------------------------------------------------
ath_display "Execution"
#-------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------
ath_display "connect_to_sftp"
#-------------------------------------------------------------------------------------------
AutoFail OFF
exp_spawn  "C:/ATH/packages/SSH/OpenSSH/PSFTP.EXE" $activenode 
ath_login_sftp "$SUT::APG1_COM_USER" "$SUT::APG1_COM_PW"

ath_send_ftp "pwd"

ath_send_ftp "cd sw_package"

ath_send_ftp "ls"

#ath_display $ATH::LastResponse

set patternSftpTestFile ":
* * * * * * * * TS_USER1_SFTP_TEST.txt
:"

print "\n"
ath_match $patternSftpTestFile $ATH::LastResponse
print "\n"


set val1 $ATH::ReturnCode


if { $val1 == 0} { ath_display "Test file TS_USER1_SFTP_TEST.txt present"} else {
                                         ath_tc_failed "Test file TS_USER1_SFTP_TEST.txt not present" }




ath_send_ftp "lpwd"
ath_send_ftp "lcd $SUT::LOCAL_SFTP_FOLDER"
ath_send_ftp "get TS_USER1_SFTP_TEST.txt"

#ath_display $ATH::LastResponse

set patternSftpTestFileGet ":
remote:/sw_package/TS_USER1_SFTP_TEST.txt => local:TS_USER1_SFTP_TEST.txt
:"

print "\n"
ath_match $patternSftpTestFileGet $ATH::LastResponse
print "\n"

set val1 $ATH::ReturnCode

if { $val1 == 0} { ath_display "get command correctly executed"} else {
                                         ath_tc_failed "get command NOT correctly executed" }


ath_send_ftp "rm TS_USER1_SFTP_TEST.txt"

ath_display $ATH::LastResponse

set patternSftpTestFilermPermissionDenied ":
rm /sw_package/TS_USER1_SFTP_TEST.txt: permission denied
:"

print "\n"
ath_match $patternSftpTestFilermPermissionDenied $ATH::LastResponse
print "\n"

set val1 $ATH::ReturnCode

if { $val1 == 0} { ath_display "Remove command correctly denieded"} else {
                                         ath_tc_failed "Remove command NOT correctly denieded" }

print "\n"


ath_send_ftp "put TS_USER1_SFTP_TEST.txt"

set patternSftpTestFilePutPermissionDenied ":
/sw_package/TS_USER1_SFTP_TEST.txt: permission denied
:"

print "\n"
ath_match $patternSftpTestFilePutPermissionDenied $ATH::LastResponse
print "\n"

set val1 $ATH::ReturnCode

if { $val1 == 0} { ath_display "Put command correctly denieded"} else {
                                         ath_tc_failed "Put command NOT correctly denieded" }
										 
#-------------------------------------------------------------------------------------------
ath_display "Close sftp session"
#-------------------------------------------------------------------------------------------
										 

ath_send_ftp "quit"


#-------------------------------------------------------------------------------------------
ath_display "Clean up"
#-------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------
ath_display "connect_to_sftp_as_ts_user1"
#-------------------------------------------------------------------------------------------
AutoFail OFF
exp_spawn  "C:/ATH/packages/SSH/OpenSSH/PSFTP.EXE" $activenode 
ath_login_sftp "$SUT::APG1_TS_USER" "$SUT::APG1_TS_PW"


ath_send_ftp "rm /sw_package/TS_USER1_SFTP_TEST.txt"

ath_display $ATH::LastResponse

set patternSftpTestFilerm ":
rm /sw_package/TS_USER1_SFTP_TEST.txt: OK
:"


print "\n"
ath_match $patternSftpTestFilerm $ATH::LastResponse
print "\n"

set val1 $ATH::ReturnCode

if { $val1 == 0} { ath_display "remove command correctly executed"} else {
                                         ath_tc_failed "remove command NOT correctly executed" }

print "\n"

ath_send_ftp "ls"

print "\n"
ath_match $patternSftpTestFile $ATH::LastResponse
print "\n"


set val1 $ATH::ReturnCode


if { $val1 == 0} { ath_tc_failed "Test file TS_USER1_SFTP_TEST.txt not removed"} else {
                                         ath_display "Test file TS_USER1_SFTP_TEST.txt removed" }








#-------------------------------------------------------------------------------------------
ath_display "Close sftp session"
#-------------------------------------------------------------------------------------------
										 

ath_send_ftp "quit"		 
AutoFail OFF
#ath_pre_check_services


preparation_cmd




AutoFail OFF


ath_tc_passed

proc CleanUp args {
}