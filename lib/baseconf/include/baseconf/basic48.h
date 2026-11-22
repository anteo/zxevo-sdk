#ifndef BASECONF_BASIC48_H
#define BASECONF_BASIC48_H

#include <baseconf/video.h>

/* Start in BASIC 48 IM1 on ZX screen 0 with zx_init complete. Select the
 * alternate hardware screen for drawing. Code, constants, data and the full
 * application stack must reside in fixed W2. Reserve the alternate screen's
 * physical RAM pages for the session. W1 and W3 are borrowed and INT is
 * masked until present or end. Use SDK drawing calls while composing the
 * frame and finish any graphics operation before present/end. Leave the
 * paging configuration and interrupt state under SDK control until end. */
zx_status_t bc_basic48_video_begin(bc_video_mode_t mode);

/* Show the completed frame, release the draw windows and restore INT so BASIC
 * frame waits work. The image remains visible until end. On failure the
 * draw windows stay borrowed and INT stays masked until end. */
zx_status_t bc_basic48_video_present(void);

/* Pair every successful begin with end, including after a draw/present error.
 * Restore BASIC's windows, ZX screen 0, saved border, addressing and INT. */
zx_status_t bc_basic48_video_end(void);

#endif
