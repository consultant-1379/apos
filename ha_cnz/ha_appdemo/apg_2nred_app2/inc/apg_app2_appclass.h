#ifndef APG_APP2_APPCLASS_H
#define APG_APP2_APPCLASS_H

#include "unistd.h"
#include "syslog.h"
#include <ace/Task_T.h>
#include <ace/OS.h>

class HAClass;

class myClass: public ACE_Task<ACE_SYNCH> {

   private:

	HAClass* m_haObj;

   public:
	myClass(){};
	~myClass(){};
	int active(HAClass*);
	int passive(HAClass*);
	void stop();
}; 

#endif /* APG_APP2_APPCLASS_H */
