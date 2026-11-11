#ifndef TSCONF_FT812_H
#define TSCONF_FT812_H

#include <stdint.h>
#include <zx/status.h>

#define TS_FT812_CMD_ACTIVE 0x00u
#define TS_FT812_CMD_STANDBY 0x41u
#define TS_FT812_CMD_SLEEP 0x42u
#define TS_FT812_CMD_CLKEXT 0x44u
#define TS_FT812_CMD_CLKINT 0x48u
#define TS_FT812_CMD_PWRDOWN 0x50u
#define TS_FT812_CMD_CLKSEL 0x61u
#define TS_FT812_CMD_RST_PULSE 0x68u

/* CLKSEL parameters for a 12 MHz oscillator. Send the command in SLEEP. */
#define TS_FT812_CLK_24_MHZ 0x02u
#define TS_FT812_CLK_36_MHZ 0x03u
#define TS_FT812_CLK_48_MHZ 0x44u
#define TS_FT812_CLK_60_MHZ 0x45u

#define TS_FT812_RAM_G 0x000000ul
#define TS_FT812_RAM_DL 0x300000ul
#define TS_FT812_DL_WORDS 2048u
#define TS_FT812_RAM_CMD 0x308000ul

#define TS_FT812_REG_ID 0x302000ul
#define TS_FT812_REG_CPURESET 0x302020ul
#define TS_FT812_REG_HCYCLE 0x30202cul
#define TS_FT812_REG_HOFFSET 0x302030ul
#define TS_FT812_REG_HSIZE 0x302034ul
#define TS_FT812_REG_HSYNC0 0x302038ul
#define TS_FT812_REG_HSYNC1 0x30203cul
#define TS_FT812_REG_VCYCLE 0x302040ul
#define TS_FT812_REG_VOFFSET 0x302044ul
#define TS_FT812_REG_VSIZE 0x302048ul
#define TS_FT812_REG_VSYNC0 0x30204cul
#define TS_FT812_REG_VSYNC1 0x302050ul
#define TS_FT812_REG_DLSWAP 0x302054ul
#define TS_FT812_REG_DITHER 0x302060ul
#define TS_FT812_REG_SWIZZLE 0x302064ul
#define TS_FT812_REG_CSPREAD 0x302068ul
#define TS_FT812_REG_PCLK_POL 0x30206cul
#define TS_FT812_REG_PCLK 0x302070ul

#define TS_FT812_ID 0x7cu
#define TS_FT812_DLSWAP_DONE 0u
#define TS_FT812_DLSWAP_FRAME 2u
#define TS_FT812_VIDEO_ROUTE 0x04u

#define TS_FT812_DL_DISPLAY 0ul
#define TS_FT812_DL_CLEAR_COLOR_RGB(r, g, b)                                                       \
    (0x02000000ul | ((uint32_t)(uint8_t)(r) << 16) | ((uint32_t)(uint8_t)(g) << 8) | (uint8_t)(b))
#define TS_FT812_DL_CLEAR(color, stencil, tag)                                                     \
    (0x26000000ul | ((uint8_t)((color) != 0) << 2) | ((uint8_t)((stencil) != 0) << 1) |            \
     (uint8_t)((tag) != 0))

/* FT812 SPI calls require VDAC2 hardware and exclusive ownership of the
 * shared SPI bus. The caller also serializes operations on the FT812. */

/* Send one host command and release CS. ACTIVE requires parameter zero.
 * Other commands have the 01xxxxxx prefix. Observe the device's minimum
 * power, oscillator and reset delays between host commands and the probe. */
zx_status_t ts_ft812_host_command(uint8_t command, uint8_t parameter);

/* Transfer a contiguous span of the 22-bit EVE address space. Addresses
 * and lengths are bytes. A zero-length span at or before the end succeeds
 * without SPI traffic. Use the register's little-endian byte order. A
 * successful transfer only reports that the SPI transaction completed. */
zx_status_t ts_ft812_read(uint32_t address, void *buffer, uint16_t length);
zx_status_t ts_ft812_write(uint32_t address, const void *buffer, uint16_t length);

/* Poll for REG_ID == 7Ch and REG_CPURESET == 0. polls is an attempt count.
 * Return ZX_TIMEOUT if no attempt sees both values, including polls == 0. */
zx_status_t ts_ft812_wait_ready(uint16_t polls) __z88dk_fastcall;

typedef struct {
    uint16_t cycle;
    uint16_t offset;
    uint16_t size;
    uint16_t sync_start;
    uint16_t sync_end;
} ts_ft812_axis_t;

typedef struct {
    ts_ft812_axis_t horizontal; /* units are pixel clocks */
    ts_ft812_axis_t vertical;   /* units are scan lines */
    uint8_t dither;
    uint8_t swizzle;
    uint8_t cspread;
    uint8_t pclk_polarity;
} ts_ft812_timing_t;

/* Validate the timings, stop PCLK and program the raster on a ready chip.
 * The active interval and sync interval must each fit in the 12-bit
 * cycle. Active height takes 1..2047. Dither, cspread and polarity are
 * bits. Swizzle takes 0..15.
 * Leaves PCLK off so the caller can submit an initial display list. */
zx_status_t ts_ft812_configure_display(const ts_ft812_timing_t *timing) __z88dk_fastcall;

/* Zero stops the pixel clock. A nonzero divider enables it at the EVE
 * system clock divided by divider. */
void ts_ft812_set_pclk(uint8_t divider) __z88dk_fastcall;

/* Upload 1..2048 little-endian display-list words ending with DISPLAY and
 * request a frame swap. Return ZX_BUSY while a previous swap is pending.
 * Enable PCLK before waiting for the swap. A floating FFh status returns
 * ZX_UNAVAILABLE from both display-list operations. */
zx_status_t ts_ft812_submit_display_list(const uint32_t *words, uint16_t count);
zx_status_t ts_ft812_wait_display_list(uint16_t polls) __z88dk_fastcall;

/* Supply the full current native VConfig. Change only D2 to route FT812
 * to the external VDAC2 connector and its INT output to IDE_D1. The
 * onboard display remains native. Requires an IDE_VDAC2 FPGA build. */
void ts_ft812_route_video(uint8_t native_config, uint8_t enabled);

#endif
