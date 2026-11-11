IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        MODULE bc__video_pixel_atm640
SECTION code_clib
PUBLIC bc__video_pixel_atm640
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_pixel_linear_offset
EXTERN bc__video_pixel_bitmap

; Locate an ATM640 pixel and its attribute on the two prepared pages.
;
; offset=y*40+(x>>4)+((x&8)?0x2000:0);
; bitmap_pixel(page1_base+offset,page0_base+offset,x&7,op,color,ATM);
;
; HL=x, DE=y, B=color, C=operation. Active lease, x<640 and y<200.
; Save op/color during address calculation. Preserve IX/IY.
bc__video_pixel_atm640:
        push bc
        ld b,4
        call bc__video_pixel_linear_offset
        bit 3,a
        jr z,@plane
        set 5,h
@plane:
        ld c,a
        ; Both 16 KiB bases are aligned. Only the top two address bits differ.
        ld e,l
        ld a,(_bc_video_page0_base+1)
        or h
        ld d,a
        ld a,(_bc_video_page1_base+1)
        or h
        ld h,a
        ld a,c
        pop bc
        scf                          ; ATM brightness format
        jp bc__video_pixel_bitmap
ENDIF
