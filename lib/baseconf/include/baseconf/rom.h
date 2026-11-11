#ifndef BASECONF_ROM_H
#define BASECONF_ROM_H

#include <stdint.h>
#include <baseconf.h>

/* Return 1 if the declared profile is not BC_ERS_NONE, otherwise 0.
 * This tests software state only and does not detect an installed ERS ROM. */
uint8_t bc_ers_is_available(void);
/* Declare the ERS profile used by wrappers, or BC_ERS_NONE to disable them.
 * The caller must supply a bc_ers_profile_t value and arrange a working RST 08h
 * service. This call does not validate the value, probe ROM or change paging. */
void bc_ers_set_profile(bc_ers_profile_t profile);

#endif
