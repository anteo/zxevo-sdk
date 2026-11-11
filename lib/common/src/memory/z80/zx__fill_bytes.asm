        MODULE zx__fill_bytes
SECTION code_clib
PUBLIC zx__fill_bytes

; Fills the supplied CPU memory range with one byte value.
;
; C model:
;
; if (length) memset(address, value, length);
;
; HL = writable CPU address, BC = length, A = value. Return HL at the last
; filled byte, or unchanged for length zero. AF/BC/DE volatile, IX/IY preserved.
; The caller validates the range and mapping.
; Replicate one initialized byte with forward-overlapping LDIR; lengths 0/1
; return before LDIR, whose BC=0 encoding would copy 65536 bytes.
zx__fill_bytes:
        ld e,a
        ld a,b
        or c
        ret z
        ld (hl),e
        dec bc
        ld a,b
        or c
        ret z
        ld d,h
        ld e,l
        inc de
        ldir
        ret
