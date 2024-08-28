#include "apg_app1_appclass.h"
#include "apg_app1_class.h"

int myClass::start(HAClass* haObj ){

	m_haObj=haObj;
	m_haObj->log.Write("app-class: active invoked", LOG_LEVEL_INFO);
	/* start any threads based on app requirements */
	return 0;
}

void myClass::stop() {
	m_haObj->log.Write("app-class: stop invoked", LOG_LEVEL_INFO);
	/* stop application work */
}



