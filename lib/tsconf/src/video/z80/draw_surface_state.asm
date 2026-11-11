        MODULE ts_draw_surface_state
SECTION data_clib
PUBLIC ts_draw_config
PUBLIC ts_draw_page
PUBLIC ts_draw_base
; The selection routine stores config and page together as one word.
ts_draw_config: defb 0ffh            ; D1:0=3, but the whole byte means unselected
ts_draw_page:   defb 0
ts_draw_base:   defb 0

SECTION bss_clib
PUBLIC ts__graphics_group_depth
ts__graphics_group_depth: defb 0
