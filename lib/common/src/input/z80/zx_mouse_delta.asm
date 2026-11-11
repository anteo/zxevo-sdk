        MODULE zx_mouse_delta

SECTION code_clib
PUBLIC _zx_mouse_delta

; Calculate signed movement across counter wraparound and copy current buttons.
; Model:
;
; int8_t dx = (int8_t)(current->x - previous->x);
; int8_t dy = (int8_t)(current->y - previous->y);
; uint8_t wheel = (current->wheel - previous->wheel) & 15;
; return (zx_mouse_delta_t){dx, dy, (wheel ^ 8) - 8, current->buttons};
;
; SDCC caller-clean ABI at entry: hidden result pointer at SP+2, previous at
; SP+4, current at SP+6. Both snapshots must be readable and non-NULL. Poll
; within the signed ranges for unambiguous deltas (-128..127, wheel -8..7).
; Preserve IX/IY, clobber AF/BC/DE/HL. The only local is the saved result
; pointer at the top of the stack. Read both snapshots before writing output.
_zx_mouse_delta:
        ld hl,7
        add hl,sp
        ld b,(hl)
        dec hl
        ld c,(hl)                    ; BC = current
        dec hl
        ld d,(hl)
        dec hl
        ld e,(hl)                    ; DE = previous
        dec hl
        ld a,(hl)
        dec hl
        ld l,(hl)
        ld h,a
        push hl                      ; save result pointer while reading inputs
        ex de,hl                     ; HL = previous

        ld a,(bc)
        sub (hl)                     ; low byte is already the signed delta
        ld d,a                       ; dx
        inc bc
        inc hl
        ld a,(bc)
        sub (hl)
        ld e,a                       ; dy
        inc bc
        inc hl
        ld a,(bc)
        sub (hl)
        and 0Fh
        xor 8                        ; sign-extend the nibble: 8..15 become -8..-1
        sub 8
        ld l,a                       ; wheel delta
        inc bc
        ld a,(bc)
        ld h,a                       ; buttons

        pop bc                       ; BC = result
        ld a,d
        ld (bc),a
        inc bc
        ld a,e
        ld (bc),a
        inc bc
        ld a,l
        ld (bc),a
        inc bc
        ld a,h
        ld (bc),a
        ret
