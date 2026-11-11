        MODULE bc__graphics_fill_rect
SECTION code_graphics
PUBLIC _clga
PUBLIC _xorclga
PUBLIC _fillb
PUBLIC bc__graphics_rect_extent_a
EXTERN _bc__graphics_begin
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height
EXTERN _bc__video_hline
EXTERN _bc__video_end
EXTERN zx__clip_axis
EXTERN zx__clip_extent
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_row_offset_40
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_fill_two_planes
EXTERN zx__ink
EXTERN zx__paper
ENDIF

defc BC_RECT_Y_END_OR_SIZE = 4
defc BC_RECT_X_END_OR_SIZE = 6
defc BC_RECT_Y_START = 8
defc BC_RECT_X_START = 10

defc BC_RECT_OPERATION = -1
defc BC_RECT_FLAGS = -2
defc BC_RECT_LAST_X = -4
defc BC_RECT_FIRST_X = -6
defc BC_RECT_ROWS = -7
defc BC_RECT_ROW = -8

; Clear, toggle or fill a clipped rectangle through the horizontal span engine.
;
; if (use_extents && (width <= 0 || height <= 0)) return;
; if (!graphics_begin()) return;
; if (use_extents) { x1 = saturate(x0 + width - 1); y1 = saturate(y0 + height - 1); }
; if (clip_span(&x0, &x1, width_of_screen) && clip_span(&y0, &y1, height_of_screen)) {
;     if (ATM320 && x0 == 0 && x1 == 319 && op != XOR) fill_atm_rows(y0, y1, op);
;     else for (row = y0; row <= y1; ++row) video_hline(x0, x1, row, op);
; }
; video_end();
;
; Small-C caller-clean, last word at SP+2. clga/xorclga take inclusive corners.
; fillb and bc__graphics_rect_extent_a take an origin and dimensions. The
; latter receives SET or CLEAR in A. IX points at saved IX. Private locals
; hold AF (operation and carry indicating extents), first/last X and row/count.
; Outgoing hline arguments are fresh copies since that routine may rewrite
; them. Preserve IX/IY, clobber AF/BC/DE/HL. No BSS or hardware remapping.
_clga:
        xor a
        inc a                        ; PIXEL_CLEAR, carry clear
        jr bc_rect_begin
_xorclga:
        ld a,2                       ; PIXEL_XOR
        or a
        jr bc_rect_begin
_fillb:
        xor a                        ; PIXEL_SET
bc__graphics_rect_extent_a:
        scf
bc_rect_begin:
        push ix
        push af                       ; save carry before computing the frame address
        ld ix,2
        add ix,sp
        bit 0,(ix+BC_RECT_FLAGS)
        jr z,@acquire
        ld a,(ix+BC_RECT_X_END_OR_SIZE+1)
        or (ix+BC_RECT_Y_END_OR_SIZE+1)
        jp m,@return
        ld a,(ix+BC_RECT_X_END_OR_SIZE)
        or (ix+BC_RECT_X_END_OR_SIZE+1)
        jr z,@return
        ld a,(ix+BC_RECT_Y_END_OR_SIZE)
        or (ix+BC_RECT_Y_END_OR_SIZE+1)
        jr nz,@acquire
@return:
        ld sp,ix
        pop ix
        ret

@acquire:
        call _bc__graphics_begin
        jr z,@return
        ld l,(ix+BC_RECT_X_START)
        ld h,(ix+BC_RECT_X_START+1)
        ld e,(ix+BC_RECT_X_END_OR_SIZE)
        ld d,(ix+BC_RECT_X_END_OR_SIZE+1)
        ld bc,(_bc_graphics_width)
        bit 0,(ix+BC_RECT_FLAGS)
        call bc_rect_clip_span
        jr c,@end
        push de
        push hl

        ld l,(ix+BC_RECT_Y_START)
        ld h,(ix+BC_RECT_Y_START+1)
        ld e,(ix+BC_RECT_Y_END_OR_SIZE)
        ld d,(ix+BC_RECT_Y_END_OR_SIZE+1)
        ld bc,(_bc_graphics_height)
        bit 0,(ix+BC_RECT_FLAGS)
        call bc_rect_clip_span
        jr c,@end

        ; Every primitive mode is at most 200 rows. Pack the first row in L
        ; and the inclusive row count (last - first + 1) in H.
        ld a,e
        sub l
        inc a
        ld h,a
        push hl
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        ld a,(_bc_video_draw_surface_state)
        cp 3                         ; BC_VIDEO_ATM_320
        jr nz,@row
        ld a,(ix+BC_RECT_OPERATION)
        cp 2                         ; SET and CLEAR can replace complete bytes
        jr nc,@row
        ld a,(ix+BC_RECT_FIRST_X)
        or (ix+BC_RECT_FIRST_X+1)
        jr nz,@row
        ld a,(ix+BC_RECT_LAST_X)
        cp 3fh                       ; 319 = 013Fh
        jr nz,@row
        ld a,(ix+BC_RECT_LAST_X+1)
        cp 1
        jr z,@atm_full_width
ENDIF
@row:
        ld a,(ix+BC_RECT_OPERATION)
        push af
        inc sp                       ; SDCC operation byte follows the words
        ld l,(ix+BC_RECT_ROW)
        ld h,0
        push hl
        ld l,(ix+BC_RECT_LAST_X)
        ld h,(ix+BC_RECT_LAST_X+1)
        push hl
        ld l,(ix+BC_RECT_FIRST_X)
        ld h,(ix+BC_RECT_FIRST_X+1)
        push hl
        call _bc__video_hline
        pop bc
        pop bc
        pop bc
        inc sp
        inc (ix+BC_RECT_ROW)
        dec (ix+BC_RECT_ROWS)
        jr nz,@row
@end:
        ld sp,ix
        pop ix
        jp _bc__video_end

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
; Fill clipped full-width ATM320 rows using contiguous spans in all four planes.
;
; offset = first_row * 40; length = rows * 40;
; color = op == SET ? ink : paper;
; for (page in pages) fill_both_planes(page, offset, length, pack(color,color));
;
; IX retains the clipped rectangle frame, with an active video lease. Save
; offset, length and packed color across the first page. Clobber AF/BC/DE/HL.
@atm_full_width:
        ld a,(ix+BC_RECT_ROW)
        call bc__video_row_offset_40
        ex de,hl
        ld a,(ix+BC_RECT_ROWS)
        call bc__video_row_offset_40 ; preserves DE, the first byte offset
        ld b,h
        ld c,l
        push de
        ld a,(ix+BC_RECT_OPERATION)
        or a
        ld a,(zx__ink)
        jr z,@pack_color
        ld a,(zx__paper)
@pack_color:
        ld e,a
        ld d,a
        call bc__video_packed_pixels_regs
        pop de
        push de
        push af
        push bc
        ld hl,(_bc_video_page0_base)
        add hl,de
        call bc__video_fill_two_planes
        pop bc
        pop af
        pop de
        ld hl,(_bc_video_page1_base)
        add hl,de
        call bc__video_fill_two_planes
        jr @end
ENDIF

; Convert one axis to endpoints if needed, then sort and clip it.
;
; if (use_extents) end = min(start + size - 1, INT16_MAX);
; return clip_span(start, end, limit);
;
; HL=start, DE=end or positive size, BC=axis limit, NZ means extents. Return
; inclusive endpoints in HL/DE, carry if empty. Preserve BC/IX/IY.
bc_rect_clip_span:
        jp z,zx__clip_axis
        jp zx__clip_extent
