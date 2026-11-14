#ifndef TSCONF_MEMORY_INTERNAL_H
#define TSCONF_MEMORY_INTERNAL_H

#include <stdint.h>
#include <zx/memory.h>

/* Raw Page1..Page3 register writes. Internal code must own paging and keep
 * all resident code, data, stack and interrupt handlers mapped. */
void ts_memory_set_page1(uint8_t page) __z88dk_fastcall;
void ts_memory_set_page2(uint8_t page) __z88dk_fastcall;
void ts_memory_set_page3(uint8_t page) __z88dk_fastcall;

#endif
