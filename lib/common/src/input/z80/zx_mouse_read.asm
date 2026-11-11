        MODULE zx_mouse_read

SECTION code_clib
PUBLIC _zx_mouse_read

; Read the raw Kempston mouse counters and pressed buttons into a snapshot.
; Model:
;
; if (!snapshot) return ZX_INVALID_ARGUMENT;
; uint8_t flags = IN(0xfadf);
; snapshot->x = IN(0xfbdf);
; snapshot->y = IN(0xffdf);
; snapshot->wheel = flags >> 4;
; snapshot->buttons = ~flags & 7;
; return ZX_OK;
;
; SDCC caller-clean ABI: snapshot pointer at SP+2, status in L. The caller
; supplies a writable snapshot or NULL. Preserve BC/IX/IY, clobber AF/DE/HL.
; No local stack storage.
_zx_mouse_read:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret z

        ld a,0FAh                    ; IN A,(n) puts the old A on address bits 15..8
        in a,(0DFh)
        ld h,a
        ld a,0FBh
        in a,(0DFh)
        ld (de),a
        inc de
        ld a,0FFh
        in a,(0DFh)
        ld (de),a
        inc de

        ld a,h                       ; high nibble is the wheel counter
        rrca
        rrca
        rrca
        rrca
        and 0Fh
        ld (de),a
        inc de
        ld a,h                       ; bits 2..0 are active-low buttons
        cpl
        and 7
        ld (de),a
        ld l,0                       ; ZX_OK
        ret
