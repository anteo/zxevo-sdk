        MODULE zx__fdd_system_byte
SECTION code_clib
PUBLIC _zx__fdd_system_byte

; Validate a system-latch descriptor and encode its low five bits.
;
; if (!cfg || cfg->drive > 3 || cfg->side > 1 ||
;     cfg->hrdy > 1 || cfg->reset > 1) return 0xff;
; return cfg->drive | (cfg->side << 4) | (cfg->hrdy << 3) |
;        (cfg->reset ? 0 : 4);
;
; Fastcall HL=descriptor (four bytes), L=encoded value or FFh.
; Clobber AF/E/HL, preserve BC/D/IX/IY. No hardware access.
_zx__fdd_system_byte:
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        cp 4
        jr nc,@invalid
        ld e,a
        inc hl
        ld a,(hl)
        cp 2
        jr nc,@invalid
        or a
        jr z,@head
        set 4,e
@head:
        inc hl
        ld a,(hl)
        cp 2
        jr nc,@invalid
        or a
        jr z,@reset
        set 3,e
@reset:
        inc hl
        ld a,(hl)
        cp 2
        jr nc,@invalid
        or a
        jr nz,@done
        set 2,e
@done:
        ld l,e
        ret
@invalid:
        ld l,0ffh
        ret
