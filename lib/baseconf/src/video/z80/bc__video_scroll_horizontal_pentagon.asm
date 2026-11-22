        MODULE bc__video_scroll_horizontal_pentagon
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_scroll_horizontal_packed_init
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_pentagon

; Shifts packed Pentagon or ATM320 rows horizontally and fills the exposed
; pixels with paper color.
;
; C model:
;
;   paper_pair = pack(paper, paper);
;   for (y = 0; y < height; ++y)
;       shift_native_pairs(page0_base + row_offset(y), width/2, pixels, right);
;
; Seven persistent stack bytes (scroll_horizontal.inc), no full-row scratch.
; Entry from the dispatcher with an active lease. Preserve IX/IY on return.
bc__video_scroll_horizontal_pentagon:
        ld a,128
        jp bc__video_scroll_horizontal_packed_init
ENDIF
ENDIF
