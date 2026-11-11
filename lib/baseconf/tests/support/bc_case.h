#ifndef BASECONF_CASE_H
#define BASECONF_CASE_H

#include <baseconf.h>
#include <zx_test.h>

/* Initialize ZXHost and the BaseConf library. Call zx_test_finish() even if
 * BaseConf initialization fails so the host receives a result. */
zx_status_t bc_case_init(void);

#endif
