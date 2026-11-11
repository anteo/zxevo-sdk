#ifndef TSCONF_FDD_H
#define TSCONF_FDD_H

#include <stdint.h>
#include <zx/fdd.h>

#define TS_FDD_VIRTUAL_A 0x01u
#define TS_FDD_VIRTUAL_B 0x02u
#define TS_FDD_VIRTUAL_C 0x04u
#define TS_FDD_VIRTUAL_D 0x08u
#define TS_FDD_OPEN_PORTS 0x80u

/* Replace the write-only FDDVirt register, with bits D6:4 cleared.
 * TS_FDD_OPEN_PORTS opens Beta Disk and hides Kempston. Virtual drive
 * bits enable VDOS trapping in DOS and require an installed VDOS handler. */
void ts_fdd_set_config(uint8_t config) __z88dk_fastcall;

#endif
