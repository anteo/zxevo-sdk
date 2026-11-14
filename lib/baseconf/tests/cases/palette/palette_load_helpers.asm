        MODULE palette_load_helpers

SECTION code_user
PUBLIC _frame_irq_on
PUBLIC _iff_enabled
PUBLIC _sample_border_colors

; Install a tiny IM1 handler in writable W0 and enable frame interrupts.
; It preserves all registers and returns within the palette loader's 4096T
; post-HALT budget. No arguments or result; changes IM1, IFF and 0038h..003Ah.
_frame_irq_on:
        ld a,0fbh              ; EI
        ld (0038h),a
        ld a,0edh              ; RETI prefix
        ld (0039h),a
        ld a,04dh
        ld (003ah),a
        im 1
        ei
        ret

; Return 1 if interrupts were enabled on entry, otherwise 0.
; Result in L; changes AF/L and preserves the remaining registers and IFF.
_iff_enabled:
        ld l,0
        ld a,i
        ret po
        inc l
        ret

; Sample all 16 ATM RGB222 colors during one initial border interval.
; HL points to 16 writable bytes outside W0; returns with interrupts enabled.
; Changes AF/BC/DE/HL, preserves IX/IY. Requires the IM1 handler above.
;
; wait_frame(); DI();
; for (i = 0; i < 16; ++i) { border(i); out[i] = IN(0x0DBD) & 0xF3; }
; EI();
;
_sample_border_colors:
        halt
        di
        ld d,0
palette_sample_loop:
        ld a,d
        and 7
        ld bc,080fch
        bit 3,d
        jr z,palette_sample_border
        ld c,0f6h
palette_sample_border:
        out (c),a
        ld bc,00dbdh
        in a,(c)
        and 0f3h
        ld (hl),a
        inc hl
        inc d
        ld a,d
        cp 16
        jr nz,palette_sample_loop
        ei
        ret
