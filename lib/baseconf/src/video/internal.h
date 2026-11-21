#ifndef BASECONF_VIDEO_INTERNAL_H
#define BASECONF_VIDEO_INTERNAL_H

#include <baseconf.h>
#include "../internal.h"

extern bc__draw_surface_t bc_video_draw_surface_state;
extern uint8_t bc_video_operation_depth, bc_video_mapped_page;
extern uint8_t bc_video_cache_valid, bc_video_cached_map;
extern uint8_t bc_video_cached_manager_enabled;
extern uint8_t bc_video_surface_selected;
extern uint16_t bc_video_cpu_base, bc_video_page0_base, bc_video_page1_base;
extern uint16_t bc_video_cached_width, bc_video_cached_height;

/* A checked buffer. ASM uses this field order and a seven-byte stride.
 * A zero window0_high marks an empty entry. */
typedef struct {
    uint8_t window0_high;
    uint8_t window1_high;
    uint8_t mode;
    zx_ram_page_t page0;
    zx_ram_page_t page1;
    uint8_t display_status;
    uint8_t display_flags;         /* Screen bit 3 of 7FFD and 128K mode bit 2 of EFF7. */
} bc__draw_buffer_t;
extern bc__draw_buffer_t bc_video_prepared_buffers[ZX_DRAW_BUFFER_SLOTS];
zx_status_t bc__video_publish_draw_buffer(const bc__draw_buffer_t *buffer) __z88dk_fastcall;

extern const zx_ram_page_t bc__video_first_screen_pages[];
/* Return the hardware mode in the low byte and the same sample's EFF7 in the high byte. */
uint16_t bc__video_read_mode_and_eff7(void);
/* Refresh display flags for valid slots and return the sampled hardware mode. */
uint8_t bc__video_refresh_display_buffers(void);

uint16_t bc__video_system_port(uint8_t palette_allowed);
uint8_t bc__video_mode_enabled(bc_video_mode_t mode);
/* Publish a validated surface and update console geometry on a format change. */
void bc__video_commit_surface(const bc__draw_surface_t *surface) __z88dk_fastcall;
/* Find the first usable W1..W3 for each page in the supplied valid map's cache.
 * ZX_WINDOW_0 marks a missing page. Return ZX_UNAVAILABLE if either is missing. */
zx_status_t bc__video_find_page_windows(bc_map_t map, const bc__draw_surface_t *surface,
                                        zx_window_t windows[2]);
/* Inspect the SDK cache for a valid map on an initialized machine. */
zx_status_t bc__video_check_page_window(bc_map_t map, zx_window_t window, zx_ram_page_t page);
uint16_t bc__video_width(void);
uint16_t bc__video_height(void);
zx_status_t bc__video_begin(void);
zx_status_t bc__video_end(void);
void bc__video_invalidate_cache(void);
void bc__video_invalidate_draw_cache(void);
zx_status_t bc__video_sync_cache(void);
void bc__video_hline(int x0, int x1, int y, uint8_t operation);
void bc__video_vline(int x, int y0, int y1, uint8_t operation);
void bc__video_scroll_up_pixels(uint8_t rows);
void bc__video_scroll_horizontal(uint8_t pixels, uint8_t right);
void bc__video_scroll_text_rows(bc_video_mode_t mode, bc__draw_surface_t surface, uint8_t row_count,
                                uint8_t columns);
void bc__video_clear_text_row(bc_video_mode_t mode, bc__draw_surface_t surface, uint8_t row,
                              uint8_t columns, uint8_t attribute);
zx_status_t bc__video_clear(void);
zx_status_t bc__video_scroll_up8(void);
void bc__console_set_geometry(uint8_t columns, uint8_t rows);

#endif
