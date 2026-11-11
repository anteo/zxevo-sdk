IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET
        MODULE bc__video_vline_zx_run
SECTION code_clib
PUBLIC bc__video_vline_zx_run

; HL = first CPU address, B = row count (1..192), D = AND, E = XOR.
; CPU bases/planes are aligned, so the low three bits of H encode y & 7.
; Preserve IX/IY. No row counter in memory or static scratch.
;
; Paints one column in a ZX-layout plane, following its interleaved scanline
; addresses.
;
; Model:
;
; for (row=0; row<count; ++row) { paint(address); address=next_zx_scanline(address); }
;
; Native in-bounds run, register ABI above. AF/B/HL volatile, C/DE/IX/IY
; preserved. Next row increments H; when its low three bits wrap, add 32 to L
; and subtract 8 from H only without L carry. At a screen-third boundary the
; L carry deliberately retains the H increment.
bc__video_vline_zx_run:
@row:
        ld a,(hl)
        and d
        xor e
        ld (hl),a
        djnz @next
        ret
@next:
        inc h
        ld a,h
        and 7
        jr nz,@row
        ld a,l
        add a,32
        ld l,a
        jr c,@row
        ld a,h
        sub 8
        ld h,a
        jr @row
ENDIF
