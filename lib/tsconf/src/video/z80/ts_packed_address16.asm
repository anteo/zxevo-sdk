        MODULE ts_packed_address16
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_map_relative
SECTION code_clib
PUBLIC ts_packed_address16

; Resolve a packed pixel to its containing CPU byte and map the page in W3.
;
; offset = 16c ? 256*y + (x>>1) : 512*y + x;
; map_relative(offset >> 14); return 0xc000 + (offset & 0x3fff);
;
; HL=x, DE=y, both below 512. Return HL=CPU byte. Caller owns W3 and
; has begun an operation. AF/BC volatile, DE/IX/IY preserved.
ts_packed_address16:
        srl h
        rr l
        ld a,e
        and 3fh                      ; 64 scanlines per page
        or 0c0h
        ld h,a
        ld a,e
        rlca
        rlca
        and 3
        ld b,a
        ld a,d
        add a,a
        add a,a
        or b
        jp ts_packed_map_relative
ENDIF
