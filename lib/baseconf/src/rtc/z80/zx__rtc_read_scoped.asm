        MODULE zx__rtc_read_scoped
SECTION code_clib
PUBLIC _zx__rtc_read_scoped
PUBLIC bc__rtc_read_scoped_regs

; Select a register at DEF7h and read its byte from BEF7h.
; Caller owns the shadow-port scope and has masked INT. Fastcall L=index
; or register input A. Result in L. Native entry preserves DE/H/IX/IY.
_zx__rtc_read_scoped:
        ld a,l
bc__rtc_read_scoped_regs:
        ld bc,0DEF7h
        out (c),a
        ld b,0BEh
        in l,(c)
        ret
