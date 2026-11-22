        MODULE bc__rtc_write_scoped_regs
SECTION code_clib
PUBLIC bc__rtc_write_scoped_regs

; Select a register at DEF7h and write its byte to BEF7h.
; Caller owns the shadow-port scope and has masked INT. SDCC index and value
; at SP+2/+3. Native entry takes A=index and E=value, clobbers BC only.
bc__rtc_write_scoped_regs:
        ld bc,0DEF7h
        out (c),a
        ld b,0BEh
        out (c),e
        ret
