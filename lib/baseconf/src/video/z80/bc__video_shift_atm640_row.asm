IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        MODULE bc__video_shift_atm640_row
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_shift_atm640_row

; Logical byte address(k) = row_origin + (k/2) + ((k&1) ? 0x2000 : 0).
;
; Shifts one ATM640 scanline in place across its alternating planes, visiting
; bytes in the order needed to preserve source pixels.
;
; C model, traversing toward the exposed edge:
;
;   neighbor = at_edge ? blank : original_byte(k + (right ? -1 : 1));
;   if (pixels == 8) out = neighbor;
;   else out = right ? (current >> pixels) | (neighbor << (8-pixels))
;                    : (current << pixels) | (neighbor >> (8-pixels));
;   byte(k) = out;
;
; HL = page/plane0 row origin, C = pixels (1..8); direction/blank come from IX.
; Preserve IX/IY; clobber AF/BC/DE/HL. Bitmap blank is zero; attribute rows are
; called only with pixels==8 and the encoded attribute as blank.
; No gather/scatter: save the current destination, advance HL to its neighbor,
; read before writing, then pop the destination into DE. Only two stack bytes
; are needed while processing a byte; no persistent row scratch exists.
bc__video_shift_atm640_row:
        ld b,80
        ld a,(ix+BC_SCROLL_RIGHT)
        or a
        jr nz,@right
@left:
        ld d,(hl)
        push hl
        ld a,b
        dec a
        jr z,@left_edge
        call @next
        ld e,(hl)
        jr @left_combine
@left_edge:
        ld e,(ix+BC_SCROLL_BLANK)
@left_combine:
        ld a,c
        cp 8
        jr z,@left_whole
@left_bits:
        sla e
        rl d
        dec a
        jr nz,@left_bits
        ld a,d
        jr @left_store
@left_whole:
        ld a,e
@left_store:
        pop de
        ld (de),a
        djnz @left
        ret
@right:
        ld de,2027h                  ; plane1, final group (39)
        add hl,de
@right_byte:
        ld d,(hl)
        push hl
        ld a,b
        dec a
        jr z,@right_edge
        call @prev
        ld e,(hl)
        jr @right_combine
@right_edge:
        ld e,(ix+BC_SCROLL_BLANK)
@right_combine:
        ld a,c
        cp 8
        jr z,@right_whole
@right_bits:
        srl e
        rr d
        dec a
        jr nz,@right_bits
        ld a,d
        jr @right_store
@right_whole:
        ld a,e
@right_store:
        pop de
        ld (de),a
        djnz @right_byte
        ret

; These address-only steps preserve BC/DE/IX/IY. Plane0 -> plane1 stays in the
; same group; plane1 -> plane0 advances the group. Reverse that order for prev.
@next:
        ld a,h
        xor 20h
        ld h,a
        bit 5,h
        ret nz
        inc hl
        ret
@prev:
        bit 5,h
        jr nz,@toggle
        dec hl
@toggle:
        ld a,h
        xor 20h
        ld h,a
        ret
ENDIF
