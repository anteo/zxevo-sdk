#ifndef BASECONF_VIDEO_INTERNAL_H
#define BASECONF_VIDEO_INTERNAL_H

#include <baseconf.h>
#include "../internal.h"

extern bc_surface_t bc_video_draw_surface_state;
extern uint8_t bc_video_operation_depth, bc_video_mapped_page;
extern uint8_t bc_video_cache_valid, bc_video_cached_map;
extern uint8_t bc_video_cached_manager_enabled;
extern uint8_t bc_video_surface_selected;
extern uint16_t bc_video_cpu_base, bc_video_page0_base, bc_video_page1_base;
extern uint16_t bc_video_cached_width, bc_video_cached_height;

uint16_t bc__video_system_port(uint8_t palette_allowed);
bc_surface_t bc_screen_surface(bc_video_mode_t mode, zx_screen_t screen);
uint8_t bc__video_mode_enabled(bc_video_mode_t mode);
zx_status_t bc_set_video_mode(bc_video_mode_t mode);
bc_video_mode_t bc_get_video_mode(void);
/* Publish a validated surface and invalidate its prepared CPU mappings. */
void bc__video_commit_surface(const bc_surface_t *surface) __z88dk_fastcall;
enum { BC_VIDEO_SKIP_WINDOW_ERRORS, BC_VIDEO_STOP_ON_WINDOW_ERROR };
/* Find the first usable W1..W3 for each page. ZX_WINDOW_0 marks a missing page.
 * Return ZX_UNAVAILABLE if either page is missing. Strict scans also return
 * the first config error, even if both pages have already been found. */
zx_status_t bc__video_find_page_windows(bc_map_t map, const bc_surface_t *surface,
                                        uint8_t stop_on_error, zx_window_t windows[2]);
zx_status_t bc_select_draw_surface(const bc_surface_t *surface);
zx_status_t zx_select_draw_screen(zx_screen_t screen);
uint16_t bc__video_width(void);
uint16_t bc__video_height(void);
zx_status_t bc__video_begin(void);
zx_status_t bc__video_end(void);
void bc__video_invalidate_cache(void);
zx_status_t bc__video_sync_cache(void);
void bc__video_hline(int x0, int x1, int y, uint8_t operation);
void bc__video_vline(int x, int y0, int y1, uint8_t operation);
void bc__video_scroll_up_pixels(uint8_t rows);
void bc__video_scroll_horizontal(uint8_t pixels, uint8_t right);
void bc__video_scroll_text_rows(bc_video_mode_t mode, bc_surface_t surface, uint8_t row_count,
                                uint8_t columns);
void bc__video_clear_text_row(bc_video_mode_t mode, bc_surface_t surface, uint8_t row,
                              uint8_t columns, uint8_t attribute);
zx_status_t bc__video_clear(void);
zx_status_t bc__video_scroll_up8(void);
void bc__console_set_geometry(uint8_t columns, uint8_t rows);

#endif
