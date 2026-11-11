IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
        MODULE bc__video_shift_byte_row
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_shift_byte_row

; Shifts a contiguous bitmap row in place and fills the edge exposed by the
; shift.
;
; C model (contiguous logical bytes, overlap-safe traversal):
;
;   if (pixels == 8) memmove_one_byte_and_fill_edge(blank);
;   else for_each_byte_in_direction {
;       neighbor = at_edge ? 0 : adjacent_original_byte;
;       out = right ? (current >> pixels) | (neighbor << (8-pixels))
;                   : (current << pixels) | (neighbor >> (8-pixels));
;       write_current(out);
;   }
;
; HL = row start, B = count (1..255), C = pixels (1..8).
; IX shared scroll frame supplies direction and blank (blank used for 8 only).
; Preserve IX/IY; clobber AF/BC/DE/HL. A saved destination address on the stack
; lets HL advance once; the neighbor is read before its predecessor is written.
bc__video_shift_byte_row:
        ld a,c
        cp 8
        jr z,@whole_byte
        ld a,(ix+BC_SCROLL_RIGHT)
        or a
        jr nz,@right
@left:
        ld d,(hl)
        push hl
        ld a,b
        dec a
        jr z,@left_edge
        inc hl
        ld e,(hl)
        jr @left_shift
@left_edge:
        ld e,0
@left_shift:
        ld a,c
@left_bits:
        sla e
        rl d
        dec a
        jr nz,@left_bits
        ld a,d
        pop de
        ld (de),a
        djnz @left
        ret
@right:
        ld e,b
        dec e
        ld d,0
        add hl,de
@right_byte:
        ld d,(hl)
        push hl
        ld a,b
        dec a
        jr z,@right_edge
        dec hl
        ld e,(hl)
        jr @right_shift
@right_edge:
        ld e,0
@right_shift:
        ld a,c
@right_bits:
        srl e
        rr d
        dec a
        jr nz,@right_bits
        ld a,d
        pop de
        ld (de),a
        djnz @right_byte
        ret

; A full-byte shift uses LDIR/LDDR rather than eight bit iterations per byte.
@whole_byte:
        ld a,b
        dec a
        jr z,@single
        ld a,(ix+BC_SCROLL_RIGHT)
        or a
        jr nz,@whole_right
        ld a,b
        dec a
        ld c,a
        ld b,0
        ld e,l
        ld d,h
        inc hl
        ldir
        jr @fill_de
@whole_right:
        ld e,b
        dec e
        ld d,0
        add hl,de                    ; last destination
        ld e,l
        ld d,h
        dec hl                       ; last source
        ld a,b
        dec a
        ld c,a
        ld b,0
        lddr
@fill_de:
        ld a,(ix+BC_SCROLL_BLANK)
        ld (de),a
        ret
@single:
        ld a,(ix+BC_SCROLL_BLANK)
        ld (hl),a
        ret
ENDIF
