#include "apg_app3_class.h"

ACE_THR_FUNC_RETURN svc_run(void *);

HAClass::HAClass(const char* daemon_name, const char* username):ACS_APGCC_ApplicationManager(daemon_name, username){

	/* create the pipe for shutdown handler */
        Is_terminated = FALSE;
        if ( (pipe(readWritePipe)) < 0) {
       		syslog(LOG_ERR, "pipe creation FAILED");
        }

        if ( (fcntl(readWritePipe[0], F_SETFL, O_NONBLOCK)) < 0) {
        	syslog(LOG_ERR, "pipe fcntl on readn");
        }

        if ( (fcntl(readWritePipe[1], F_SETFL, O_NONBLOCK)) < 0) {
        	syslog(LOG_ERR, "pipe fcntl on writen");
        }
}


ACS_APGCC_ReturnType HAClass::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState){

	/* Check if we have received the ACTIVE State Again.
	 * This means that, our application is already Active and
	 * again we have got a callback from AMF to go active.
	 * Ignore this case anyway. This case should rarely happens
	 */
	ACE_TCHAR state[1] = {'A'};
	if(ACS_APGCC_AMF_HA_ACTIVE == previousHAState)
		return ACS_APGCC_SUCCESS;

	/* Our application has received state ACTIVE from AMF.
	 * Start off with the activities needs to be performed
	 * on ACTIVE
	 */
	 /* Check if it is due to State Transition ( Passive --> Active)*/
	if ( ACS_APGCC_AMF_HA_UNDEFINED != previousHAState ){
		syslog(LOG_INFO, "State Transision happend. Becomming Active now");
		/* Inform the thread to go "active" state */
		write(readWritePipe[1], &state, sizeof(state));
		return ACS_APGCC_SUCCESS;
	}

	/* Handle here what needs to be done when you are given ACTIVE State */
	syslog(LOG_INFO, "My Application Component received ACTIVE state assignment!!!");
	
	/* Create a thread with the state machine (active, passive, stop states)
	 * and start off with "active" state activities.
	 */
	
	/* spawn thread */
	const ACE_TCHAR* thread_name = "ApplicationThread";
	ACE_HANDLE threadHandle = ACE_Thread_Manager::instance()->spawn(&svc_run,
									(void *)this ,
									THR_NEW_LWP | THR_JOINABLE | THR_INHERIT_SCHED,
									0,
									0,
									ACE_DEFAULT_THREAD_PRIORITY,
									-1,
									0,
									ACE_DEFAULT_THREAD_STACKSIZE,
									&thread_name);
	if (threadHandle == -1){
		syslog(LOG_ERR, "Error creating the application thread");
		return ACS_APGCC_FAILURE;	
	}
				
	write(readWritePipe[1], &state, sizeof(state));

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	(void)previousHAState;
	ACE_TCHAR state[1] = {'S'};

	/* We were active and now losing active state due to some shutdown admin
	 * operation performed on our SU. 
	 * Inform the thread to go to "stop" state
	 */  

	syslog(LOG_INFO, "My Application Component received QUIESING state assignment!!!");
	
	/* Inform the thread to go "stop" state */	
	if ( !Is_terminated )
		write(readWritePipe[1], &state, sizeof(state));
	Is_terminated = TRUE;

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
	(void)previousHAState;
	ACE_TCHAR state[1] = {'S'};

	/* We were Active and now losting Active state due to Lock admin
	 * operation performed on our SU. 
	 * Inform the thread to go to "stop" state
	 */

	syslog(LOG_INFO, "My Application Component received QUIESCED state assignment!");

	/* Inform the thread to go "stop" state */	
	if ( !Is_terminated )
		write(readWritePipe[1], &state, sizeof(state));
	Is_terminated = TRUE;

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performComponentHealthCheck(void)
{

	/* Application has received health check callback from AMF. Check the
	 * sanity of the application and reply to AMF that you are ok.
	 */
	syslog(LOG_INFO, "My Application Component received healthcheck query!!!");

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performComponentTerminateJobs(void)
{
	/* Application has received terminate component callback due to 
	 * LOCK-INST admin opreration perform on SU. Terminate the thread if
	 * we have not terminated in performComponentRemoveJobs case or double 
	 * check if we are done so.
	 */
	syslog(LOG_INFO, "My Application Component received terminate callback!!!");

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performComponentRemoveJobs(void)
{

	/* Application has received Removal callback. State of the application 
	 * is neither Active nor Standby. This is with the result of LOCK admin operation
	 * performed on our SU. Terminate the thread by informing the thread to go "stop" state. 
	 */

	ACE_TCHAR state[1] = {'S'};

	syslog(LOG_INFO, "Application Assignment is removed now");
	/* Inform the thread to go "stop" state */	
	if ( !Is_terminated )
		write(readWritePipe[1], &state, sizeof(state));

	Is_terminated = FALSE;
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType HAClass::performApplicationShutdownJobs() {
	
	syslog(LOG_ERR, "Shutting down the application");
	ACE_TCHAR state[1] = {'S'};

	if ( !Is_terminated )
		write(readWritePipe[1], &state, sizeof(state));

	Is_terminated = FALSE;
	return ACS_APGCC_SUCCESS;
}

ACE_THR_FUNC_RETURN svc_run(void *ptr){
	HAClass *haObj = (HAClass*) ptr;
	haObj->svc(); 
	return 0;	
}

ACS_APGCC_ReturnType HAClass::svc(){

	struct pollfd fds[1];
	nfds_t nfds = 1;
	ACE_INT32 ret;
	ACE_Time_Value timeout;

        ACE_INT32 retCode;

	syslog(LOG_INFO, "Starting Application Thread");

	__time_t secs = 5;
	__suseconds_t usecs = 0;
	timeout.set(secs, usecs);

			
	fds[0].fd = readWritePipe[0];
	fds[0].events = POLLIN;

	while(true)
	{
		ret = ACE_OS::poll(fds, nfds, &timeout); // poll can also be a blocking call, such case timeout = 0

		if (ret == -1) {
			if (errno == EINTR)
				continue;
			syslog(LOG_ERR,"poll Failed - %s, Exiting...",strerror(errno));
			kill(getpid(), SIGTERM);
			return ACS_APGCC_FAILURE;
		}

		if (ret == 0){
			syslog(LOG_INFO, "timeout on ACE_OS::poll");
			continue;
		}
		
		if (fds[0].revents & POLLIN){
			ACE_TCHAR ha_state[1] = {'\0'};
			ACE_TCHAR* ptr = (ACE_TCHAR*) &ha_state;
        		ACE_INT32 len = sizeof(ha_state);
			
			while (len > 0){
                		retCode=read(readWritePipe[0], ptr, len);
                		if ( retCode < 0 && errno != EINTR){
                        		syslog(LOG_ERR, "Read interrupted by error: [%s]",strerror(errno));
					kill(getpid(), SIGTERM);
                        		return ACS_APGCC_FAILURE;
                		}
                		else {
                        		ptr += retCode;
                        		len -= retCode;
                		}
                		if (retCode == 0)
                       		   break;
        		}

			if ( len != 0) {
                		syslog(LOG_ERR, "Improper Msg Len Read [%d]", len);
				kill(getpid(), SIGTERM);
                		return ACS_APGCC_FAILURE;
        		}
			len = sizeof(ha_state);

			if (ha_state[0] == 'A'){
				syslog(LOG_ERR, "Thread:: Application is Active");
				/* start application work */
				
			}

			if (ha_state[0] == 'S'){
				syslog(LOG_ERR, "Thread:: Request to stop application");
				/* Request to stop the thread, perform the gracefull activities here */
				break;
			}
		}
	}
	
	syslog(LOG_INFO, "Application Thread Terminated successfully");
	return ACS_APGCC_SUCCESS;
}

