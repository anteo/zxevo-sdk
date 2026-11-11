IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        MODULE bc__video_scroll_horizontal_atm640
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_atm640
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__ink
EXTERN zx__paper
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_row_offset_40
EXTERN bc__video_shift_atm640_row
EXTERN bc__video_scroll_horizontal_return

; Shifts the ATM640 bitmap horizontally and moves attributes for whole-byte
; shifts.
;
; C model:
;
;   attr = encode_atm_attribute(ink, paper);
;   for (y=0; y<200; ++y) shift_row(page1_base + y*40, pixels, right, 0);
;   if (pixels == 8)
;       for (y=0; y<200; ++y) shift_row(page0_base + y*40, 8, right, attr);
;
; Three persistent locals: Y, BLANK, ATTRIBUTE (scroll_horizontal.inc).
; Bitmap shifts of 1..7 leave attributes unchanged. Preserve IX/IY on return.
bc__video_scroll_horizontal_atm640:
        push bc
        dec sp
        ld a,(zx__ink)
        ld e,a
        ld a,(zx__paper)
        ld d,a
        call bc__video_packed_pixels_regs
        ld (ix+BC_SCROLL_ATTRIBUTE),a
        xor a
        ld (ix+BC_SCROLL_Y),a
        ld (ix+BC_SCROLL_BLANK),a
@bitmap:
        ld a,(ix+BC_SCROLL_Y)
        call bc__video_row_offset_40
        ld de,(_bc_video_page1_base)
        add hl,de
        ld c,(ix+BC_SCROLL_PIXELS)
        call bc__video_shift_atm640_row
        inc (ix+BC_SCROLL_Y)
        ld a,(ix+BC_SCROLL_Y)
        cp 200
        jr nz,@bitmap
        ld a,(ix+BC_SCROLL_PIXELS)
        cp 8
        jp nz,bc__video_scroll_horizontal_return
        ld a,(ix+BC_SCROLL_ATTRIBUTE)
        ld (ix+BC_SCROLL_BLANK),a
        xor a
        ld (ix+BC_SCROLL_Y),a
@attribute:
        ld a,(ix+BC_SCROLL_Y)
        call bc__video_row_offset_40
        ld de,(_bc_video_page0_base)
        add hl,de
        ld c,8
        call bc__video_shift_atm640_row
        inc (ix+BC_SCROLL_Y)
        ld a,(ix+BC_SCROLL_Y)
        cp 200
        jr nz,@attribute
        jp bc__video_scroll_horizontal_return
ENDIF
