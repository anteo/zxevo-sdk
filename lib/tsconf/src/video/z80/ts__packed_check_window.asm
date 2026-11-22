        MODULE ts__packed_check_window
EXTERN _ts__memory_window_owner
EXTERN ts__packed_base_page
EXTERN ts__packed_depth
SECTION code_clib
PUBLIC ts__packed_check_window

; Check whether a glyph can acquire W3 without changing the mapping.
; D=base page, carry means busy. Clobber AF/BC/HL.
ts__packed_check_window:
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        ret z
        ld bc,ts__packed_depth
        sbc hl,bc
        jr nz,@conflict
        ld a,(ts__packed_base_page)
        cp d
        jr nz,@conflict
        ld a,(ts__packed_depth)
        cp 255
        ccf
        ret
@conflict:
        scf
        ret
