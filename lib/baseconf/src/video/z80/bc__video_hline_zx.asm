IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
        MODULE bc__video_hline_zx
SECTION code_clib
PUBLIC bc__video_hline_zx
EXTERN _bc_video_page0_base
EXTERN bc__video_line_bitmap_paint
EXTERN bc__video_hline_masks
EXTERN bc__video_line_zx_row
EXTERN bc__video_hline_span
EXTERN bc__video_hline_run
EXTERN bc__video_line_return

; Paints a horizontal span in the ZX bitmap while keeping pixels outside its
; endpoints intact.
;
; Model:
;
; masks=bitmap_edges(x0,x1); paint=bitmap_operation(op);
; origin=page0_base+zx__offset(y,0); paint_span(origin+(x0>>3),origin+(x1>>3));
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Four private bytes: first_mask -1,last_mask -2,full_AND -3,full_XOR -4.
bc__video_hline_zx:
        push bc
        push bc                      ; four-byte local masks/paint, no request
        call bc__video_line_bitmap_paint
        ld (ix-3),b
        ld (ix-4),c
        call bc__video_hline_masks
        ld (ix-1),b
        ld (ix-2),c
        call bc__video_line_zx_row
        ld de,(_bc_video_page0_base)
        add hl,de
        ld a,3
        call bc__video_hline_span
        call bc__video_hline_run
        jp bc__video_line_return
ENDIF
