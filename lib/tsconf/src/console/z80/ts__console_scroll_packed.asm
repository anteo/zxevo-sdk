        MODULE ts__console_scroll_packed
SECTION code_clib
IFDEF TSCONF_VIDEO_PACKED
PUBLIC ts__console_scroll_packed
EXTERN ts_draw_config
EXTERN ts_draw_page
EXTERN ts__video_raster_cells
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
EXTERN zx__paper
EXTERN zx__fill_bytes
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_address256
ENDIF

defc TS_SCROLL_MODE = -1
defc TS_SCROLL_ROW = -4
defc TS_SCROLL_END = -6
defc TS_SCROLL_COPY_END = -8
defc TS_SCROLL_WIDTH = -10
defc TS_SCROLL_SCRATCH = -12
defc TS_SCROLL_FILL = -13

; Move the visible packed rectangle up eight scanlines and clear its tail.
;
; if (!begin_window(page)) return BUSY;
; for (y=0; y<height; ++y) {
;     if (y >= height-8) fill(row(y), paper_byte, width_in_bytes);
;     else if (page(y) == page(y+8)) copy(row(y), row(y+8), width_in_bytes);
;     else {
;         copy(scratch, row(y+8), width_in_bytes);
;         copy(row(y), scratch, width_in_bytes);
;     }
; }
; end_window(); return OK;
;
; A=mode, selected packed canvas. L=status. IX frames the saved fields.
; The stack below them reserves one visible byte row for page crossings.
; Code, stack, data and handlers must be resident outside W3. Preserve IX/IY,
; clobber AF/BC/DE/HL. Copying forward preserves source rows and pixels
; outside the raster rectangle. The page cache avoids redundant OUTs.
ts__console_scroll_packed:
        push af
        ld a,(ts_draw_page)
        ld d,a
        call ts_packed_begin_window
        pop bc                       ; B = mode; keep carry from begin
        ld l,2                       ; ZX_BUSY
        ret c
        ld a,b
        push ix
        ld ix,0
        add ix,sp
        push af
        ld hl,0
        push hl                      ; logical destination scanline

        ld a,(ts_draw_config)
        call ts__video_raster_cells  ; B=rows, C=width in eight-pixel units
        ld l,b
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        push hl                      ; raster height
        ld de,8
        or a
        sbc hl,de
        push hl                      ; first scanline of the vacated row

        ld l,c
        ld h,0
        add hl,hl
        add hl,hl                    ; 16c: four bytes per eight pixels
        ld a,(ix+TS_SCROLL_MODE)
        cp 2
        jr nz,@width_ready
        add hl,hl
@width_ready:
        push hl
        ld b,h
        ld c,l
        push hl                      ; scratch pointer slot
        ld a,(zx__paper)
        bit 0,(ix+TS_SCROLL_MODE)
        jr z,@paint_ready
        and 0fh
        ld d,a
        rlca
        rlca
        rlca
        rlca
        or d
@paint_ready:
        push af
        ld hl,0
        or a
        sbc hl,bc
        add hl,sp
        ld sp,hl
        ld (ix+TS_SCROLL_SCRATCH),l
        ld (ix+TS_SCROLL_SCRATCH+1),h

@row:
        ld l,(ix+TS_SCROLL_ROW)
        ld h,(ix+TS_SCROLL_ROW+1)
        ld e,(ix+TS_SCROLL_COPY_END)
        ld d,(ix+TS_SCROLL_COPY_END+1)
        or a
        sbc hl,de
        jr nc,@fill

        ; y+8 crosses a page only in its last eight scanlines.
        ld a,(ix+TS_SCROLL_ROW)
        bit 0,(ix+TS_SCROLL_MODE)
        jr z,@boundary_256
        and 3fh
        cp 56
        jr nc,@cross
        jr @local
@boundary_256:
        and 1fh
        cp 24
        jr nc,@cross
@local:
        call @destination
        ld d,h
        ld e,l
        ld a,16                      ; 256c: 8*512 bytes = 16 high-byte units
        bit 0,(ix+TS_SCROLL_MODE)
        jr z,@local_source
        ld a,8                       ; 16c: 8*256 bytes
@local_source:
        add a,h
        ld h,a
        call @copy_width
        jr @advance

@cross:
        ld e,(ix+TS_SCROLL_ROW)
        ld d,(ix+TS_SCROLL_ROW+1)
        ld hl,8
        add hl,de
        ex de,hl
        call @address
        ld e,(ix+TS_SCROLL_SCRATCH)
        ld d,(ix+TS_SCROLL_SCRATCH+1)
        call @copy_width
        call @destination
        ex de,hl
        ld l,(ix+TS_SCROLL_SCRATCH)
        ld h,(ix+TS_SCROLL_SCRATCH+1)
        call @copy_width
        jr @advance

@fill:
        call @destination
        ld c,(ix+TS_SCROLL_WIDTH)
        ld b,(ix+TS_SCROLL_WIDTH+1)
        ld a,(ix+TS_SCROLL_FILL)
        call zx__fill_bytes
@advance:
        ld l,(ix+TS_SCROLL_ROW)
        ld h,(ix+TS_SCROLL_ROW+1)
        inc hl
        ld (ix+TS_SCROLL_ROW),l
        ld (ix+TS_SCROLL_ROW+1),h
        ld e,(ix+TS_SCROLL_END)
        ld d,(ix+TS_SCROLL_END+1)
        or a
        sbc hl,de
        jp c,@row
        ld sp,ix
        pop ix
        call ts_packed_end
        ld l,0
        ret

; Map the packed byte address of X=0 for the destination row or given DE=Y.
@destination:
        ld e,(ix+TS_SCROLL_ROW)
        ld d,(ix+TS_SCROLL_ROW+1)
@address:
        ld hl,0
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        bit 0,(ix+TS_SCROLL_MODE)
        jp z,ts_packed_address256
ENDIF
        jp ts_packed_address16
ELSE
        jp ts_packed_address256
ENDIF

; Copy one visible scanline from HL to DE within the already mapped ranges.
@copy_width:
        ld c,(ix+TS_SCROLL_WIDTH)
        ld b,(ix+TS_SCROLL_WIDTH+1)
        ldir
        ret
ENDIF
