#ifndef BASECONF_H
#define BASECONF_H

#include <stdint.h>
#include <zx/memory.h>
#include <zx/status.h>

typedef uint8_t bc_flash_bank_t;

typedef enum { BC_MAP_0, BC_MAP_1 } bc_map_t;

typedef enum { BC_RAM, BC_FLASH } bc_memory_kind_t;

typedef enum { BC_ADDRESSING_1024K, BC_ADDRESSING_128K } bc_addressing_t;

typedef enum { BC_READBACK_BD, BC_READBACK_BE } bc_readback_backend_t;

typedef enum { BC_ERS_NONE, BC_ERS_ROM_BAS48, BC_ERS_SERVICES_ROM } bc_ers_profile_t;

typedef enum {
    BC_VIDEO_ZX_256,
    BC_VIDEO_ZX_MULTICOLOR,
    BC_VIDEO_PENTAGON_256,
    BC_VIDEO_ATM_320,
    BC_VIDEO_ATM_640,
    BC_VIDEO_ATM_TEXT_80,
    BC_VIDEO_EVO_TEXT_80,
    BC_VIDEO_UNKNOWN = 0xff
} bc_video_mode_t;

typedef struct {
    bc_memory_kind_t kind;
    uint8_t physical_page;
    uint8_t substitute_from_7ffd_or_dos;
    uint8_t write_protected;
} bc_window_config_t;

typedef struct {
    bc_video_mode_t mode;
    zx_ram_page_t page0;
    zx_ram_page_t page1;
} bc_surface_t;

/* BC_PAGING_* macros take the byte read from the 7FFD paging register. */
#define BC_PAGING_ACTIVE_MAP(state) ((bc_map_t)(((state) >> 4) & 1u))
#define BC_PAGING_SCREEN(state) ((zx_screen_t)(((state) >> 3) & 1u))
#define BC_PAGING_RAM_PAGE_128K(state) ((uint8_t)((state) & 7u))
#define BC_PAGING_RAM_PAGE_1024K(state)                                                            \
    ((uint8_t)(((state) & 7u) | (((state) & 0x20u) >> 2) | (((state) & 0xc0u) >> 2)))
#define BC_PAGING_IS_LOCKED_128K(state) (((state) & 0x20u) != 0u)
#define BC_CONFIG_SHADOW_PORTS(state) ((uint8_t)((state) & 1u))
#define BC_CONFIG_FLASH_WRITE(state) ((uint8_t)(((state) >> 1) & 1u))
#define BC_CONFIG_FONT_WRITE(state) ((uint8_t)(((state) >> 2) & 1u))
#define BC_CONFIG_RGB444(state) ((uint8_t)(((state) >> 5) & 1u))

#include <zx/audio.h>
#include <zx/color.h>
#include <zx/console.h>
#include <zx/graphics.h>
#include <zx/init.h>
#include <zx/video.h>
#include <zx/ide.h>
#include <zx/input.h>
#include <zx/interrupt.h>
#include <zx/printf.h>
#include <zx/ps2.h>
#include <zx/sd.h>
#include <zx/timing.h>
#include <zx/uart.h>

#include <baseconf/ers.h>
#include <baseconf/font.h>
#include <baseconf/interrupt.h>
#include <baseconf/memory.h>
#include <baseconf/newirq.h>
#include <baseconf/palette.h>
#include <baseconf/rom.h>
#include <baseconf/rtc.h>
#include <baseconf/storage.h>
#include <baseconf/text.h>
#include <baseconf/video.h>

#endif
