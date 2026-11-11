        MODULE bc__text_putc
SECTION code_clib
PUBLIC bc__text_putc
EXTERN _bc__video_begin
EXTERN bc__text_put
EXTERN _bc__video_end
EXTERN _zx__console_text_bg

; SDCC character:8. One lease, including control characters. Preserve IX/IY.
;
; Processes one hardware text character or cursor control while holding a
; video lease.
;
; Model:
;
; if (transparent) return UNSUPPORTED;
; status=video_begin(); if (status!=OK) return status;
; text_put(character); return video_end();
;
; Caller has selected a hardware-text surface. Save the character across
; begin(). Status in L, AF/BC/DE/HL volatile; IX/IY preserved. Owns the lease.
bc__text_putc:
        ld a,(_zx__console_text_bg)
        or a
        ld l,5                       ; ZX_UNSUPPORTED
        ret nz
        ld hl,2
        add hl,sp
        ld a,(hl)
        push af
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@failed
        pop af
        call bc__text_put
        jp _bc__video_end
@failed:
        pop bc
        ret
