IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        MODULE bc__video_hline_atm640
SECTION code_clib
PUBLIC bc__video_hline_atm640
EXTERN _bc_video_page1_base
EXTERN bc__video_line_bitmap_paint
EXTERN bc__video_hline_masks
EXTERN bc__video_line_linear_row
EXTERN bc__video_hline_span
EXTERN bc__video_hline_run
EXTERN bc__video_line_return

; Seven local bytes: masks/paint -4..-1, plane -5, row offset -7/-6.
;
; Draws an ATM640 horizontal line across the two interleaved bitmap planes.
;
; Model:
;
; for (plane=0; plane<2; ++plane) {
;     origin=page1_base+y*40+plane*0x2000;
;     first/last=origin+(x0/x1>>4), rounded to logical-byte plane parity;
;     paint_span(first,last,endpoint_masks_for_this_plane);
; }
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Seven private bytes: edge masks -1/-2,AND/XOR -3/-4,plane -5,row_offset -7/-6.
; A nonmatching endpoint plane uses a full mask; rounding can leave an empty span.
bc__video_hline_atm640:
        push bc
        push bc
        push bc
        dec sp
        call bc__video_line_bitmap_paint
        ld (ix-3),b
        ld (ix-4),c
        call bc__video_line_linear_row
        ld (ix-7),l
        ld (ix-6),h
        xor a
        ld (ix-5),a
@plane:
        call bc__video_hline_masks
        ld a,(ix+4)
        rrca
        rrca
        rrca
        xor (ix-5)
        and 1
        jr z,@first
        ld b,0FFh                    ; first pixel byte belongs to the other plane
@first:
        ld a,(ix+8)
        rrca
        rrca
        rrca
        xor (ix-5)
        and 1
        jr z,@last
        ld c,0FFh
@last:
        ld (ix-1),b
        ld (ix-2),c
        ld l,(ix-7)
        ld h,(ix-6)
        bit 0,(ix-5)
        jr z,@origin
        set 5,h
@origin:
        ld de,(_bc_video_page1_base)
        add hl,de
        ld a,4
        call bc__video_hline_span
        bit 0,(ix-5)
        jr nz,@odd
        bit 3,(ix+4)
        jr z,@run
        inc hl                       ; round first logical byte up to even parity
        jr @run
@odd:
        bit 3,(ix+8)
        jr nz,@run
        dec de                       ; round last logical byte down to odd parity
@run:
        call bc__video_hline_run      ; also handles an empty plane span
        inc (ix-5)
        ld a,(ix-5)
        cp 2
        jp nz,@plane
        jp bc__video_line_return
ENDIF
