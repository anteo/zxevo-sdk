        MODULE zx__mem_read_sp
SECTION code_clib
PUBLIC _zx__mem_read_sp

; Return the entry SP in HL, including this CALL's two-byte return address.
; No arguments; A/BC/DE/IX/IY preserved, HL and ADD arithmetic flags change.
; Does not return the caller's pre-CALL stack pointer.
_zx__mem_read_sp:
        ld hl,0
        add hl,sp
        ret
