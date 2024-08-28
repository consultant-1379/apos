
#include "apos_ha_rdeagent_utils.h"

ACS_APGCC_AgentUtils::ACS_APGCC_AgentUtils(){

	// empty constructor

}

ACS_APGCC_AgentUtils::~ACS_APGCC_AgentUtils(){

	// empty destructor
}

ACS_APGCC_ReturnType ACS_APGCC_AgentUtils::sel_obj_create(ACS_APGCC_SEL_OBJ *o_sel_obj){

	int s_pair[2];
	int enable_nbio = 1;
	int flags = 0;

	if (0 != socketpair(AF_UNIX, SOCK_STREAM, 0, s_pair)) {
		perror("socketpair:");
		return ACS_APGCC_FAILURE;
	}

	flags = fcntl(s_pair[0], F_GETFD, 0);
	fcntl(s_pair[0], F_SETFD, (flags | FD_CLOEXEC));

	flags = fcntl(s_pair[1], F_GETFD, 0);
	fcntl(s_pair[1], F_SETFD, (flags | FD_CLOEXEC));

	if (s_pair[0] > s_pair[1]) {
		/* Ensure s_pair[1] is equal or greater */
		int temp = s_pair[0];
		s_pair[0] = s_pair[1];
		s_pair[1] = temp;
	}
	o_sel_obj->raise_obj = s_pair[0];
	o_sel_obj->rmv_obj = s_pair[1];

	/* Raising indications should be a non-blocking operation. Otherwise,
	 * it can lead to deadlocks among reader and writer applications.
	 */
	ioctl(o_sel_obj->raise_obj, FIONBIO, &enable_nbio);
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType ACS_APGCC_AgentUtils::sel_obj_destroy(ACS_APGCC_SEL_OBJ i_ind_obj){

	shutdown(i_ind_obj.raise_obj, SHUT_RDWR);
	close(i_ind_obj.raise_obj);
	shutdown(i_ind_obj.rmv_obj, SHUT_RDWR);
	close(i_ind_obj.rmv_obj);
	return ACS_APGCC_SUCCESS;
}



int ACS_APGCC_AgentUtils::sel_obj_rmv_ind(	ACS_APGCC_SEL_OBJ i_ind_obj,
					ACS_APGCC_BOOL nonblock,
					ACS_APGCC_BOOL one_at_a_time){

	char tmp[MAX_INDS_AT_A_TIME];
	int ind_count, tot_inds_rmvd;
	int num_at_a_time;

	tot_inds_rmvd = 0;
	num_at_a_time = (one_at_a_time ? 1 : MAX_INDS_AT_A_TIME);

	/* If one_at_a_time == FALSE, remove MAX_INDS_AT_A_TIME in a
	 * non-blocking way and count the number of indications
	 * so removed using "tot_inds_rmvd"
	 * 
	 * If one_at_a_time == TRUE,  then quit the infinite loop
	 * after removing at most 1 indication.
	 */

	for (;;) {
		ind_count = recv(i_ind_obj.rmv_obj, &tmp, num_at_a_time, MSG_DONTWAIT);

		if (ind_count > 0) {
			 /* Only one indication should be removed at a time, return immediately */
			if (one_at_a_time) {
				assert(ind_count == 1);
				return 1;
			}

			/* Some indications were removed */
			tot_inds_rmvd += ind_count;
		} else if (ind_count <= 0) {
			if (errno == EAGAIN)
				/* All queued indications have been removed */
				break;
			else if (errno == EINTR)
				/* recv() call was interrupted. Needs to be invoked again */
				continue;
			else {
				/* Unknown error. */
				perror("rmv_ind1:");
				return -1;
			}
		}
	}                       /* End of infinite loop */

	/* Reaching here implies that all pending indications have been removed
	 * and "tot_inds_rmvd" contains a count of indications removed.
	 * 
	 * Now, action to be taken could be one of the following
	 * a) if  (tot_inds_rmvd !=0) : All indications removed, need some
	 *          processing, so will return "tot_inds_rmvd"
	 *
	 * b) if  (tot_inds_rmvd == 0) and (nonblock) : Caller was just checking
	 *         if any indications were pending, he didn't know that there were
	 *         no indications pending. Simply return 0;
	 *                                               
	 * c) if  (tot_inds_rmvd == 0) and (!nonblock) : There are no indications
	 *         pending but we should not return unless there is an indication
	 *         arrives.
	 */

	 if ((tot_inds_rmvd != 0) || (nonblock)) {
		/* Case (a) or case (b) above */
		return tot_inds_rmvd;
	}

	/* Case (c) described above */
	 for (;;) {
		/* We now block on receive.  */
		ind_count = recv(i_ind_obj.rmv_obj, &tmp, num_at_a_time, 0);
		if (ind_count > 0) {
			/* Some indication has arrived. */
		
		/* NOTE: There may be more than "num_at_a_time" indications
		 * queued up. We could do another "tot_inds_rmvd" calculation,
		 * but that's not done here, as it is involves some effort and can
		 * conveniently be postponed till the next invocation of this
		 * function.
		 */
		  return ind_count;
		} else if ((ind_count < 0) && (errno != EINTR)) {
			/* Unknown mishap. Should reach here only if
			 * the i_rmv_ind_obj has now become invalid.
			 * Close down and return error.
			 * FIXME: TODO
			 */
			shutdown(i_ind_obj.rmv_obj, SHUT_RDWR);
			close(i_ind_obj.rmv_obj);
			syslog(LOG_INFO, "RMV_IND2. Returning -1\n");
			return -1;
		}
	}	/* End of infinite loop */
}


ACS_APGCC_ReturnType ACS_APGCC_AgentUtils::sel_obj_ind(ACS_APGCC_SEL_OBJ i_ind_obj){
	
	/* The following call can block, in such a case a failure is returned */
	if (write(i_ind_obj.raise_obj, "A", 1) != 1)
		return ACS_APGCC_FAILURE;
	return ACS_APGCC_SUCCESS;
}


