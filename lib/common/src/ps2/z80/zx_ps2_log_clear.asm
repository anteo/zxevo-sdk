        MODULE zx_ps2_log_clear
SECTION code_clib
PUBLIC _zx_ps2_log_clear
EXTERN _zx__rtc_scope_begin
EXTERN _zx__rtc_scope_end
EXTERN _zx__rtc_read_scoped
EXTERN _zx__rtc_write_scoped

; Clear the AVR log while preserving its Caps LED and EEPROM mux.
;
; scope = rtc_scope_begin(); control = rtc_read_scoped(0x0c);
; if (control != 0xff) rtc_write_scoped(0x0c, (control & 0x82) | 1);
; rtc_scope_end(scope); return control == 0xff ? UNAVAILABLE : OK;
;
; SDCC no arguments, status in L. The stack holds the opaque scope and
; the packed write arguments. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_ps2_log_clear:
        call _zx__rtc_scope_begin
        push hl
        ld l,0Ch
        call _zx__rtc_read_scoped
        ld a,l
        inc a
        jr z,@unavailable
        ld a,l
        and 82h
        or 1
        ld h,a
        ld l,0Ch
        push hl
        call _zx__rtc_write_scoped
        pop bc
        pop hl
        call _zx__rtc_scope_end
        ld l,0                       ; ZX_OK
        ret
@unavailable:
        pop hl
        call _zx__rtc_scope_end
        ld l,3                       ; ZX_UNAVAILABLE
        ret
