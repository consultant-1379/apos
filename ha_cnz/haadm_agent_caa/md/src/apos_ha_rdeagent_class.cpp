/*===================================================================
 *
 *  @file   "apos_ha_rdeagent_class.cpp"
 *
 *  @brief
 *
 *
 *  @version 1.0.0
 *
 *
 *  HISTORY
 *
 *
 *
 *
 *       PR           DATE      INITIALS    DESCRIPTION
 *--------------------------------------------------------------------
 *       N/A       DD/MM/YYYY     NS       Initial Release
 *==================================================================== */

/*====================================================================
 *                           DIRECTIVE DECLARATION SECTION
 * =================================================================== */

#include "apos_ha_rdeagent_class.h"

using namespace std;

//-----------------------------------------------------------------------------
APGHA_RDEAgent::APGHA_RDEAgent(const char* daemon_name, const char* user_name):
	APOS_HA_RdeAgent_AmfClass(daemon_name, user_name)
{
	Initialize_Agent();
}


//-----------------------------------------------------------------------------
APGHA_RDEAgent::APGHA_RDEAgent()
{
	/* constructor */
	Initialize_Agent();
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::Initialize_Agent()
{
	this->NodeA.PortOne.Is_healthy = FALSE;
	this->NodeB.PortTwo.Is_healthy = FALSE;
	this->PortOne.disk.Is_healthy = FALSE;
	this->PortOne.disk.Is_registered = FALSE;
	this->PortOne.disk.Is_reserved = FALSE;
	this->PortTwo.disk.Is_healthy = FALSE;
	this->PortTwo.disk.Is_registered = FALSE;
	this->PortTwo.disk.Is_reserved = FALSE;
	this->backPlaneUp = FALSE;
	this->IsRAIDConfigured = FALSE;
	this->IsMIPConfigured = FALSE;
	this->terminateRdeAgent = FALSE;
	this->handleRdeAgentGracefullDownJobsDone=FALSE;
	this->Is_Agent_Stanby=FALSE;
	this->initiateFailover=FALSE;
	this->Is_State_Assgned=FALSE;
	this->gep_id = 0;
	this->node_id = 0;
	this->diskRenewalThreadFreq = 0;
	this->renewDiskRegCounter =0;
	this->X_Times=DEFLT_X_TIMES;
	this->Y_Msecs=DEFLT_Y_MSECS;
	this->diskRenewalThreadFreq=DEFALT_THREAD_FREQ;
	this->IsDebug=FALSE;
}

//-----------------------------------------------------------------------------
APGHA_RDEAgent::~APGHA_RDEAgent() {
	/* empty destructor */
}

//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------
ACS_APGCC_SEL_OBJ APGHA_RDEAgent::term_sel_obj;
ACS_APGCC_SEL_OBJ APGHA_RDEAgent::sigrt_sel_obj;
ACS_APGCC_SEL_OBJ APGHA_RDEAgent::sighup_sel_obj;
ACS_APGCC_SEL_OBJ APGHA_RDEAgent::sigint_sel_obj;
ACS_APGCC_SEL_OBJ APGHA_RDEAgent::iTimer_sel_obj;
ACS_APGCC_AgentUtils APGHA_RDEAgent::utils;
ACS_APGCC_BOOL APGHA_RDEAgent::sigterm_received = FALSE;
ACS_APGCC_BOOL APGHA_RDEAgent::sigint_received = FALSE;
ACS_APGCC_BOOL APGHA_RDEAgent::update_datadisk_info = FALSE;
ACS_APGCC_BOOL APGHA_RDEAgent::update_raid_info = FALSE;
ACS_APGCC_BOOL APGHA_RDEAgent::debugEnabled = FALSE;
ACE_INT32 APGHA_RDEAgent::logCounter=0;
ACS_APGCC_RDARoleT APGHA_RDEAgent::rdeServerRoleReceived=ACS_APGCC_RDA_UNDEFINED;

const char* APGHA_RDEAgent::role_string[] = { 	"UNDEFINED",
	"ACTIVE",
	"STANDBY",
	"QUIESCED",
	"ASSERTING",
	"YIELDING" };

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::InitializeRdeAgentEngine(void)
{
	if ( readConfig() != ACS_APGCC_SUCCESS ) {
		syslog(LOG_ERR, "RDE_Agent: readConfig FAILED");
		return ACS_APGCC_FAILURE;
	}

	if ( setNodeId() != ACS_APGCC_SUCCESS ){
		syslog(LOG_ERR, "RDE_Agent: setNodeId FAILED");
		return ACS_APGCC_FAILURE;
	}

	if ( setGepId () != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	if ( updateDiskStatusFile() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	if ( tipcObj.tipc_initialize(getNodeId()) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR, "RDE_Agent: Tipc Initialization Failure");
		return ACS_APGCC_FAILURE;
	}

	if ( checkSCSIControllerStatus() != ACS_APGCC_SUCCESS ) {
		return ACS_APGCC_FAILURE;
	}

	if ( checkAvailableDataDisks() != ACS_APGCC_SUCCESS ) {
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::ActiveJobsDebug()
{
	/* reset the folllowing paramters to their defaults if the transision happens*/
	this->Is_State_Assgned=TRUE;
	this->handleRdeAgentGracefullDownJobsDone=FALSE;
	this->IsRAIDConfigured=FALSE;
	this->IsMIPConfigured=FALSE;
	this->Is_Agent_Stanby=FALSE;

	ACS_APGCC_BOOL OnStart=FALSE;

	syslog(LOG_INFO ,"RDE_Agent: Registering Available Data disks:");

	if ( registerReachableDataDisks() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	OnStart=TRUE;

	if ( dataDiskReservationAlgo() != ACS_APGCC_SUCCESS ) {
		/* Disk reservation FAILED, we can not take the
		 * ACTIVE role, reset the node.
		 */
		syslog(LOG_INFO ,"RDE_Agent: Disk reservation Algo FAILED on ACTIVE Node.. Initiating Node Failover...");
		return ACS_APGCC_FAILURE;
	}

	if ( mountRAIDandActivateMIPs(OnStart)!= ACS_APGCC_SUCCESS ) {
		if (!this->IsRAIDConfigured) {
			syslog(LOG_INFO ,"RDE_Agent: RAID and MIP Configure FAILED on Active Node.");
			return ACS_APGCC_FAILURE;
		}
	}

	/* Update our active data disks with logical raid disks.
	 * Registration and renewal will be happening on these
	 * disks
	 */
	if(updateDatadisksWithRaidDisks() != ACS_APGCC_SUCCESS ) {
		syslog(LOG_ERR, "RDE_Agent: Updating the data disks with RAID disks FAILED!.. Initiating Component Faiover");
		return ACS_APGCC_FAILURE;
	}

	if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS ){
		syslog(LOG_ERR, "RDE_Agent: Updating updateBothNodeDisknControllerstatus FAILED!.. Initiating Component Faiover");
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO, "RDE_Agent: RDE Agent Role: ACTIVE");
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::ExecuteDebug()
{
	FILE *p_fd;
	ACE_TCHAR command_string[CMD_LEN];
	ACE_TCHAR line[80];
	line[0]='\0';
	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --node-state");

	p_fd = popen (command_string,"r");

	if ( p_fd == NULL ){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;

		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			//if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while

		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: Counter NULL data found");
			break; // from outer while
		}
	}

	if (ACE_OS::strstr(line ,"ACTIVE") != NULL){
		syslog(LOG_INFO, "apos_ha_rdeagentd : Running on active node...");
		if(ActiveJobsDebug() == ACS_APGCC_FAILURE)
		{
			syslog(LOG_INFO, "apos_ha_rdeagentd : Running on standby node...");
			pclose(p_fd);
			return ACS_APGCC_FAILURE;
		}
	}
	else if(ACE_OS::strstr(line ,"STANDBY") != NULL){
		syslog(LOG_INFO, "apos_ha_rdeagentd : Running on standby node...");
		if(StandbyJobsDebug() == ACS_APGCC_FAILURE)
		{
			syslog(LOG_INFO, "apos_ha_rdeagentd : Running on standby node...");
			return ACS_APGCC_FAILURE;
		}
	}
	else
	{
		syslog(LOG_INFO, "apos_ha_rdeagentd : Internal error occured while executing command...");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::StandbyJobsDebug()
{
	this->Is_Agent_Stanby=TRUE;
	this->Is_State_Assgned=TRUE;
	if ( registerReachableDataDisks() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS ){
		syslog(LOG_INFO, "RDE_Agent: updateBothNodeDisknControllerstatus FAILED");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::ShutdownJobsDebug()
{
	if (this->handleRdeAgentGracefullDownJobsDone) {
		syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED!");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	if(previousHAState == ACS_APGCC_AMF_HA_ACTIVE) {
		syslog(LOG_INFO ,"RDE_Agent: Received State Transistion From ACTIVE to ACTIVE.");
		return ACS_APGCC_SUCCESS;
	}

	/* reset the folllowing paramters to their defaults if the transision happens*/
	this->Is_State_Assgned=TRUE;
	this->handleRdeAgentGracefullDownJobsDone=FALSE;
	this->IsRAIDConfigured=FALSE;
	this->IsMIPConfigured=FALSE;
	this->Is_Agent_Stanby=FALSE;

	ACS_APGCC_BOOL OnStart=FALSE;
	syslog(LOG_INFO ,"RDE_Agent: Registering Available Data disks:");
	if ( registerReachableDataDisks() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}
	if (previousHAState == ACS_APGCC_AMF_HA_UNDEFINED) {
		/* Received Active State from AMF. Check if we
		 * can become Active using our data disk
		 * reservation Algorithm. If we can not go
		 * Active, reset the node
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From UNDEFINED to ACTIVE.");
		if (this->initiateFailover){
			syslog(LOG_INFO, "RDE_Agent: Initiating Node Failover...");
			InitiateFailover(ACS_APGCC_NODE_FAILOVER);
			return ACS_APGCC_FAILURE;
		}
		OnStart=TRUE;
	}

	if (previousHAState == ACS_APGCC_AMF_HA_STANDBY) {
		/* State transition from passive to active.
		 * Check if we can become active using our
		 * data disk reservation algorithem. If we
		 * can not go active, reset the node
		 *
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From PASSIVE to ACTIVE.");
		if (IsActiveStateTransitionAllowed() == FALSE){
			syslog(LOG_ERR, "RDE_Agent: Can not take the ACTIVE ROLE. Initiating Node Failover...");
			InitiateFailover(ACS_APGCC_NODE_FAILOVER);
			return ACS_APGCC_FAILURE;
		}
	}

	/* Common activities
	 */
	if (dataDiskReservationAlgo() != ACS_APGCC_SUCCESS) {
		/* Disk reservation FAILED, we can not take the
		* ACTIVE role, initiate node failover.
		*/
		syslog(LOG_INFO ,"RDE_Agent: Disk reservation Algo FAILED on ACTIVE Node.. Initiating Node Failover...");
		InitiateFailover(ACS_APGCC_NODE_FAILOVER);
		return ACS_APGCC_FAILURE;
	}
	if (mountRAIDandActivateMIPs(OnStart)!= ACS_APGCC_SUCCESS){
		if (!this->IsRAIDConfigured){
			syslog(LOG_INFO ,"RDE_Agent: RAID and MIP Configure FAILED on Active Node.");
			return ACS_APGCC_FAILURE;
		}
		if (!this->IsMIPConfigured){
     		syslog(LOG_INFO ,"RDE_Agent: MIP Configuration FAILED on Active Node.");
			return ACS_APGCC_FAILURE;
    	}
	}

	/* Update our active data disks with logical raid disks.
	 * Registration and renewal will be happening on these
	 * disks
	 */
	if(updateDatadisksWithRaidDisks() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: Updating the data disks with RAID disks FAILED!.. Initiating Component Faiover");
		InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
		return ACS_APGCC_FAILURE;
	}

	if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: Updating updateBothNodeDisknControllerstatus FAILED!.. Initiating Component Faiover");
		InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO, "RDE_Agent: RDE Agent Role: ACTIVE");
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	this->Is_Agent_Stanby=TRUE;
	this->Is_State_Assgned=TRUE;
	if(previousHAState == ACS_APGCC_AMF_HA_STANDBY) {
		syslog(LOG_INFO ,"RDE_Agent: Received State Transistion From PASSIVE to PASSIVE.");
		return ACS_APGCC_SUCCESS;
	}

	if (previousHAState == ACS_APGCC_AMF_HA_UNDEFINED) {
		/* Ok.Our applicaion has given Passive State from AMF
		 * Nothing much left to do in this case, as we have
		 * done disk registration on initialization.
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From UNDEFINED to PASSIVE.");

		if (this->initiateFailover){
			syslog(LOG_INFO, "RDE_Agent: Initiating Node Failfast...");
			InitiateFailover(ACS_APGCC_NODE_FAILFAST);
			return ACS_APGCC_FAILURE;
		}
	}

	syslog(LOG_INFO ,"RDE_Agent: Registering Available Data disks:");
	if ( registerReachableDataDisks() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	if (previousHAState == ACS_APGCC_AMF_HA_ACTIVE ) {
		/* State transition from active to passive.
		 * We have released data disks we own in quiesced Jobs.
		 * Nothing much left to do in this case. Return Success.
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From ACTIVE to PASSIVE.");
	}

	if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS ){
		syslog(LOG_INFO, "RDE_Agent: updateBothNodeDisknControllerstatus FAILED");
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO, "RDE_Agent: RDE Agent Role: STANDBY");
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	if(previousHAState == ACS_APGCC_AMF_HA_QUIESCING) {
		syslog(LOG_INFO ,"RDE_Agent: Received State Transistion From QUIESCING to QUIESCING.");
		return ACS_APGCC_SUCCESS;
	}

	if (previousHAState == ACS_APGCC_AMF_HA_ACTIVE) {
		/* State transition from Active to Quiesing.
		 * Losing Active State.
		 * Perform following tasks.
		 * 	1. Release registered data disks
		 * 	2. Deactivate MIPs
		 * 	3. Deactivate RAID & Unmount Data disks
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From ACTIVE to QUIESCED.");

		if (this->handleRdeAgentGracefullDownJobsDone) {
			syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
			return ACS_APGCC_SUCCESS;
		}

		if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED!");
			return ACS_APGCC_FAILURE;
		}
		return ACS_APGCC_SUCCESS;
	}
	/*
	 * state transition to QUEISING from any other state is invalid
	 */
	return ACS_APGCC_FAILURE;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	syslog(LOG_INFO ,"RDE_Agent: Received State Transition To QUIESCED");
	if(previousHAState == ACS_APGCC_AMF_HA_QUIESCED) {
		syslog(LOG_INFO ,"RDE_Agent: Received State Transistion From QUIESCED to QUIESCED");
		return ACS_APGCC_SUCCESS;
	}

	if (previousHAState == ACS_APGCC_AMF_HA_ACTIVE) {
		/* State transition from Active to Quiesced Jobs.
		 * Losing Active State.
		 * Perform following tasks.
		 * 	1. Release registered data disks
		 * 	2. Deactivate MIPs
		 * 	3. Deactivate RAID & Unmount Data disks
		 */
		syslog(LOG_INFO ,"RDE_Agent: Received State Transition From ACTIVE to QUIESCED.");

		if (this->handleRdeAgentGracefullDownJobsDone) {
			syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
			return ACS_APGCC_SUCCESS;
		}

		if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED!");
			return ACS_APGCC_FAILURE;
		}
		return ACS_APGCC_SUCCESS;
	}

	/*
	 * state transition to QUEISCED from any other state is invalid
	 */
	return ACS_APGCC_FAILURE;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performComponentHealthCheck(void)
{
	/* Respond to AMF that you are healthy
	*/
	if (debugEnabled) {
		syslog(LOG_INFO ,"RDE_Agent: HealtchCheck Received");
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performComponentTerminateJobs(void)
{
	syslog(LOG_INFO ,"RDE_Agent: Component TerminateJobs Received");
	this->terminateRdeAgent = TRUE;
	if (getHAState() == ACS_APGCC_AMF_HA_STANDBY){
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobsDone) {
		syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED!");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performComponentRemoveJobs(void)
{
	syslog(LOG_INFO ,"RDE_Agent: Component RemoveJobs Received");
	if (getHAState() == ACS_APGCC_AMF_HA_STANDBY)
		return ACS_APGCC_SUCCESS;

	if (this->handleRdeAgentGracefullDownJobsDone) {
		syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED!");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::performApplicationShutdownJobs()
{
	syslog(LOG_INFO, "RDE_Agent: performApplicationShutdownJobs");
	if (getHAState() == ACS_APGCC_AMF_HA_STANDBY){
		utils.sel_obj_ind(term_sel_obj);
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobsDone) {
		syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
		return ACS_APGCC_SUCCESS;
	}

	if (handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED");
		return ACS_APGCC_FAILURE;
	}
	utils.sel_obj_ind(term_sel_obj);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::sigusr1Handler(int sig)
{
	(void)sig;
	if (debugEnabled){
		debugEnabled=FALSE;
		syslog(LOG_INFO,"RDE_Agent: Disableing Debug Trace");
	}
	else {
		debugEnabled=TRUE;
		syslog(LOG_INFO,"RDE_Agent: Enable Debug Trace");
	}
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::sighupHandler(int sig)
{
	(void)sig;
	syslog(LOG_INFO,"RDE_Agent: signal HUP received. Reading the Configuration file");
	utils.sel_obj_ind(sighup_sel_obj);
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::AgentShutdownHandler(int sig)
{
	switch(sig){
		case SIGTERM:
			syslog(LOG_INFO, "RDE_Agent: Shutting Rde Agent Down...(TERM)");
			sigterm_received=TRUE;
			utils.sel_obj_ind(term_sel_obj);
			break;
		case SIGINT:
			syslog(LOG_INFO, "RDE_Agent: Shutting Rde Agent Down...(INT)");
			sigint_received=TRUE;
			utils.sel_obj_ind(sigint_sel_obj);
			break;
	}
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::updateDiskStatusHandler(int sig)
{
	(void)sig;
	syslog(LOG_INFO, "RDE_Agent: SIG_UPDATE_DISK Received");
	update_datadisk_info=TRUE;
	utils.sel_obj_ind(sigrt_sel_obj);
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::updateRaidStatusHandler(int sig)
{
	(void)sig;
	syslog(LOG_INFO, "RDE_Agent: SIG_UPDATE_RAID Received");
	update_raid_info=TRUE;
	utils.sel_obj_ind(sigrt_sel_obj);
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::registerReachableDataDisks()
{
	ACS_APGCC_ReturnType errorCode;
	ACE_INT32 diskRegCounter=0;
	this->PortOne.disk.Is_registered = FALSE;
	this->PortTwo.disk.Is_registered = FALSE;

	/* register working data disks */
	if (debugEnabled) {
		syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to register disk:[%s]", diskRegCounter+1, this->PortOne.disk.diskname);
	}

	if (this->PortOne.Is_healthy == TRUE && this->PortOne.disk.Is_healthy == TRUE) {
		while (diskRegCounter != MAX_ATTEMPTS){
			/* disk1 registration*/

			if ( (errorCode = registerDataDisk(this->PortOne.disk.diskname )) != ACS_APGCC_SUCCESS ) {
				syslog(LOG_ERR,"RDE_Agent: Registration FAILED on data disk [%s]" ,this->PortOne.disk.diskname);
				diskRegCounter++;
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to register disk:[%s]", diskRegCounter+1, this->PortOne.disk.diskname);
				msec_sleep(1000); // sleep for a sec before the next attempt
			}
			else {
				/* disk registration success */
				/* log Success message on 1 min interval */
				if ( logCounter == 0  || logCounter >= 30){
					syslog(LOG_INFO, "RDE_Agent: disk registration Success");
				}
				this->PortOne.disk.Is_registered = TRUE;
				break;
			}
		}

		if( (this->PortOne.disk.Is_registered == FALSE) &&
				(diskRegCounter >= MAX_ATTEMPTS)){
			//Perform disk Cleanup
			ACE_TCHAR command_string[CMD_LEN];
			syslog(LOG_INFO, "RDE_Agent: Performing cleanup for disk:[%s]", this->PortOne.disk.diskname);
			ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --clear-registrations %s",this->PortOne.disk.diskname);
			if (launchCommand(command_string) != ACS_APGCC_FAILURE)
			{
				syslog(LOG_INFO, "RDE_Agent: Cleanup registrations/reservations for disk:[%s] success", this->PortOne.disk.diskname);
				this->PortOne.disk.Is_registered = TRUE;
			}
			else
			{
				syslog(LOG_ERR, "RDE_Agent: Error in registration cleanup for disk:[%s]", this->PortOne.disk.diskname);
				return ACS_APGCC_FAILURE;
			}
		}
	}

	diskRegCounter=0;
	if (debugEnabled){
		syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to register disk:[%s]", diskRegCounter+1,this->PortTwo.disk.diskname);
	}

	if (this->PortTwo.Is_healthy == TRUE && this->PortTwo.disk.Is_healthy == TRUE){
		/* disk2 registration*/
		while (diskRegCounter != MAX_ATTEMPTS){
			if ( (errorCode = registerDataDisk(this->PortTwo.disk.diskname )) != ACS_APGCC_SUCCESS ) {
				syslog(LOG_ERR,"RDE_Agent: Registration FAILED on data disk [%s]" ,this->PortTwo.disk.diskname);
				diskRegCounter++;
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to register disk:[%s]", diskRegCounter+1,this->PortTwo.disk.diskname);
				msec_sleep(1000); // sleep for a sec before the next attempt
			}
			else {
				/* disk registration success */
				/* log Success message on 1 min interval */
				if ( logCounter == 0  || logCounter >= 30){
					syslog(LOG_INFO, "RDE_Agent: disk registration Success");
				}
				this->PortTwo.disk.Is_registered = TRUE;
				break;
			}
		}
		if( (this->PortTwo.disk.Is_registered == FALSE) &&
				(diskRegCounter >= MAX_ATTEMPTS)){
			//Perform disk Cleanup
			ACE_TCHAR command_string[CMD_LEN];
			syslog(LOG_INFO, "RDE_Agent: Performing cleanup for disk:[%s]", this->PortTwo.disk.diskname);
			ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --clear-registrations %s",this->PortTwo.disk.diskname);
			if (launchCommand(command_string) != ACS_APGCC_FAILURE)
			{
				syslog(LOG_INFO, "RDE_Agent: Cleanup for disk:[%s] success", this->PortTwo.disk.diskname);
				this->PortOne.disk.Is_registered = TRUE;
			}
			else
			{
				syslog(LOG_ERR, "RDE_Agent: Error in registration cleanup for disk:[%s]", this->PortTwo.disk.diskname);
				return ACS_APGCC_FAILURE;
			}
		}
	}

	/* make sure atleast we can work with One disk being active */
	if (!this->PortOne.disk.Is_registered && !this->PortTwo.disk.Is_registered )
		return ACS_APGCC_FAILURE;
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::launchCommand(char *command_string)
{
	int retCode;
	retCode = ACE_OS::system(command_string);
	if (retCode == -1 ){
		syslog(LOG_ERR, "\"system\" call failed while executing the command %s",command_string);
		return ACS_APGCC_FAILURE;
	}

	retCode = WEXITSTATUS(retCode);
	if (retCode != 0) {
		syslog(LOG_ERR,"[ %s ]command failed with error code: %d",command_string,retCode);
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACE_INT32 APGHA_RDEAgent::launch_popen(const char *command_string, ACS_APGCC_BOOL &port_status)
{
	ACE_TCHAR line[80],buff1[20],buff2[20];
	FILE *p_fd;
	line[0]='\0';
	port_status = FALSE;
	p_fd = popen (command_string,"r");
	if (p_fd == NULL){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			//if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: NULL data found");
			break; // from outer while
		}
		sscanf(line,"%s %s",buff1,buff2);
	}//end outer while

	if (ACE_OS::strcmp(buff2 ,"healthy") == 0)
		port_status = TRUE;
	if (ACE_OS::strcmp(buff2 ,"unhealthy") == 0)
		port_status = FALSE;

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"RDE_Agent: Error in popen close. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::checkSCSIControllerStatus()
{
	syslog(LOG_INFO ,"RDE_Agent: Checking SCSI Controller Status");
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_BOOL port_status = FALSE;
	this->PortOne.Is_healthy = FALSE ;
	this->PortTwo.Is_healthy = FALSE ;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	if (this->gep_id == GEP_ONE){
		ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-one-port-status 1");
		if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE)
			this->PortOne.Is_healthy = port_status;

		ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-one-port-status 2");
		if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE)
			this->PortTwo.Is_healthy = port_status;
	}

	if (this->gep_id == GEP_TWO){
		ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-two-port-status 1");
		if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE)
			this->PortOne.Is_healthy = port_status;

		ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-two-port-status 2");
		if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE)
			this->PortTwo.Is_healthy = port_status;
	}

	if ( !this->PortOne.Is_healthy && !this->PortTwo.Is_healthy ) {
		syslog(LOG_ERR,"RDE_Agent: Both Controllers FAULT on Node.  Waiting for AMF to take the recovery action");
		this->initiateFailover = TRUE;
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::checkAvailableDataDisks()
{
	FILE *p_fd;
	ACE_TCHAR line[80];
	ACE_TCHAR buff1[10],buff2[10],buff3[10],buff4[10];
	ACE_TCHAR command_string[CMD_LEN];

	line[0]='\0';
	syslog(LOG_INFO ,"RDE_Agent: Checking Available Data Disks");

	/* Reset both disk status to FALSE */
	this->PortOne.disk.Is_healthy = FALSE ;
	this->PortTwo.disk.Is_healthy = FALSE ;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --list-port-disk");

	p_fd = popen (command_string,"r");
	if ( p_fd == NULL ){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			//if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: Counter NULL data found");
			break; // from outer while
		}
		if (ACE_OS::strstr(line ,"PORT1:") != NULL){
			sscanf(line ,"%s %s", buff1 ,buff2);
			if (ACE_OS::strcmp(buff2 ,"null") != 0){
				memcpy(PortOne.disk.diskname, buff2,strlen(buff2)+1);
				this->PortOne.disk.Is_healthy = TRUE;
			}
		}

		if (ACE_OS::strstr(line ,"PORT2:") != NULL){
			sscanf(line ,"%s %s", buff3 ,buff4);
			if (ACE_OS::strcmp(buff4 ,"null") != 0){
				memcpy(PortTwo.disk.diskname, buff4,strlen(buff4)+1);
				this->PortTwo.disk.Is_healthy = TRUE;
			}
		}
	}//end outer while

	/* If both the disks are not healthy or
	 * not present, reset the node.
	 */

	if ( !this->PortOne.disk.Is_healthy && !this->PortTwo.disk.Is_healthy ) {
		syslog(LOG_ERR,"RDE_Agent: Found both Disks are FAULTY. Waiting for AMF to take the recovery action");
		this->initiateFailover = TRUE;
		pclose(p_fd);
		return ACS_APGCC_FAILURE;
	}

	if (this->PortOne.disk.Is_healthy){
		syslog(LOG_INFO ,"RDE_Agent: Disk [%s] Found Healthy", this->PortOne.disk.diskname);
	}
	if (this->PortTwo.disk.Is_healthy){
		syslog(LOG_INFO ,"RDE_Agent: Disk [%s] Found Healthy", this->PortTwo.disk.diskname);
	}

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"RDE_Agent: Error in popen exit. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}
	return ACS_APGCC_SUCCESS ;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::updateDatadisksWithRaidDisks()
{
	FILE *p_fd;
	ACE_TCHAR line[80];
	ACE_TCHAR buff1[50],buff2[50],buff3[50],buff4[50];
	ACE_TCHAR command_string[CMD_LEN];

	line[0]='\0';
	syslog(LOG_INFO ,"RDE_Agent: Checking Available Data Disks from the RAID Array");

	/* Reset both disk status to FALSE */
	this->PortOne.disk.Is_healthy = FALSE ;
	this->PortTwo.disk.Is_healthy = FALSE ;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --list-raid-disks");

	p_fd = popen (command_string,"r");
	if ( p_fd == NULL ){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		buff1[0]='\0';
		buff2[0]='\0';
		buff3[0]='\0';
		buff4[0]='\0';
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			//if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: Counter NULL data found");
			break; // from outer while
		}
		if (ACE_OS::strstr(line ,"DISK1:") != NULL){
			sscanf(line ,"%s %s %s %s", buff1 ,buff2, buff3,buff4);
			/* syslog(LOG_INFO, "RDE_Agent: buff1[%s], buff2[%s], buff3[%s], buff4[%s]", buff1 ,buff2, buff3,buff4); */
			if ( (ACE_OS::strcmp(buff4,"active") == 0) || (ACE_OS::strcmp(buff4,"spare") == 0) ){
				memcpy(this->PortOne.disk.diskname, buff2,strlen(buff2)+1);
				this->PortOne.disk.Is_healthy = TRUE;
			}
			continue;
		}

		if (ACE_OS::strstr(line ,"DISK2:") != NULL){
			sscanf(line ,"%s %s %s %s", buff1 ,buff2, buff3,buff4);
			/* syslog(LOG_INFO, "RDE_Agent: buff1[%s], buff2[%s], buff3[%s], buff4[%s]", buff1 ,buff2, buff3,buff4); */
			if ( (ACE_OS::strcmp(buff4,"active") == 0) || (ACE_OS::strcmp(buff4,"spare") == 0) ){
				memcpy(this->PortTwo.disk.diskname, buff2,strlen(buff2)+1);
				this->PortTwo.disk.Is_healthy = TRUE;
			}
		}
	} // enof outer while


	/* If both the disks are not healthy or
	 * not present, Initiate node reboot.
	 */

	if ( !this->PortOne.disk.Is_healthy && !this->PortTwo.disk.Is_healthy ) {
		syslog(LOG_ERR,"RDE_Agent: Found both Disks are FAULTY. Initiating Component Failover...");
		InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
		pclose(p_fd);
		return ACS_APGCC_FAILURE;
	}

	/* Verify disk1 sanity */
	if (!this->PortOne.disk.Is_healthy && this->PortOne.disk.Is_reserved){
		/* RAID is running in degraded Mode. PortOne disk seems to be
		 * not added into the RAID array. Release the current reservation.
		 */
		if (releaseDataDiskReservation(this->PortOne.disk.diskname) != ACS_APGCC_SUCCESS){
			syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk [ %s ]",this->PortOne.disk.diskname);
		}
		this->PortOne.disk.Is_reserved = FALSE;
	}

	if (this->PortOne.disk.Is_healthy && !this->PortOne.disk.Is_reserved){
		/* Degarded disk is now added into the RAID arry.
		 * Try reserving the disk.
		 */
		if (reserveDatadisk(this->PortOne.disk.diskname) != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR ,"RDE_Agent: Reservation on Data disk [%s] FAILED",this->PortOne.disk.diskname);
		}
		else
			this->PortOne.disk.Is_reserved = TRUE;
	}

	/* Verify disk2 sanity */
	if (!this->PortTwo.disk.Is_healthy && this->PortTwo.disk.Is_reserved){
		/* RAID is running in degraded Mode. PortTwo disk seems to be
		 * not added into the RAID array. Release the current reservation.
		 */
		if (releaseDataDiskReservation(this->PortTwo.disk.diskname) != ACS_APGCC_SUCCESS){
			syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk [ %s ]",this->PortTwo.disk.diskname);
		}
		this->PortTwo.disk.Is_reserved = FALSE;
	}

	if (this->PortTwo.disk.Is_healthy && !this->PortTwo.disk.Is_reserved){
		/* Degarded disk is now added into the RAID arry.
		 * Try reserving the disk.
		 */
		if (reserveDatadisk(this->PortTwo.disk.diskname) != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR ,"RDE_Agent: Reservation on Data disk [%s] FAILED",this->PortTwo.disk.diskname);
		}
		else
			this->PortTwo.disk.Is_reserved = TRUE;
	}

	if (this->PortOne.disk.Is_healthy){
		syslog(LOG_INFO ,"RDE_Agent: Disk [%s] Found Healthy", this->PortOne.disk.diskname);
	}
	if (this->PortTwo.disk.Is_healthy){
		syslog(LOG_INFO ,"RDE_Agent: Disk [%s] Found Healthy", this->PortTwo.disk.diskname);
	}

	/* If both the disks are healthy and atleast one of the disk is
	 * not reserved, LOCK the node
	 */

	if ( !this->PortOne.disk.Is_reserved && !this->PortTwo.disk.Is_reserved ) {
		syslog(LOG_ERR,"RDE_Agent: Found both Disks are Not RESERVED. Initiating Component Failover...");
		InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
		pclose(p_fd);
		return ACS_APGCC_FAILURE;
	}

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"RDE_Agent: Error in popen exit. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}
	return ACS_APGCC_SUCCESS ;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::renewDatadiskRegistrations()
{
	logCounter++; // increment log disk registration success msg counter
	if( registerReachableDataDisks() != ACS_APGCC_SUCCESS ){
		/* disk registration renewal failed.
		 * send the error report with the recommend recovery
		 * action NODE FAILOVER before we go down
		 */
		syslog(LOG_INFO, "RDE_Agent: disk registration renewal FAILED. Initiating Node Failover");
		InitiateFailover(ACS_APGCC_NODE_FAILOVER);
		return ACS_APGCC_FAILURE;
	}

	if (logCounter >= 30 ) /* Reset the counter if it reaches 15, 1 min */
		logCounter=0;
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::registerDataDisk(ACE_TCHAR* diskname)
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --register-renew-datadisk %s",diskname);
	errorCode = launchCommand(command_string);
	if ( errorCode == ACS_APGCC_FAILURE ) {
		//syslog (LOG_ERR,"RDE_Agent: Data disk [%s] registration failed" ,diskname);
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::reserveDatadisk(ACE_TCHAR* diskname)
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;
	ACE_INT32 diskResCounter=0;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD"  --reserve-datadisk  %s",diskname);
	while (diskResCounter != MAX_ATTEMPTS){
		/* disk reservation*/
		syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to reserve disk:[%s]", diskResCounter+1, diskname);

		errorCode = launchCommand(command_string);
		if (errorCode == ACS_APGCC_FAILURE) {
			//syslog (LOG_ERR,"RDE_Agent: Data disk [%s] reservation failed" ,diskname);
			diskResCounter++;
			msec_sleep(1000); // sleep for a sec before the next attempt
		}
		else {
			/* disk reservation success */
			syslog (LOG_INFO,"RDE_Agent: Data disk [%s] reservation SUCCESS" ,diskname);
			return ACS_APGCC_SUCCESS;
		}
	}
	return ACS_APGCC_FAILURE;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::dataDiskReservationAlgo()
{
	ACS_APGCC_ReturnType errorCode;
	ACS_APGCC_BOOL counterChanged=FALSE;
	ACE_INT32 Index=0;

	/* Mate node is up and updating the counter. There are two UCs to handle
	 * 1. Mate node is up and healty - In this case current node need reset
	 * 2. Mate node is up and not healthy (hardware fault) - In this case current
	 * 		node have to take up ACTIVE assignment, as the Mate node eventually
	 * 		be reset by APBM.
	 */
	/* reserve disk1 */
	if (this->PortOne.disk.Is_healthy == TRUE && this->PortOne.disk.Is_registered == TRUE) {
		while(Index != (MAX_ATTEMPTS+4)) { // check for 7 iterations with 3 second window between each.
			counterChanged=FALSE;
			if ((errorCode = reserveDatadisk(PortOne.disk.diskname )) != ACS_APGCC_SUCCESS){
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to check PR counter on disk[%s]", Index+1, PortOne.disk.diskname);
				if ((errorCode = checkDiskPRGenerationCounter(this->PortOne.disk.diskname, counterChanged)) != ACS_APGCC_SUCCESS) {
					counterChanged=FALSE;
					if (Index == (MAX_ATTEMPTS+4)) reserveDatadisk(PortOne.disk.diskname ); // dead code, shall be removed
				}else if (counterChanged == FALSE) { break;
				}else { syslog(LOG_INFO, "RDE_Agent: Found counter change on disk[%s], trying again...", this->PortOne.disk.diskname); }
			}else { this->PortOne.disk.Is_reserved=TRUE; break; }
			Index++;
			msec_sleep(3000);
		} //end of while
		if (errorCode != ACS_APGCC_SUCCESS) {
			syslog(LOG_ERR,"RDE_Agent: Error! Checking PR Generation Counter FAILED!");
			return ACS_APGCC_FAILURE;
		}else if (counterChanged) {
			syslog(LOG_INFO, "RDE_Agent: split-brain case, temporary network failure detected, resetting the node to recover");
			return ACS_APGCC_FAILURE ;
		}
	}

	if (this->PortOne.disk.Is_healthy == TRUE && counterChanged == FALSE && 
			this->PortOne.disk.Is_reserved == FALSE) {
		/* Ok. Counter not changed, Other node might be dead. Try Preempting the resevation */
		syslog(LOG_INFO, "RDE_Agent: No Change in PR Generation Counter. Going for PreemptDisk");
		if ((errorCode = preemptDataDisk(this->PortOne.disk.diskname)) != ACS_APGCC_SUCCESS) {
			syslog(LOG_ERR,"RDE_Agent: Error! Preempt Disk [ %s ] failed. Nothing to fall back on",this->PortOne.disk.diskname);
			return ACS_APGCC_FAILURE ;
		}else { this->PortOne.disk.Is_reserved=TRUE; }
	}

	/* reset counterChange flag */
	counterChanged = FALSE;
	Index=0;
	if (this->PortTwo.disk.Is_healthy == TRUE && this->PortTwo.disk.Is_registered == TRUE) {
		/* reserve disk2 */
		while(Index != (MAX_ATTEMPTS+4)) { // check for 7 iterations with 3 second window between each.
			counterChanged=FALSE;
			if ((errorCode = reserveDatadisk(PortTwo.disk.diskname )) != ACS_APGCC_SUCCESS) {
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to check PR counter on disk[%s]", Index+1, PortTwo.disk.diskname);
				if ((errorCode = checkDiskPRGenerationCounter(this->PortTwo.disk.diskname, counterChanged)) != ACS_APGCC_SUCCESS) {
					counterChanged=FALSE;
					if (Index == (MAX_ATTEMPTS+4)) reserveDatadisk(PortOne.disk.diskname ); // dead code, shall be removed
				}else if (counterChanged == FALSE) { break;
				}else { syslog(LOG_INFO, "RDE_Agent: Found counter change on disk[%s], trying again...", this->PortTwo.disk.diskname); }
			}else { this->PortTwo.disk.Is_reserved=TRUE; break; }
			Index++;
			msec_sleep(3000);
		} //end of while
		if (errorCode != ACS_APGCC_SUCCESS) { syslog(LOG_ERR,"RDE_Agent: Error! Checking PR Generation Counter FAILED!"); }
		if (counterChanged) { syslog(LOG_ERR, "RDE_Agent: MATE node is up and healthy"); } // mate node is working with disk2 only
		if (counterChanged || (errorCode != ACS_APGCC_SUCCESS)) {
			if (this->PortOne.disk.Is_reserved) {
				this->PortOne.disk.Is_reserved=FALSE;
				syslog(LOG_INFO, "RDE_Agent: releasing disk[%s] reservations", this->PortOne.disk.diskname);
				if ((errorCode = releaseDataDiskReservation(this->PortOne.disk.diskname)) != ACS_APGCC_SUCCESS) {
					syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk[%s]",this->PortOne.disk.diskname);
				}
			}
			return ACS_APGCC_FAILURE;
		}
	}

	if (this->PortTwo.disk.Is_healthy == TRUE && counterChanged == FALSE && 
			this->PortTwo.disk.Is_reserved == FALSE) {
		/* Ok. Counter not changed, Other node might be dead. Try Preempting the resevation */
		syslog(LOG_INFO, "RDE_Agent: No Change in PR Generation Counter. Going for PreemptDisk");
		if ((errorCode = preemptDataDisk(PortTwo.disk.diskname)) != ACS_APGCC_SUCCESS ) {
			syslog(LOG_ERR,"RDE_Agent: Error! Preempt Disk [ %s ] failed. Nothing to fall back on",this->PortTwo.disk.diskname);
			if (this->PortOne.disk.Is_reserved){
				this->PortOne.disk.Is_reserved=FALSE;
				syslog(LOG_INFO, "RDE_Agent: releasing disk[%s] reservations", this->PortOne.disk.diskname);
				if ((errorCode = releaseDataDiskReservation(this->PortOne.disk.diskname)) != ACS_APGCC_SUCCESS) {
					syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk [ %s ]",this->PortOne.disk.diskname);
				}
			}
			return ACS_APGCC_FAILURE ;
		}else { this->PortTwo.disk.Is_reserved=TRUE; }
	}

	if (!this->PortOne.disk.Is_reserved && !this->PortTwo.disk.Is_reserved) {
		syslog(LOG_ERR, "RDE_Agent: Error! Both disks are not reserved.");
		return ACS_APGCC_FAILURE ;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::checkDiskPRGenerationCounter(ACE_TCHAR* diskname, ACS_APGCC_BOOL &counterChanged)
{
	ACE_TCHAR command_string[CMD_LEN];
	ACE_UINT32 frstPRGenKey = 0;
	ACE_UINT32 nextPRGenKey = 0;
	ACE_INT32 status;
	ACE_INT32 Len;
	FILE *p_fd;
	char line[25]={0};
	char buff[25]={0};

	counterChanged=TRUE;
	ACE_OS::memset(command_string, 0, CMD_LEN);
	ACE_OS::snprintf(command_string, CMD_LEN, SCSI_BASE_CMD" --query-generation-key %s", diskname);

	ACS_APGCC_BOOL spike_raised = FALSE;
	ACS_APGCC_BOOL break_for_nextlaunch=FALSE;
	ACE_UINT32 iterations = 0;

	for (ACE_UINT32 i = 0; i < (this->X_Times * 2); i++) {
		// Sending the command
		p_fd = popen(command_string,"r");
		if (p_fd == NULL) {
			syslog(LOG_ERR, "RDE_Agent: popen error to launch [%s]", command_string);
			return ACS_APGCC_FAILURE;
		}

		//  Collect the counter
		while (!feof(p_fd)) {
			ACE_INT32 attemp_count=0;
			while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
				if (attemp_count++ > 10 ) break; // from inner while
				continue;
			} // inner while
			if (line[0] == '\0'){
				syslog(LOG_ERR, "RDE_Agent: Counter NULL data found");
				break_for_nextlaunch=TRUE;
				break; // from outer while
			}
			sscanf(line,"%s",buff);
		}//end outer while
		if (break_for_nextlaunch) {
			syslog(LOG_ERR, "regisrations released from the other node, going with new registrations");
			return ACS_APGCC_FAILURE;
		}	
		Len = ACE_OS::strlen(buff);
		if (Len > 0) {
			iterations++;
			nextPRGenKey = atoi(buff);
			if (i == 0) { /* first iteration */
				frstPRGenKey = nextPRGenKey;
			}
		} else {
			syslog(LOG_ERR, "RDE_Agent: Error in counter collection.");
			pclose(p_fd);
			return ACS_APGCC_FAILURE;
		}

		//Close the file descriptor
		status = pclose(p_fd);
		if (WIFEXITED(status)){
			if ((status = WEXITSTATUS(status)) != 0) {
				/* apos_ha_scsi_operations: we return NULL key here if not found.
				 * this null key need to be handled to reserver the disk again
				 */
				syslog(LOG_INFO, "RDE_Agent: PR generation key not found, going for register/reservation again");
				return ACS_APGCC_FAILURE;
			}
		}

		// Check the counter
		if (frstPRGenKey != nextPRGenKey) {
			if (!spike_raised) {
				spike_raised = TRUE;
				iterations = 0;
				frstPRGenKey = nextPRGenKey;
			} else {
				break;  //2 spikes in the same inspection window
			}
		}

		// Check the iteration
		if (iterations == this->X_Times) {
			counterChanged = FALSE;
			break;  //X_Times iterations reached without change in the counter
		}
		// Sleep for Y milli seconds
		msec_sleep(this->Y_Msecs);
	}  //end for
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::releaseDataDiskReservation(ACE_TCHAR* diskname) {

	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --release-reservations %s",diskname);
	errorCode = launchCommand(command_string);
	if (errorCode == ACS_APGCC_FAILURE) {
		//syslog (LOG_ERR,"RDE_Agent: Data disk [%s] release failed" ,diskname);
		return ACS_APGCC_FAILURE;
	}

	syslog (LOG_INFO,"RDE_Agent: Data disk [%s] release success" ,diskname);
	return ACS_APGCC_SUCCESS;
}


//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::releaseDataDiskRegistrations(ACE_TCHAR* diskname)
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --unreg-datadisk %s",diskname);
	errorCode = launchCommand(command_string);
	if (errorCode == ACS_APGCC_FAILURE) {
		return ACS_APGCC_FAILURE;
	}

	syslog (LOG_INFO,"RDE_Agent: Data disk [%s] unregister success" ,diskname);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::preemptDataDisk (ACE_TCHAR* diskname)
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,SCSI_BASE_CMD" --preempt-disk  %s",diskname);
	errorCode = launchCommand(command_string);
	if (errorCode == ACS_APGCC_FAILURE) {
		syslog (LOG_ERR,"RDE_Agent: Data disk [%s] preempt Failed" ,diskname);
		return ACS_APGCC_FAILURE;
	}
	syslog (LOG_INFO,"RDE_Agent: Data disk [%s] preempt success" ,diskname);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::msec_sleep(ACE_INT32 time_in_msec)
{
	struct timeval tv;
	tv.tv_sec = time_in_msec / 1000;
	tv.tv_usec = ((time_in_msec) % 1000) * 1000;

	while (select(0, 0, 0, 0, &tv) != 0)
		if (errno == EINTR)
			continue;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::mountRAIDandActivateMIPs(ACS_APGCC_BOOL OnStart)
{
	/* Mount RAID Using APOS script raidmgmt
	 * Check for the MIP status. If it is already
	 * configured then do nothing, else Configure MIP
	 */

	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	if (this->IsRAIDConfigured == TRUE) {
		syslog(LOG_INFO, "RDE_Agent: Configure RAID already done");
	}
	else {
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN,DISK_MGMT_CMD " --assemble --mount --force");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: RAID Config on Active Node FAILED.Initiating Failover...");
			InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
			return ACS_APGCC_FAILURE;
		}

		this->IsRAIDConfigured=TRUE;
		syslog(LOG_INFO ,"RDE_Agent: Mount and Configure RAID Success!");
	}

	/* Activate MIPs and do necessary actions*/
	if (this->IsMIPConfigured == TRUE){
		syslog(LOG_INFO, "RDE_Agent: Configure MIP already done");
	}
	else {
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		if (OnStart == TRUE)
			ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -s");
		else
			ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -f passive");

		errorCode = launchCommand(command_string);
		if (errorCode == 1) {
			syslog (LOG_ERR,"RDE_Agent: MIP Activate FAILED on Active Node");
			return ACS_APGCC_FAILURE; 
		}
		this->IsMIPConfigured = TRUE;
		syslog(LOG_INFO ,"RDE_Agent: Activating MIP Success on Active Node");
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::setNodeId()
{
	FILE* fp;
	ACE_TCHAR buff[10];

	fp = ACE_OS::fopen(NODE_ID_FILE,"r");
	if (fp == NULL) {
		syslog(LOG_ERR,"RDE_Agent: Error! fopen FAILED");
		return ACS_APGCC_FAILURE;
	}

	if (fscanf(fp ,"%s" ,buff) != 1) {
		(void)fclose(fp);
		syslog(LOG_ERR ,"RDE_Agent: Unable to Retreive the node id from file [ %s ]" ,NODE_ID_FILE);
		return ACS_APGCC_FAILURE;
	}

	if (ACE_OS::fclose(fp) != 0) {
		syslog(LOG_ERR ,"RDE_Agent: Error! fclose FAILED");
		return ACS_APGCC_FAILURE;
	}

	this->node_id= ACE_OS::atoi(buff);
	syslog(LOG_INFO ,"RDE_Agent: Running on NODE:%d",this->node_id);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::updateDiskStatusFile()
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode=ACS_APGCC_SUCCESS;

	/*Update disk_status file */
	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --update-diskstatus");
	errorCode = launchCommand(command_string);
	if (errorCode == ACS_APGCC_FAILURE) {
		syslog (LOG_ERR,"RDE_Agent: Updating disk_status file FAILED on Active Node");
		return ACS_APGCC_FAILURE;
	}
	syslog(LOG_INFO, "RDE_Agent: disk_status file updated Successfully");
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::setGepId()
{
	ACE_TCHAR line[25],buff[20];
	FILE *p_fd;
	line[0]='\0';
	p_fd = popen (GEP_HWTYPE,"r");
	if (p_fd == NULL){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,GEP_HWTYPE);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			//if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: NULL data found");
			break; // from outer while
		}
		sscanf(line,"%s",buff);
	}//end outer while

	if (ACE_OS::strcmp(buff ,GEP1STRING) == 0){
		this->gep_id=GEP_ONE;
	}

	if (ACE_OS::strcmp(buff ,GEP2STRING) == 0){
		this->gep_id=GEP_TWO;
	}

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"RDE_Agent: Error in popen close. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}
	syslog(LOG_INFO ,"RDE_Agent: Running on :GEP%d",this->gep_id);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACE_INT32 APGHA_RDEAgent::getNodeId() const
{
	return this->node_id;
}

//-----------------------------------------------------------------------------
ACE_INT32 APGHA_RDEAgent::getGepId() const
{
	return this->gep_id;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::updatePortStatus(APGHA_NodeT *Node, ACE_UINT32 node_id)
{
	FILE* fp;
	ACE_TCHAR buff[80],buff1[20],buff2[20],buff3[20],buff4[20],buff5[20],line[25];

	FILE *p_fd;
	line[0]='\0';
	p_fd = popen (STORAGE_FIND_PATH,"r");
	if (p_fd == NULL){
		syslog(LOG_ERR, "RDE_Agent: popen error to lanuch [%s]" ,STORAGE_FIND_PATH);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading file. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while

		if (line[0] == '\0'){
			syslog(LOG_ERR, "RDE_Agent: NULL data found");
			break; // from outer while
		}
		sscanf(line,"%s",buff5);
	}//end outer while


	ACE_TCHAR command_string[CMD_LEN];
	string disk_status_path;
	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,"/ha/nodes/%d/disk_status", node_id);
	ACE_OS::strcat(buff5,command_string);
	disk_status_path = buff5;
	syslog(LOG_INFO, "RDE_Agent: disk_status path = [%s]" ,disk_status_path.c_str());

	fp = ACE_OS::fopen(disk_status_path.c_str(), "r");
	if (fp == NULL) {
		syslog(LOG_ERR,"RDE_Agent: Error! fopen FAILED to read [ %s ]",disk_status_path.c_str());
		fclose(p_fd);
		return ACS_APGCC_FAILURE;
	}

	while(ACE_OS::fgets(buff, 80, fp)!= NULL){
		if (ACE_OS::strstr(buff, "PORT1:") != NULL){
			sscanf(buff, "%s %s %s %s",buff1,buff2,buff3,buff4);
			if (ACE_OS::strcmp(buff2,"healthy") == 0)
				Node->PortOne.Is_healthy=TRUE;
			else
				Node->PortOne.Is_healthy=FALSE;

			if (ACE_OS::strcmp(buff4, "null") != 0){
				strncpy(Node->PortOne.disk.diskname, buff4, strlen(buff4));
				Node->PortOne.disk.Is_healthy=TRUE;
			}
			else
				Node->PortOne.disk.Is_healthy=FALSE;

		}

		if (ACE_OS::strstr(buff, "PORT2:") != NULL){
			if (ACE_OS::strcmp(buff2,"healthy") == 0)
				Node->PortTwo.Is_healthy=TRUE;
			else
				Node->PortTwo.Is_healthy=FALSE;
			if (ACE_OS::strcmp(buff4, "null") != 0){
				strncpy(Node->PortTwo.disk.diskname, buff4, strlen(buff4));
				Node->PortTwo.disk.Is_healthy=TRUE;
			}
			else
				Node->PortTwo.disk.Is_healthy=FALSE;
		}
	} /* end of while */
	fclose(p_fd);
	fclose(fp);
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::updateBothNodeDisknControllerstatus()
{
	if (getNodeId() == NODE_ONE){
		/* Fill NodeA details */
		NodeA.PortOne.Is_healthy = this->PortOne.Is_healthy;
		NodeA.PortOne.disk.Is_healthy = this->PortOne.disk.Is_healthy;
		strncpy(NodeA.PortOne.disk.diskname,PortOne.disk.diskname,sizeof(PortOne.disk.diskname));

		NodeA.PortTwo.Is_healthy = this->PortTwo.Is_healthy;
		NodeA.PortTwo.disk.Is_healthy = this->PortTwo.disk.Is_healthy;
		strncpy(NodeA.PortTwo.disk.diskname,PortTwo.disk.diskname,sizeof(PortTwo.disk.diskname));

		/* Fill NodeB details */
		/* open ddisk status to read NodeB status*/
		if (updatePortStatus(&this->NodeB, NODE_ONE) != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: Updating NodeB Port and disk Status Failed");
			return ACS_APGCC_FAILURE;
		}
	}

	if (getNodeId() == NODE_TWO){
		/* Fill NodeB details */
		NodeB.PortOne.Is_healthy = this->PortOne.Is_healthy;
		NodeB.PortOne.disk.Is_healthy = this->PortOne.disk.Is_healthy;
		strncpy(NodeB.PortOne.disk.diskname,PortOne.disk.diskname,sizeof(PortOne.disk.diskname));

		NodeB.PortTwo.Is_healthy = this->PortTwo.Is_healthy;
		NodeB.PortTwo.disk.Is_healthy = this->PortTwo.disk.Is_healthy;
		strncpy(NodeB.PortTwo.disk.diskname,PortTwo.disk.diskname,sizeof(PortTwo.disk.diskname));

		/* Fill NodeA details */
		/* open ddisk status to read NodeA status*/
		if (updatePortStatus(&this->NodeA, NODE_TWO) != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: Updating NodeB Port and disk Status Failed");
			return ACS_APGCC_FAILURE;
		}
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::updateDeviceStatus()
{
	ACS_APGCC_ReturnType errorCode=ACS_APGCC_SUCCESS;
	if (update_datadisk_info == TRUE){
		update_datadisk_info=FALSE;
		if (checkSCSIControllerStatus() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR ,"RDE_Agent: Error! Checking the Controller status");
			errorCode=ACS_APGCC_FAILURE;
		}

		if (checkAvailableDataDisks() != ACS_APGCC_SUCCESS) {
			syslog(LOG_ERR ,"RDE_Agent: Error! Checking available data disks");
			errorCode=ACS_APGCC_FAILURE;
		}

		/* Reset the counter to get the printout */
		logCounter=0;
		if (renewDatadiskRegistrations() != ACS_APGCC_SUCCESS) {
			syslog(LOG_ERR ,"RDE_Agent: Error! renewDatadiskRegistrations FAILED");
			errorCode=ACS_APGCC_FAILURE;
		}
		if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR ,"RDE_Agent: Error! updating both node disk/controller status");
			errorCode=ACS_APGCC_FAILURE;
		}
	}

	if (update_raid_info == TRUE){
		update_raid_info=FALSE;
		if (!IsDebug) {
			if (getHAState() == ACS_APGCC_AMF_HA_ACTIVE) {
				if (this->IsRAIDConfigured == TRUE){
					if (updateDatadisksWithRaidDisks() != ACS_APGCC_SUCCESS) {
						syslog(LOG_ERR ,"RDE_Agent: Error! Checking available data disks");
						return ACS_APGCC_FAILURE;
					}
				}
				else {
					syslog(LOG_INFO, "RDE_Agent: Ignoring updateDatadisksWithRaidDisks as RAID is not yet mounted");
				}

				if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS ){
					syslog(LOG_ERR ,"RDE_Agent: Error! updating both node disk/controller status");
					return ACS_APGCC_FAILURE;
				}
			}
			else {
				/* This should not happen as raid is not mounted on Passive node.
				 * Ignore the request and write to syslog
				 */
				syslog(LOG_INFO, "RDE_Agent: UpdateDatadisksWithRaidDisks success");
			}
		}else if (!this->Is_Agent_Stanby) {
			if (this->IsRAIDConfigured == TRUE){
				if (updateDatadisksWithRaidDisks() != ACS_APGCC_SUCCESS) {
					syslog(LOG_ERR ,"RDE_Agent: Error! Checking available data disks");
					return ACS_APGCC_FAILURE;
				}
				else {
					syslog(LOG_INFO, "RDE_Agent: UpdateDatadisksWithRaidDisks success ");
				}
				if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS ){
					syslog(LOG_ERR ,"RDE_Agent: Error! updating both node disk/controller status");
					return ACS_APGCC_FAILURE;
				}
			}
		}
		return ACS_APGCC_SUCCESS;
	}
	return errorCode;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::releaseBothDatadiskReservations()
{
	ACS_APGCC_ReturnType errorCode=ACS_APGCC_SUCCESS;
	syslog(LOG_INFO, "RDE_Agent: release reservations made if any.");
	if ( this->PortOne.disk.Is_healthy == TRUE && this->PortOne.disk.Is_reserved == TRUE) {
		/* release disk1 */
		if ( (errorCode = releaseDataDiskReservation(this->PortOne.disk.diskname)) != ACS_APGCC_SUCCESS ) {
			syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk [ %s ]",this->PortOne.disk.diskname);
			return ACS_APGCC_FAILURE;
		}
		this->PortOne.disk.Is_reserved = FALSE;
	}

	if (this->PortTwo.disk.Is_healthy == TRUE && this->PortTwo.disk.Is_reserved == TRUE) {
		/* release disk2 */
		if ( (errorCode = releaseDataDiskReservation(this->PortTwo.disk.diskname)) != ACS_APGCC_SUCCESS ) {
			syslog( LOG_ERR,"RDE_Agent: Error! release reservation failed on disk [ %s ]",this->PortTwo.disk.diskname);
			return ACS_APGCC_FAILURE;
		}
		this->PortTwo.disk.Is_reserved = FALSE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::releaseBothDatadiskRegistrations()
{
	ACS_APGCC_ReturnType errorCode;
	ACE_INT32 diskRegCounter=1;
	const ACE_INT32 L_MAX_ATTEMPTS=5;

	syslog(LOG_INFO, "RDE_Agent: releaseBothDatadiskRegistrations invoked");

	// un-register first disk registration.
	if (this->PortOne.disk.Is_registered == TRUE){
		while (diskRegCounter != L_MAX_ATTEMPTS){
			if ( (errorCode = releaseDataDiskRegistrations(this->PortOne.disk.diskname )) != ACS_APGCC_SUCCESS ) {
				syslog(LOG_ERR,"RDE_Agent: Release Data Disk Registration FAILED on data disk [%s]" ,this->PortOne.disk.diskname);
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to Release registered disk:[%s]", diskRegCounter+1, this->PortOne.disk.diskname);
				diskRegCounter++;

				//If diskA Reservation not released
				if ( this->PortOne.disk.Is_healthy == TRUE && this->PortOne.disk.Is_reserved == TRUE) {
					/* release disk1 */
					if ( (errorCode = releaseDataDiskReservation(this->PortOne.disk.diskname)) != ACS_APGCC_SUCCESS ) {
						syslog( LOG_ERR,"RDE_Agent: Error! Registration-release reservation failed on disk [ %s ]",this->PortOne.disk.diskname);
					}
					this->PortOne.disk.Is_reserved = FALSE;
				}

				msec_sleep(1000); // sleep for a sec before the next attempt
			} else {
				syslog(LOG_INFO, "RDE_Agent: disk registration-release Success");
				this->PortOne.disk.Is_registered = FALSE;
				break;
			}
		}
	}

	// un-register second disk registration.
	diskRegCounter=1;
	if (this->PortTwo.disk.Is_registered == TRUE){
		while (diskRegCounter != L_MAX_ATTEMPTS){
			if ( (errorCode = releaseDataDiskRegistrations(this->PortTwo.disk.diskname )) != ACS_APGCC_SUCCESS ) {
				syslog(LOG_ERR,"RDE_Agent: Release Data Disk Registration FAILED on data disk [%s]" ,this->PortTwo.disk.diskname);
				syslog(LOG_INFO, "RDE_Agent: Attempt #[%d] to Release registered disk:[%s]", diskRegCounter+1, this->PortTwo.disk.diskname);
				diskRegCounter++;

				//If diskB Reservation not released
				if (this->PortTwo.disk.Is_healthy == TRUE && this->PortTwo.disk.Is_reserved == TRUE) {
					/* release disk2 */
					if ( (errorCode = releaseDataDiskReservation(this->PortTwo.disk.diskname)) != ACS_APGCC_SUCCESS ) {
						syslog( LOG_ERR,"RDE_Agent: Error! Registration-release reservation failed on disk [ %s ]",this->PortTwo.disk.diskname);
					}
					this->PortTwo.disk.Is_reserved = FALSE;
				}
				msec_sleep(1000); // sleep for a sec before the next attempt
			} else {
				syslog(LOG_INFO, "RDE_Agent: disk registration-release Success");
				this->PortTwo.disk.Is_registered = FALSE;
				break;
			}
		}
	}

	/* make sure atleast we can work with One disk being active */
	if ( !(this->PortOne.disk.Is_registered == FALSE) && !(this->PortTwo.disk.Is_registered == FALSE) )
		return ACS_APGCC_FAILURE;

	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::umountRAIDandDeactivateMIPs()
{
	/* Deactivate RAID Using APOS script raidmgmt
	 * and unmount Data disks and Deactivate MIPs
	 */
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode=ACS_APGCC_SUCCESS;
	ACS_APGCC_ReturnType rCode=ACS_APGCC_SUCCESS;

	if (this->IsMIPConfigured == FALSE){
		syslog(LOG_INFO, "RDE_Agent: MIP already deactivated");
	}
	else {
		/* Deactivate MIPs */
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -f active");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: MIP Deactivate FAILED on Active Node");
			rCode=ACS_APGCC_FAILURE;
		}
		syslog(LOG_INFO, "RDE_Agent: MIP deactivated Successfully");
	}

	if (this->IsRAIDConfigured == FALSE) {
		syslog(LOG_INFO, "RDE_Agent: RAID already disabled");
	}
	else {
		/* Cleanup Active RAID Users  */
		syslog (LOG_INFO,"RDE_Agent: Cleanup Active RAID Users.");
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " --cleanup");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: Cleanup Active RAID users FAILED");
		}
                msec_sleep(3000); //Sleep for 3 secs
                syslog (LOG_INFO,"RDE_Agent: Disable and unmount raid");

		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN,DISK_MGMT_CMD " --disable --unmount");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: Unmount RAID FAILED");
			rCode=ACS_APGCC_FAILURE;
		}
		else {
			syslog(LOG_INFO ,"RDE_Agent: Umount RAID Success!");
		}
	}
	return rCode;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::handleRdeAgentGracefullDownJobs()
{
	/* handle all gracefull jobs here  */
	if (!this->Is_State_Assgned) {
		syslog(LOG_INFO, "RDE_Agent: No Graceful jobs required, Active assignment not done");
		return ACS_APGCC_SUCCESS;
	}

	if (this->Is_Agent_Stanby){
		syslog(LOG_INFO, "RDE_Agent: STNDBY - No gracefullJobs to be done");
		syslog(LOG_INFO, "RDE_Agent: STNDBY - Success");
		return ACS_APGCC_SUCCESS;
	}

	if (this->handleRdeAgentGracefullDownJobsDone) {
		syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
		return ACS_APGCC_SUCCESS;
	}

	if (this->releaseBothDatadiskReservations() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: release datadisk reservations FAILED");
		return ACS_APGCC_FAILURE;
	}

	if (this->umountRAIDandDeactivateMIPs() != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: unmount and Deactivate MIP FAILED");
		return ACS_APGCC_FAILURE;
	}

	/* handle here if there are any left out jobs */
	this->handleRdeAgentGracefullDownJobsDone=TRUE;
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_BOOL APGHA_RDEAgent::IsActiveStateTransitionAllowed()
{
	/* check for back plane connectivity from tipc topology server */
	ACE_INT32 rnode=0;
	ACS_APGCC_BOOL rCode=TRUE;

	if (getNodeId() == NODE_ONE)
		rnode=NODE_TWO;

	if (getNodeId() == NODE_TWO)
		rnode=NODE_ONE;

	if (tipcObj.query_tipc_topserver(rnode, this->backPlaneUp) != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR,"Failed to Query BackPlane connectivity");
		return FALSE;
	}

	if (debugEnabled) {
		/* print out */
		syslog(LOG_INFO, "NodeA.PortOne.Is_healthy[%d] NodeA.PortOne.disk.Is_healthy[%d] NodeA.PortTwo.Is_healthy[%d] NodeA.PortTwo.disk.Is_healthy[%d]"
				"NodeB.PortOne.Is_healthy[%d] NodeB.PortOne.disk.Is_healthy[%d] NodeB.PortTwo.Is_healthy[%d] NodeB.PortTwo.disk.Is_healthy[%d]",NodeA.PortOne.Is_healthy,
				NodeA.PortOne.disk.Is_healthy,NodeA.PortTwo.Is_healthy,NodeA.PortTwo.disk.Is_healthy,NodeB.PortOne.Is_healthy,NodeB.PortOne.disk.Is_healthy,NodeB.PortTwo.Is_healthy,NodeB.PortTwo.disk.Is_healthy);
	}

	if (this->backPlaneUp) {
		/* populate the latest info of disk status from the disk file */
		if (updateBothNodeDisknControllerstatus() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR ,"RDE_Agent: Error! updating both node disk/controller status");
			rCode=FALSE;
		}

		/* handle disjoint RAID cases first */
		if ((NodeA.PortOne.Is_healthy) && (NodeA.PortOne.disk.Is_healthy) && ( !(NodeA.PortTwo.Is_healthy) || !(NodeA.PortTwo.disk.Is_healthy)) &&
				(!(NodeB.PortOne.Is_healthy) || !(NodeB.PortTwo.Is_healthy)) && (NodeB.PortTwo.disk.Is_healthy) && (NodeB.PortTwo.Is_healthy)) {
			/* This handles the case where NodeA disk1 and controller are healthy and disk2 or controller is dead
			 * and NodeB disk1 or controller is dead and disk2, controller are healthy.
			 */
			rCode=FALSE;
		}

		if ((!(NodeA.PortOne.Is_healthy) || !(NodeA.PortOne.disk.Is_healthy)) && (NodeA.PortTwo.Is_healthy) && (NodeA.PortTwo.disk.Is_healthy) &&
				(NodeB.PortOne.Is_healthy) && (NodeB.PortTwo.disk.Is_healthy) && (!(NodeB.PortTwo.Is_healthy) || !(NodeB.PortTwo.disk.Is_healthy))) {

			/* This handles the case where NodeA disk1 and controller are healthy and disk2 controller is dead
			 * and NodeB disk1 controller is dead and disk2, controller are healthy.
			 */
			rCode=FALSE;
		}

		if (getNodeId() == NODE_ONE) {
			if ((NodeA.PortOne.Is_healthy && !(NodeA.PortOne.disk.Is_healthy)) ||
					(NodeA.PortTwo.Is_healthy && NodeA.PortTwo.disk.Is_healthy)){
				/* This handles the case where port1 is healthy but
				 * disk1 is dead and port2 and disk2 are healthy.
				 * RAID run in degraded mode
				 */
				rCode=TRUE;
			}

			if ((NodeA.PortOne.Is_healthy && NodeA.PortOne.disk.Is_healthy) ||
					(NodeA.PortTwo.Is_healthy && !(NodeA.PortTwo.disk.Is_healthy))){
				/* This handles the case where port1 and disk1
				 * are healthy and port2 is also healthy but disk2 is dead.
				 * RAID run in degraded mode
				 */
				rCode=TRUE;
			}

			if ((NodeA.PortOne.Is_healthy && NodeA.PortOne.disk.Is_healthy) ||
					(NodeA.PortTwo.Is_healthy && NodeA.PortTwo.disk.Is_healthy)){
				/* This handles cases where
				 * Both disks and both controllers are healthy
				 */
				rCode=TRUE;
			}
		}
		if (getNodeId() == NODE_TWO) {
			if ((NodeB.PortOne.Is_healthy && !(NodeB.PortOne.disk.Is_healthy)) ||
					(NodeB.PortTwo.Is_healthy && NodeB.PortTwo.disk.Is_healthy)){
				/* This handles the case where port1 is healthy but
				 * disk1 is dead and port2 and disk2 are healthy.
				 * RAID run in degraded mode
				 */
				rCode=TRUE;
			}

			if ((NodeB.PortOne.Is_healthy && NodeB.PortOne.disk.Is_healthy) ||
					(NodeB.PortTwo.Is_healthy && !(NodeB.PortTwo.disk.Is_healthy))){
				/* This handles the case where port1 and disk1
				 * are healthy and port2 is also healthy but disk2 is dead.
				 * RAID run in degraded mode
				 */
				rCode=TRUE;
			}

			if ((NodeB.PortOne.Is_healthy && NodeB.PortOne.disk.Is_healthy) ||
					(NodeB.PortTwo.Is_healthy && NodeB.PortTwo.disk.Is_healthy)){
				/* This handles the following cases
				 * 1. Both disks and both controllers are healthy
				 * 2. Atleast a disk and controller is healthy, this case
				 * forms degraded raid
				 */
				rCode=TRUE;
			}
		}

	}

	if ( !this->backPlaneUp){
		/* In case of back plane connectivity loss, both disks and controllers must be up and working to take up the active role */
		if (getNodeId() == NODE_ONE) {
			if ( (!(NodeA.PortOne.Is_healthy) || !(NodeA.PortOne.disk.Is_healthy)) &&
					(!(NodeA.PortTwo.Is_healthy) || !(NodeA.PortTwo.disk.Is_healthy)) ) {
				/* This handles the case where both the controllers or the disks are dead of node One */
				syslog(LOG_INFO,"NodeA: Both the controllers or the disks are dead");
				rCode=FALSE;
			}
		}

		if (getNodeId() == NODE_TWO) {
			if ( (!(NodeB.PortOne.Is_healthy) || !(NodeB.PortOne.disk.Is_healthy)) &&
					(!(NodeB.PortTwo.Is_healthy) || !(NodeB.PortTwo.disk.Is_healthy)) ) {
				/* This handles the case where both the controllers or the disks are dead of node One */
				syslog(LOG_INFO, "NodeB: This handles the case where both the controllers or the disks are dead of node One");
				rCode=FALSE;
			}
		}
	}

	if (getNodeId() == NODE_ONE) {
		if ( !(NodeA.PortOne.Is_healthy) && !(NodeA.PortTwo.Is_healthy)){
			/* This handles both controllers are dead case
			 * Eventually disks are also dead
			 */
			syslog(LOG_INFO,"NodeA: This handles both controllers are dead case");
			rCode=FALSE;
		}
		if ( (NodeA.PortOne.Is_healthy && !(NodeA.PortOne.disk.Is_healthy)) &&
				(NodeB.PortTwo.Is_healthy && !(NodeB.PortTwo.disk.Is_healthy))){
			/* This handles the case where both controllers are
			 * healthy but disks are dead.
			 */
			syslog(LOG_INFO,"NodeA: This handles the case where both controllers are healthy but disks are dead.");
			rCode=FALSE;
		}
	}

	if (getNodeId() == NODE_TWO) {
		if ( !(NodeB.PortOne.Is_healthy) && !(NodeB.PortTwo.Is_healthy)){
			/* This handles both controllers are dead case
			 * Eventually disks are also dead
			 */
			syslog(LOG_INFO,"NodeB: This handles both controllers are dead case Eventually disks are also dead");
			rCode=FALSE;
		}
		if ( (NodeB.PortOne.Is_healthy && !(NodeB.PortOne.disk.Is_healthy)) &&
				(NodeB.PortTwo.Is_healthy && !(NodeB.PortTwo.disk.Is_healthy))){
			/* This handles the case where both controllers are
			 * present and healthy but disks are dead.
			 */
			syslog(LOG_INFO,"NodeB: This handles the case where both controllers are present and healthy but disks are dead.");
			rCode=FALSE;
		}
	}

	/* This is the general case where the node is healhty
	 * and ready to take up the Active role.
	 * rCode=TRUE
	 */

	return rCode;
}

//-----------------------------------------------------------------------------
ACE_TCHAR* APGHA_RDEAgent::gettoken(char *str, unsigned char tok)
{
	ACE_TCHAR *p, *q;
	int i=0;

	q=p=strchr(str,tok);
	if (!p)
		return (NULL);
	/* truncate the token from the string */
	p++;

	while ( *p != '\0' ){
		if (isdigit(*p)) {
			q[i]=*p;
			i++;
		}
		else
			break;
		p++;
	}
	q[i]='\0';
	return q;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::readConfig()
{
	FILE* fp;
	ACE_TCHAR buff[100];
	ACE_TCHAR *ch, *ch1, *tmp;

	fp = ACE_OS::fopen(RDAGNT_CONF_FILE, "r");
	if ( fp == NULL ) {
		syslog(LOG_ERR,"RDE_Agent: Error! fopen FAILED to read [ %s ]",RDAGNT_CONF_FILE);
		return ACS_APGCC_FAILURE;
	}

	while(ACE_OS::fgets(buff, sizeof(buff), fp) != NULL)
	{
		/* Skip Comments and tab spaces in the beginning */
		ch = buff;
		while (*ch == ' ' || *ch == '\t')
			ch++;

		if (*ch == '#' || *ch == '\n')
			continue;

		/* In case if we have # somewhere in this line lets truncate the string from there */
		if ((ch1 = ACE_OS::strchr(ch, '#')) != NULL) {
			*ch1++ = '\n';
			*ch1 = '\0';
		}

		if (ACE_OS::strstr(ch, "RDAGNT_X_TIMES=") != NULL){
			tmp=gettoken(ch, '=');
			this->X_Times = ( DEFLT_X_TIMES > atoi(tmp))? DEFLT_X_TIMES : atoi(tmp);
			syslog(LOG_INFO, "RDE_Agent: Setting X_Times to [%d]", this->X_Times);
		}

		if (ACE_OS::strstr(ch, "RDAGNT_Y_MSECS=") != NULL){
			tmp=gettoken(ch, '=');
			this->Y_Msecs = ( DEFLT_Y_MSECS > atoll(tmp))? DEFLT_Y_MSECS : atoll(tmp);
			syslog(LOG_INFO, "RDE_Agent: Setting Y_Msecs to [%llu] from next iteration", (unsigned long long)this->Y_Msecs);
		}

		if (ACE_OS::strstr(ch, "RDAGNT_DISK_RENEWAL_THREAD_FREQUENCY=") != NULL){
			tmp=gettoken(ch, '=');
			this->diskRenewalThreadFreq = ( DEFALT_THREAD_FREQ  > atoll(tmp))? DEFALT_THREAD_FREQ : atoll(tmp);
			this->diskRenewalThreadFreq = (ACE_UINT64)(this->diskRenewalThreadFreq/1000);
			syslog(LOG_INFO, "RDE_Agent: Setting Disk renewal thread frequency to [%llu]", (unsigned long long)this->diskRenewalThreadFreq);
		}

	} /* end of while */

	if ( ACE_OS::fclose(fp) != 0) {
		syslog(LOG_ERR, "RDE_Agent: Error! fclose FAILED");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::iTimerInit()
{
	struct sigaction sa;
	struct itimerval timer;

	__time_t secs = 2;
	__suseconds_t usecs = 0;

	/* Create selection Object */
	if (utils.sel_obj_create(&iTimer_sel_obj) != ACS_APGCC_SUCCESS) {
		syslog(LOG_ERR, "RDE_Agent: iTimer_sel_obj creation FAILED");
		return ACS_APGCC_FAILURE;
	}

	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = iTimerHandler;
	sigaction (SIGALRM, &sa, NULL);

	timer.it_value.tv_sec = secs;
	timer.it_value.tv_usec = usecs;
	timer.it_interval.tv_sec = secs;
	timer.it_interval.tv_usec = usecs;

	int ret = setitimer (ITIMER_REAL, &timer, NULL);
	if (ret != 0){
		syslog(LOG_ERR, "RDE_Agent: setitimer FAILED with error:[%s]",strerror(errno));
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::iTimerHandler(ACE_INT32 sigNum)
{
	(void)sigNum;
	utils.sel_obj_ind(iTimer_sel_obj);
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::InitiateFailover(ACS_APGCC_AMF_RecommendedRecoveryT recommendedRecovery)
{
	if ( !this->handleRdeAgentGracefullDownJobsDone) {
		if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED! Forcing the Failover anyway.");
			/* Force Node to failover if the gracefuldown jobs fail */
			recommendedRecovery=ACS_APGCC_NODE_FAILOVER;
		}
	}
	else {
		syslog(LOG_INFO, "RDE_Agent: Gracefull jobs already performed!");
	}

	if (componentReportError(recommendedRecovery) != ACS_APGCC_SUCCESS){
		syslog(LOG_ERR, "RDE_Agent: componentReportError FAILED NODE FAILOVER Recovery Action");
		/* FAILOVER Action FAILED. Try rebooting the node forcefully */
		reboot_local_node();
	}
}

//-----------------------------------------------------------------------------
void APGHA_RDEAgent::reboot_local_node()
{
	ACE_TCHAR command_string[CMD_LEN];
	ACS_APGCC_ReturnType errorCode;

	syslog(LOG_INFO, "RDE_Agent: RDE Agent initiating reboot...");

	if (debugEnabled) {
		syslog(LOG_INFO, "RDE_Agent: Releasing AMF registration...");
	}
	/* release amf registrations */
	if (finalize() != ACS_APGCC_SUCCESS ){
		syslog(LOG_ERR, "RDE_Agent :rdaObj->finalize FAILED");
	}

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN,HA_BASE_CMD " --reboot-node");
	errorCode = launchCommand(command_string);
	 if ( errorCode == ACS_APGCC_FAILURE ) {
		 syslog (LOG_ERR,"failed to launch reboot command");
	 }
}

//-----------------------------------------------------------------------------
ACS_APGCC_ReturnType APGHA_RDEAgent::iTimerTimeoutHandler()
{
	utils.sel_obj_rmv_ind(APGHA_RDEAgent::iTimer_sel_obj, TRUE, TRUE);
	if (!IsDebug) {
		if (getHAState() == ACS_APGCC_AMF_HA_ACTIVE) {
			this->renewDiskRegCounter+=2;
			if (this->renewDiskRegCounter >=  this->diskRenewalThreadFreq){
				this->renewDiskRegCounter = 0;
				return renewDatadiskRegistrations();
			}
		}
	} else if (!this->Is_Agent_Stanby) {
		this->renewDiskRegCounter+=2;
		if (this->renewDiskRegCounter >=  this->diskRenewalThreadFreq){
			this->renewDiskRegCounter = 0;
			return renewDatadiskRegistrations();
		}
	}
	return ACS_APGCC_SUCCESS;
}

//*************************************************************************
//
//-------------------------------------------------------------------------
//
//  COPYRIGHT Ericsson AB 2010
//
//  The copyright to the computer program(s) herein is the property of
//  ERICSSON AB, Sweden. The programs may be used and/or copied only
//  with the written permission from ERICSSON AB or in accordance with
//  the terms and conditions stipulated in the agreement/contract under
//  which the program(s) have been supplied.
//
//-------------------------------------------------------------------------

