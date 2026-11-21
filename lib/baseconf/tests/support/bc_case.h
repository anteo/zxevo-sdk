#ifndef BASECONF_CASE_H
#define BASECONF_CASE_H

#include <baseconf.h>
#include <zx_test.h>

/* Initialize ZXHost and the BaseConf library. Call zx_test_finish() even if
 * BaseConf initialization fails so the host receives a result. */
zx_status_t bc_case_init(void);

/* Configure the mode, show screen 0 and prepare it for drawing. */
zx_status_t bc_case_select_video_mode(bc_video_mode_t mode);

#endif
