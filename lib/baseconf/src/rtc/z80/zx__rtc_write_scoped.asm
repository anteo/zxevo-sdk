        MODULE zx__rtc_write_scoped
SECTION code_clib
PUBLIC _zx__rtc_write_scoped
PUBLIC bc__rtc_write_scoped_regs

; Select a register at DEF7h and write its byte to BEF7h.
; Caller owns the shadow-port scope and has masked INT. SDCC index and value
; at SP+2/+3. Native entry takes A=index and E=value, clobbers BC only.
_zx__rtc_write_scoped:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
bc__rtc_write_scoped_regs:
        ld bc,0DEF7h
        out (c),a
        ld b,0BEh
        out (c),e
        ret
