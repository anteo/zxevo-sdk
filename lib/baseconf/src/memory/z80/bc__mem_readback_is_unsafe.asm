        MODULE bc__mem_readback_is_unsafe
SECTION code_clib
PUBLIC _bc__mem_readback_is_unsafe

; Detect a floating readback port before selecting the backend.
;
; port = 0xbd + backend;
; for (index = 0; index < 0x0a; ++index)
;     if (in((index << 8) | port) != 0xff) return 0;
; return in(0x1200 | port) == 0xff;
;
; Fastcall L = backend (0 or 1), L = 1 if all memory registers read FF.
; Reads the pages, RAM/ROM and substitution bits, then write protection.
; Clobber AF/BC/L. Preserve DE/H/IX/IY. No writes or changes to the cache.
_bc__mem_readback_is_unsafe:
        ld a,l
        add a,0bdh
        ld c,a
        ld b,0
@scan:
        in a,(c)
        inc a
        jr nz,@available
        inc b
        ld a,b
        cp 0ah
        jr c,@scan
        ld b,12h
        in a,(c)
        inc a
        jr nz,@available
        ld l,1
        ret
@available:
        ld l,0
        ret
