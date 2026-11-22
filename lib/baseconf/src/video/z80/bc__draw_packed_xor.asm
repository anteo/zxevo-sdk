        MODULE bc__draw_packed_xor
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
EXTERN bc__draw_packed_store
EXTERN zx__ink
SECTION code_graphics
PUBLIC bc__draw_packed_xor

; Toggles the selected packed pixel color with the current ink bits and
; writes it back.
;
; Model:
;
; color=decode(*address,side)^ink; store_selected(address,side,color);
;
; HL=address,B=side; active mapped pair required. AF/BC/DE volatile, HL/IX/IY
; preserved. Re-enter the same selected-field encoder, retaining the other pixel.
bc__draw_packed_xor:
        ld d,b                        ; preserve packed side
        ld c,(hl)
        bit 0,b
        jr nz,bc_circle_packed_xor_right
        ld a,c
        and 7
        ld e,a
        ld a,c
        and 040h
        rrca
        rrca
        rrca
        or e
        jr bc_circle_packed_xor_apply
bc_circle_packed_xor_right:
        ld a,c
        and 038h
        rrca
        rrca
        rrca
        ld e,a
        ld a,c
        and 080h
        rrca
        rrca
        rrca
        rrca
        or e
bc_circle_packed_xor_apply:
        ld e,a
        ld a,(zx__ink)
        xor e
        ld b,d
        jp bc__draw_packed_store
ENDIF
