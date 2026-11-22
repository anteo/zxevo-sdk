        MODULE ts__packed_window_state
SECTION bss_clib
PUBLIC ts_packed_mode
PUBLIC ts_packed_color
PUBLIC ts__packed_base_page
PUBLIC ts__packed_saved_page
PUBLIC ts__packed_mapped_page
PUBLIC ts__packed_depth

ts_packed_mode:         defb 0
ts_packed_color:        defb 0
ts__packed_base_page:   defb 0
ts__packed_saved_page:  defb 0
ts__packed_mapped_page: defb 0
ts__packed_depth:       defb 0
