        MODULE ts_packed_address256
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_map_relative
SECTION code_clib
PUBLIC ts_packed_address256

ts_packed_address256:
        ld a,e
        and 31                       ; 32 scanlines per page
        add a,a
        or h                         ; X bit 8 selects the second 256 bytes
        or 0c0h
        ld h,a
        ld a,e
        rlca
        rlca
        rlca
        and 7
        ld b,a
        ld a,d
        add a,a
        add a,a
        add a,a
        or b
        jp ts_packed_map_relative
ENDIF
