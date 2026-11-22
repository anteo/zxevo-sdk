        MODULE ts_packed_map_relative
EXTERN ts__packed_base_page
EXTERN ts__packed_map_page
SECTION code_clib
PUBLIC ts_packed_map_relative

; A=relative page. Switch only when needed. Preserve HL/DE/IX/IY.
ts_packed_map_relative:
        ld c,a
        ld a,(ts__packed_base_page)
        add a,c
        jp ts__packed_map_page
