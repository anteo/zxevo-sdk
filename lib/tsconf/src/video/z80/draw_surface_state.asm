        MODULE ts_draw_surface_state
INCLUDE "video/draw_buffer.inc"
SECTION data_clib
PUBLIC ts_draw_config
PUBLIC ts_draw_page
PUBLIC ts_draw_base
PUBLIC _ts_draw_config
PUBLIC _ts_draw_page
PUBLIC _ts_draw_base
PUBLIC _ts_video_prepared_buffers
; The selection routine stores config and page together as one word.
_ts_draw_config:
ts_draw_config: defb 0ffh            ; D1:0=3, but the whole byte means unselected
_ts_draw_page:
ts_draw_page:   defb 0
_ts_draw_base:
ts_draw_base:   defb 0

; Two prepared records: config, page, window high byte.
_ts_video_prepared_buffers:
        REPT 2
        defb 0ffh                    ; empty config
        defs TS_DRAW_SLOT_SIZE-1
        ENDR

SECTION bss_clib
PUBLIC ts__graphics_group_depth
PUBLIC _ts__draw_window_leased
ts__graphics_group_depth: defb 0
; A public RAM lease temporarily covers the selected CPU-mapped draw window.
_ts__draw_window_leased: defb 0
