        MODULE zx_console_get_size
SECTION code_clib
PUBLIC _zx_console_get_size
EXTERN __console_w

; Report the geometry maintained by surface and font selection.
; Fastcall HL=output, L=status.
; Preserve IX/IY. Leave memory untouched if the pointer is NULL.
_zx_console_get_size:
        ld a,h
        or l
        jr z,@invalid
        ld de,(__console_w)
        ld (hl),e
        inc hl
        ld (hl),d
        ld l,0
        ret
@invalid:
        ld l,1
        ret
