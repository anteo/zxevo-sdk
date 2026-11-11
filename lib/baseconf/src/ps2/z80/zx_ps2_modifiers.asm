        MODULE zx_ps2_modifiers
SECTION code_clib
PUBLIC _zx_ps2_modifiers
EXTERN _zx__rtc_scope_begin
EXTERN _zx__rtc_scope_end
EXTERN _zx__rtc_read_scoped

; Read the single modifier byte and zero-extend it into the shared mask.
;
; if (!modifiers) return INVALID_ARGUMENT;
; scope = rtc_scope_begin(); sample = rtc_read_scoped(0x0d);
; if (!(sample & 0x80)) status = UNSUPPORTED;
; else if (sample == 0xff && rtc_read_scoped(0x0b) == 0xff) status = UNAVAILABLE;
; else status = OK;
; rtc_scope_end(scope);
; if (status == OK) *modifiers = sample & 0x7f;
; return status;
;
; SDCC output pointer at SP+2, status in L. Keep the pointer and scope
; on the stack. E holds the sample and D the status across scope restoration.
; AF/BC/DE/HL volatile, IX/IY preserved.
_zx_ps2_modifiers:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        push de
        call _zx__rtc_scope_begin
        push hl
        ld l,0Dh
        call _zx__rtc_read_scoped
        ld e,l
        ld d,5                       ; ZX_UNSUPPORTED without the AVR marker
        bit 7,e
        jr z,@restore
        ld d,0                       ; ZX_OK
        inc l
        jr nz,@restore
        ld l,0Bh                     ; Distinguish all pressed keys from open bus.
        call _zx__rtc_read_scoped
        inc l
        jr nz,@restore
        ld d,3                       ; ZX_UNAVAILABLE
@restore:
        pop hl
        call _zx__rtc_scope_end
        pop bc
        ld a,d
        or a
        jr nz,@status
        ld a,e
        and 7Fh
        ld (bc),a
        inc bc
        xor a
        ld (bc),a
@status:
        ld l,d
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
