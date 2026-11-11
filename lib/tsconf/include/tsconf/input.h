#ifndef TSCONF_INPUT_H
#define TSCONF_INPUT_H

#include <stdint.h>

#define TS_JOYSTICK_RIGHT 0x01u
#define TS_JOYSTICK_LEFT 0x02u
#define TS_JOYSTICK_DOWN 0x04u
#define TS_JOYSTICK_UP 0x08u
#define TS_JOYSTICK_FIRE 0x10u

/* Read the Kempston port (1Fh). The caller keeps DOS and FDDVirt.D7 clear
 * so that 1Fh addresses the joystick. D7:5 are extra controller buttons on
 * 8-bit builds and zero on 5-bit builds. */
uint8_t ts_joystick_read(void);

#endif
