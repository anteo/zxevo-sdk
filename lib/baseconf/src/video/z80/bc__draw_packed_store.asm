        MODULE bc__draw_packed_store
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
SECTION code_graphics
PUBLIC bc__draw_packed_store

; A=color, HL=address, B=0 for left pixel or 1 for right pixel.
; Replaces one pixel in a packed byte and leaves the other pixel unchanged.
;
; Model:
;
; selected=pack_selected(color&15,side);
; *address=(*address & (side?0x47:0xb8)) | selected;
;
; A=color,HL=address,B=side. AF/C/DE volatile; B/HL/IX/IY preserved.
; Left mask 47h covers RGB bits 0..2 plus bright bit 6; right B8h covers
; RGB bits 3..5 plus bright bit 7. Neighbouring pixel bits survive.
bc__draw_packed_store:
        and 0fh
        ld d,a
        bit 0,b
        jr nz,bc_circle_packed_store_right
        ld a,d
        and 7
        ld c,a
        ld a,d
        and 8
        rlca
        rlca
        rlca
        or c
        ld c,a
        ld a,(hl)
        and 0b8h
        or c
        ld (hl),a
        ret
bc_circle_packed_store_right:
        ld a,d
        and 7
        rlca
        rlca
        rlca
        ld c,a
        ld a,d
        and 8
        rlca
        rlca
        rlca
        rlca
        or c
        ld c,a
        ld a,(hl)
        and 047h
        or c
        ld (hl),a
        ret
ENDIF
