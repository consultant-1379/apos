#ifndef APOS_HA_UTILS_H
#define APOS_HA_UTILS_H

#include "signal.h"
#include "sys/wait.h"
#include "time.h"
#include "fcntl.h"
#include "errno.h"
#include "stdio.h"
#include "unistd.h"
#include "limits.h"
#include "sys/types.h"
#include "sys/socket.h"
#include "syslog.h"
#include "assert.h"
#include "sys/ioctl.h"

#include "ACS_APGCC_AmfTypes.h"

#define MAX_INDS_AT_A_TIME 10

class ACS_APGCC_AgentUtils {

	private:

	public:

		ACS_APGCC_AgentUtils();
		~ACS_APGCC_AgentUtils();

		ACS_APGCC_ReturnType sel_obj_create(ACS_APGCC_SEL_OBJ *o_sel_obj);

		ACS_APGCC_ReturnType sel_obj_destroy(ACS_APGCC_SEL_OBJ i_ind_obj);

		int sel_obj_rmv_ind(ACS_APGCC_SEL_OBJ i_ind_obj, 
					ACS_APGCC_BOOL nonblock, 
					ACS_APGCC_BOOL one_at_a_time);

		ACS_APGCC_ReturnType sel_obj_ind(ACS_APGCC_SEL_OBJ i_ind_obj);
};
#endif
