; Direct Z80 pixel callbacks for the remaining BaseConf bitmap formats.
; The selected entry is mode/operation-specific; callbacks never inspect the
; video mode or touch paging ports.

        MODULE bc_draw_pixel_modes
SECTION code_graphics
EXTERN _bc__draw_clip_point
EXTERN zx__masks
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__ink
EXTERN zx__paper

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
PUBLIC _bc__draw_atm640_set
PUBLIC _bc__draw_atm640_clear
PUBLIC _bc__draw_atm640_xor
PUBLIC _bc__draw_atm640_set_clipped
PUBLIC _bc__draw_atm640_clear_clipped
PUBLIC _bc__draw_atm640_xor_clipped
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
PUBLIC _bc__draw_pentagon_set
PUBLIC _bc__draw_pentagon_clear
PUBLIC _bc__draw_pentagon_xor
PUBLIC _bc__draw_pentagon_set_clipped
PUBLIC _bc__draw_pentagon_clear_clipped
PUBLIC _bc__draw_pentagon_xor_clipped
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
PUBLIC _bc__draw_atm320_set
PUBLIC _bc__draw_atm320_clear
PUBLIC _bc__draw_atm320_xor
PUBLIC _bc__draw_atm320_set_clipped
PUBLIC _bc__draw_atm320_clear_clipped
PUBLIC _bc__draw_atm320_xor_clipped
ENDIF

; ATM 640 stores the bitmap in page1, with every second 8-pixel group in the
; second 8K plane. Attributes are left to the normal video setup.
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
; Sets the ATM640 bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) set_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm640_set_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm640_set
; Clears the ATM640 bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) clear_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm640_clear_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm640_clear
; Toggles the ATM640 bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) xor_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm640_xor_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm640_xor

; Sets one ATM640 bitmap pixel while retaining the other bits in its byte.
;
; Model:
;
; *bitmap |= mask;
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm640_set:
        call bc_draw_atm640_address
        or (hl)
        ld (hl),a
        ret
; Clears one ATM640 bitmap pixel while retaining the other bits in its byte.
;
; Model:
;
; *bitmap &= (uint8_t)~mask;
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm640_clear:
        call bc_draw_atm640_address
        cpl
        and (hl)
        ld (hl),a
        ret
; Toggles one ATM640 bitmap pixel without changing its attribute.
;
; Model:
;
; *bitmap ^= mask;
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm640_xor:
        call bc_draw_atm640_address
        xor (hl)
        ld (hl),a
        ret

; Resolves an ATM640 pixel to its bitmap plane address and the bit that
; selects it.
;
; Model:
;
; address=page1_base+y*40+(x>>4)+((x&8)?0x2000:0); mask=0x80>>(x&7).
;
; HL=x,DE=y -> HL=address,A=mask. Active mapped bitmap, x<640,y<200 required.
; AF/BC/DE/HL volatile; IX/IY preserved. High X bits participate in x/16;
; the logical-byte parity x bit 3 alone selects the plane.
bc_draw_atm640_address:
        ld a,l
        and 7
        push af
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        add hl,hl
        add hl,hl
        add hl,hl                     ; 8*y
        push hl
        add hl,hl
        add hl,hl                     ; 32*y
        pop bc
        add hl,bc                     ; 40*y
        pop bc                        ; x
        bit 3,c
        jr z,bc_circle_atm640_bank_ready
        ld de,02000h
        add hl,de
bc_circle_atm640_bank_ready:
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c                         ; x/16
        ld e,c
        ld d,0
        add hl,de
        ld bc,(_bc_video_page1_base)
        add hl,bc
        push hl
        pop de
        pop af                        ; mask index
        ld c,a
        ld b,0
        ld hl,zx__masks
        add hl,bc
        ld a,(hl)
        ex de,hl
        ret
ENDIF

; Pentagon and ATM 320 use the same packed 4-bit pixel byte format. The mode
; determines only the byte offset; x bits select the already mapped page.
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
; Paints the point with the current ink color if it lies inside the Pentagon
; surface.
;
; Model:
;
; if (clip_point(x,y)) set_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_pentagon_set_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_pentagon_set
; Paints the point with the current paper color if it lies inside the
; Pentagon surface.
;
; Model:
;
; if (clip_point(x,y)) clear_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_pentagon_clear_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_pentagon_clear
; XORs the point with the current ink color if it lies inside the Pentagon
; surface.
;
; Model:
;
; if (clip_point(x,y)) xor_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_pentagon_xor_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_pentagon_xor
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
; Paints the point with the current ink color if it lies inside the ATM320
; surface.
;
; Model:
;
; if (clip_point(x,y)) set_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm320_set_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm320_set
; Paints the point with the current paper color if it lies inside the ATM320
; surface.
;
; Model:
;
; if (clip_point(x,y)) clear_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm320_clear_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm320_clear
; XORs the point with the current ink color if it lies inside the ATM320
; surface.
;
; Model:
;
; if (clip_point(x,y)) xor_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_atm320_xor_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_atm320_xor
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
; Replaces one Pentagon packed pixel with the current ink color while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(ink);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_pentagon_set:
        call bc_draw_pentagon_address
        ld a,(zx__ink)
        and 0fh
        jp bc_draw_packed_store
; Replaces one Pentagon packed pixel with the current paper color while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(paper);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_pentagon_clear:
        call bc_draw_pentagon_address
        ld a,(zx__paper)
        and 0fh
        jp bc_draw_packed_store
; Applies the current ink color as an XOR to one Pentagon packed pixel while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(decode_selected_field() ^ ink);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_pentagon_xor:
        call bc_draw_pentagon_address
        jp bc_draw_packed_xor
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
; Replaces one ATM320 packed pixel with the current ink color while retaining
; its neighbor.
;
; Model:
;
; replace_selected_field(ink);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm320_set:
        call bc_draw_atm320_address
        ld a,(zx__ink)
        and 0fh
        jp bc_draw_packed_store
; Replaces one ATM320 packed pixel with the current paper color while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(paper);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm320_clear:
        call bc_draw_atm320_address
        ld a,(zx__paper)
        and 0fh
        jp bc_draw_packed_store
; Applies the current ink color as an XOR to one ATM320 packed pixel while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(decode_selected_field() ^ ink);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm320_xor:
        call bc_draw_atm320_address
        jp bc_draw_packed_xor
ENDIF

; Return HL=byte address and B=x&1 for the packed byte's left/right pixel.
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
; Resolves a Pentagon pixel to its packed byte address and left or right
; position.
;
; Model:
;
; address=page_base[(x>>1)&1]+zx__offset(y,x>>3)+((x&4)?0x2000:0);
; side=x&1; return address,side;
;
; Native HL=x,DE=y -> HL=address,B=side. Requires x<256,y<192 and mapped pages;
; AF/BC/DE/HL volatile, IX/IY preserved. X bits select pair/page/plane separately.
bc_draw_pentagon_address:
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        ld a,e
        and 038h
        rlca
        rlca
        ld l,a
        ld a,e
        and 0c0h
        rrca
        rrca
        rrca
        ld h,a
        ld a,e
        and 7
        or h
        ld h,a
        pop bc                        ; x
        ld a,c
        and 1
        ld b,a                        ; packed side
        ld a,c
        srl a
        srl a
        srl a
        ld e,a
        ld d,0
        add hl,de                     ; x/8 byte within the ZX bitmap row
        bit 2,c
        jr z,bc_circle_pentagon_offset_ready
        ld de,02000h
        add hl,de
bc_circle_pentagon_offset_ready:
        bit 1,c
        jr nz,bc_circle_pentagon_page1
        ld de,(_bc_video_page0_base)
        add hl,de
        ret
bc_circle_pentagon_page1:
        ld de,(_bc_video_page1_base)
        add hl,de
        ret
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
; Resolves an ATM320 pixel to its packed byte address and left or right
; position.
;
; Model:
;
; address=page_base[(x>>1)&1]+y*40+(x>>3)+((x&4)?0x2000:0);
; side=x&1; return address,side;
;
; Native HL=x,DE=y -> HL=address,B=side. Requires x<320,y<200 and mapped pages;
; AF/BC/DE/HL volatile, IX/IY preserved. Saved side/page AF values are private
; stack temporaries, not fields in a shared C request.
bc_draw_atm320_address:
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        add hl,hl
        add hl,hl
        add hl,hl                     ; 8*y
        push hl
        add hl,hl
        add hl,hl                     ; 32*y
        pop de
        add hl,de                     ; 40*y
        pop bc                        ; x
        ld a,c
        and 1
        push af                       ; packed side
        ld a,c
        and 2
        push af                       ; selected physical page
        bit 2,c
        jr z,bc_circle_atm320_offset_ready
        ld de,02000h
        add hl,de
bc_circle_atm320_offset_ready:
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c                         ; x/8
        ld e,c
        ld d,0
        add hl,de
        pop af
        or a
        jr nz,bc_circle_atm320_page1
        ld de,(_bc_video_page0_base)
        add hl,de
        pop af
        ld b,a
        ret
bc_circle_atm320_page1:
        ld de,(_bc_video_page1_base)
        add hl,de
        pop af
        ld b,a
        ret
ENDIF

; A=color, HL=address, B=0 for left pixel or 1 for right pixel.
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
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
bc_draw_packed_store:
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

; Toggles the selected packed pixel color with the current ink bits and
; writes it back.
;
; Model:
;
; color=decode(*address,side)^ink; store_selected(address,side,color);
;
; HL=address,B=side; active mapped pair required. AF/BC/DE volatile, HL/IX/IY
; preserved. Re-enter the same selected-field encoder, retaining the other pixel.
bc_draw_packed_xor:
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
        jp bc_draw_packed_store
ENDIF
