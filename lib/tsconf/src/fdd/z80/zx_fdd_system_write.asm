        MODULE zx_fdd_system_write
SECTION code_clib
PUBLIC _zx_fdd_system_write
EXTERN _zx__fdd_system_byte

; Write the drive select, side, head-ready and active-low reset latch.
;
; byte = encode_system_latch(cfg);
; if (byte == 0xff) return ZX_INVALID_ARGUMENT;
; out(0xff, byte);
; return ZX_OK;
;
; Fastcall HL = pointer to four successive byte fields. Status in L.
; Beta Disk ports must be open and the selected drive physical.
; Clobber AF/BC/E/HL, preserve D/IX/IY.
_zx_fdd_system_write:
        call _zx__fdd_system_byte
        ld a,l
        inc a
        jr z,@invalid
        ld bc,00FFh
        out (c),l
        ld l,0                      ; ZX_OK
        ret
@invalid:
        ld l,1                      ; ZX_INVALID_ARGUMENT
        ret
