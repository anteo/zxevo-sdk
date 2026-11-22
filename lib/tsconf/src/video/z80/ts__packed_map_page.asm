        MODULE ts__packed_map_page
EXTERN ts__packed_mapped_page
SECTION code_clib
PUBLIC ts__packed_map_page
ts__packed_map_page:
        ld c,a
        ld a,(ts__packed_mapped_page)
        cp c
        ret z
        ld a,c
        ld (ts__packed_mapped_page),a
        ld bc,13afh
        out (c),a
        ret
