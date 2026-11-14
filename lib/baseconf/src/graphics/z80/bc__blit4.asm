        MODULE bc__blit4
INCLUDE "graphics/z80/blit4.inc"
SECTION code_graphics
PUBLIC zx__blit4_begin
PUBLIC zx__blit4_span
PUBLIC zx__blit4_end
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
EXTERN _bc_video_surface_selected
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN _bc__video_begin
EXTERN _bc__video_end
ENDIF

; Acquire the already mapped ATM320 surface without pulling pixel primitives
; or unrelated video modes into the blitter's archive dependencies.
;
; if (!selected) return NOT_INITIALIZED;
; if (mode != ATM320) return UNSUPPORTED;
; status=video_begin(); return status,320,200;
;
; IX=common blitter frame. L=status, BC/DE=bounds on success.
; AF/BC/DE/HL volatile; IX/IY preserved. Source must not alias either page.
zx__blit4_begin:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        ld a,(_bc_video_surface_selected)
        or a
        ld l,4
        ret z
        ld a,(_bc_video_draw_surface_state)
        cp 3                         ; BC_VIDEO_ATM_320
        jr nz,@unsupported
        call _bc__video_begin
        ld bc,320
        ld de,200
        ret
@unsupported:
ENDIF
        ld l,5
        ret

; Balance a successful begin. Status in L; IX/IY preserved.
zx__blit4_end:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        jp _bc__video_end
ELSE
        ld l,0
        ret
ENDIF

; Translate one clipped linear row to the four ATM320 packed parts.
;
; address=page[(x>>1)&1]+40*y+(x>>3)+((x&4)?0x2000:0);
; for each source pixel {
;     color=next_nibble();
;     if (color!=key) replace_selected_pixel(address,x&1,color);
;     ++x; advance_address_on_pair_boundary();
; }
;
; IX=common frame, including scratch COUNT/SRC_HALF/DEST_PHASE. The acquired
; video operation supplies two aligned writable CPU bases. No paging or C
; calls occur here. HL=destination, DE=source while looping; BC/AF volatile.
; No source pointer/frame fields used by the next row are modified. IX/IY
; preserved. A pair uses left mask47h and rightmaskB8h, not normal nibbles.
zx__blit4_span:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        ld l,(ix+BLIT_Y)
        ld h,(ix+BLIT_Y+1)
        add hl,hl
        add hl,hl
        add hl,hl                    ; 8*y
        ld d,h
        ld e,l
        add hl,hl
        add hl,hl                    ; 32*y
        add hl,de                    ; row=40*y
        ld c,(ix+BLIT_X)
        ld b,(ix+BLIT_X+1)
        ld a,c
        and 7
        ld (ix+BLIT_DEST_PHASE),a
        bit 2,c
        jr z,@plane_ready
        set 5,h                      ; second 8 KiB plane
@plane_ready:
        ld de,(_bc_video_page0_base)
        bit 1,c
        jr z,@page_ready
        ld de,(_bc_video_page1_base)
@page_ready:
        add hl,de
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c
        add hl,bc                    ; x/8 byte within the row
        ld a,(ix+BLIT_HALF)
        ld (ix+BLIT_SRC_HALF),a
        ld c,(ix+BLIT_WIDTH)
        ld b,(ix+BLIT_WIDTH+1)
        ld (ix+BLIT_COUNT),c
        ld (ix+BLIT_COUNT+1),b
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
@pixel:
        ld a,(de)
        bit 0,(ix+BLIT_SRC_HALF)
        jr nz,@source_low
        set 0,(ix+BLIT_SRC_HALF)
        rrca
        rrca
        rrca
        rrca
        jr @source_ready
@source_low:
        res 0,(ix+BLIT_SRC_HALF)
        inc de
@source_ready:
        and 15
        cp (ix+BLIT_KEY)
        jr z,@advance
        ld b,a
        bit 0,(ix+BLIT_DEST_PHASE)
        jr nz,@right
        and 7
        ld c,a
        ld a,b
        and 8
        rlca
        rlca
        rlca                         ; left brightness -> bit 6
        or c
        ld b,a
        ld a,(hl)
        and 0b8h                     ; retain right pixel
        or b
        ld (hl),a
        jr @advance
@right:
        and 7
        rlca
        rlca
        rlca
        ld c,a
        ld a,b
        and 8
        rlca
        rlca
        rlca
        rlca                         ; right brightness -> bit 7
        or c
        ld b,a
        ld a,(hl)
        and 047h                     ; retain left pixel
        or b
        ld (hl),a
@advance:
        inc (ix+BLIT_DEST_PHASE)
        ld a,(ix+BLIT_DEST_PHASE)
        and 7
        ld (ix+BLIT_DEST_PHASE),a
        and 1
        jr nz,@count
        ld a,(ix+BLIT_DEST_PHASE)
        or a
        jr z,@next_group
        cp 4
        jr z,@second_plane
        ; Pairs 1/3 select page1 while retaining the plane and byte offset.
        ld a,h
        and 03fh
        ld b,a
        ld a,(_bc_video_page1_base+1)
        or b
        ld h,a
        jr @count
@second_plane:
        ld a,h
        and 03fh
        or 020h
        jr @page0
@next_group:
        ld a,h
        and 01fh                     ; pair3 -> pair0, drop plane2000h
        ld b,a
        ld a,(_bc_video_page0_base+1)
        or b
        ld h,a
        inc hl                       ; next group of eight pixels
        jr @count
@page0:
        ld b,a
        ld a,(_bc_video_page0_base+1)
        or b
        ld h,a
@count:
        ld c,(ix+BLIT_COUNT)
        ld b,(ix+BLIT_COUNT+1)
        dec bc
        ld (ix+BLIT_COUNT),c
        ld (ix+BLIT_COUNT+1),b
        ld a,b
        or c
        jp nz,@pixel
ENDIF
        ret
