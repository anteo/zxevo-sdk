#ifndef BASECONF_INTERNAL_H
#define BASECONF_INTERNAL_H

#include <arch/z80.h>
#include <baseconf.h>
#include <baseconf/memory.h>

#ifndef BASECONF_INLINE
#if defined(__SDCC)
/* SDCC inlines these definitions but emits standalone bodies for static inline. */
#define BASECONF_INLINE inline
#else
#define BASECONF_INLINE static inline
#endif
#endif

zx_status_t bc__mem_write_eff7(uint8_t value);
void bc__console_set_geometry(uint8_t columns, uint8_t rows);
/* Every successful begin owns one nesting level and needs a matching end. */
zx_status_t bc__video_begin(void);
zx_status_t bc__video_end(void);
void bc__video_invalidate_cache(void);
zx_status_t bc__video_sync_cache(void);
/* Inclusive signed axis lines: sort/clip endpoints inside a prepared video
 * lease; SET/CLEAR/XOR change pixel data while preserving attributes. */
void bc__video_hline(int x0, int x1, int y, uint8_t operation);
void bc__video_vline(int x, int y0, int y1, uint8_t operation);
extern bc_surface_t bc_video_draw_surface_state;
extern uint8_t bc_video_operation_depth;
extern uint16_t bc_video_page0_base, bc_video_page1_base;
zx_status_t bc__video_clear(void);
/* Primitive-mode vertical scroll inside an active prepared lease. Zero rows
 * does nothing; rows at/above the height fill the active planes. ZX256 keeps
 * its cell attributes; Multicolor/ATM scroll their attribute planes too. */
void bc__video_scroll_up_pixels(uint8_t rows);
/* Text-mode-family bitmap scroll: owns begin/end and moves eight pixel rows.
 * Also shifts ZX256 attributes by one cell row. Uses TEXT, not PRIMITIVE flags. */
zx_status_t bc__video_scroll_up8(void);
/* Active prepared lease; shift 1..8 pixels, nonzero right selects the right edge.
 * Bitmap attributes move only for an eight-pixel shift. Exposed packed pixels
 * use paper; exposed bitmap bits are zero. */
void bc__video_scroll_horizontal(uint8_t pixels, uint8_t right);
void bc__video_scroll_text_rows(bc_video_mode_t mode, bc_surface_t surface, uint8_t row_count,
                                uint8_t columns);
void bc__video_clear_text_row(bc_video_mode_t mode, bc_surface_t surface, uint8_t row,
                              uint8_t columns, uint8_t attribute);

#endif
