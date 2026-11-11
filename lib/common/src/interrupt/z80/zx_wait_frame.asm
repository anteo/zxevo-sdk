        MODULE zx_wait_frame
SECTION code_clib
PUBLIC _zx_wait_frame

; Wait for the frame ISR's counter to change, ignoring other interrupt sources.
;
; if (!counter) return ZX_INVALID_ARGUMENT;
; if (!IFF2) return ZX_UNSAFE_CONTEXT;
; DI();
; previous = *counter;
; do { EI(); HALT(); DI(); } while (*counter == previous);
; EI();
; return ZX_OK;
;
; Fastcall HL = resident counter, L = status. The caller enables INT and
; installs a recurring frame ISR that updates the counter. D holds the
; snapshot. Clobber AF/D/HL, preserve BC/E/IX/IY and the entry INT state.
_zx_wait_frame:
        ld a,h
        or l
        jr z,@invalid
        ld a,i
        jp po,@disabled
        di
        ld d,(hl)
@wait:
        ; EI defers INT until HALT executes, closing the sample-to-wait race.
        ei
        halt
        di
        ld a,(hl)
        cp d
        jr z,@wait
        ld l,0                       ; ZX_OK
        ei
        ret
@disabled:
        ld l,6                       ; ZX_UNSAFE_CONTEXT
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
