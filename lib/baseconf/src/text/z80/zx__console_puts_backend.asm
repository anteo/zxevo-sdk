        MODULE zx__console_puts_backend
SECTION code_clib
PUBLIC zx__console_puts_backend
EXTERN zx__console_puts_chars
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_begin
EXTERN bc__text_put
EXTERN _bc__video_end
EXTERN _zx__console_text_bg

; Write a hardware text string under one video lease. Other surfaces
; use the common character loop.
;
; Model:
;
; if (!hardware_text_mode) return console_puts_chars(text);
; if (transparent) return UNSUPPORTED;
; if (video_begin()!=OK) return status;
; while (*text) text_put(*text++); return video_end();
;
; HL=validated nonempty string. String storage stays readable during one lease.
; Save the next-character pointer across text_put.
; AF/BC/DE/HL volatile; IX/IY preserved, status in L.
zx__console_puts_backend:
        ld a,(_bc_video_draw_surface_state)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jp nc,zx__console_puts_chars
        ld a,(_zx__console_text_bg)
        or a
        jr nz,@unsupported
        push hl
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@failed
        pop hl
@next:
        ld a,(hl)
        or a
        jp z,_bc__video_end
        inc hl
        push hl
        call bc__text_put
        pop hl
        jr @next
@failed:
        pop bc
        ret
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ELSE
defc zx__console_puts_backend = zx__console_puts_chars
ENDIF
