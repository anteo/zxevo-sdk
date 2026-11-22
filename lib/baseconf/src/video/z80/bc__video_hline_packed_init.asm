        MODULE bc__video_hline_packed_init
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_hline_run
EXTERN bc__video_hline_span
EXTERN bc__video_line_packed_paint
EXTERN bc__video_line_return
SECTION code_clib
PUBLIC bc__video_hline_packed_init
bc__video_hline_packed_init:
        push bc
        push bc
        push bc
        dec sp
        ld (ix-7),l
        ld (ix-6),h
        call bc__video_line_packed_paint
        ld (ix-3),b
        ld (ix-4),c
        xor a
        ld (ix-5),a
@part:
        call @masks
        ld l,(ix-7)
        ld h,(ix-6)
        bit 1,(ix-5)
        jr z,@plane
        set 5,h
@plane:
        ld de,(_bc_video_page0_base)
        bit 0,(ix-5)
        jr z,@origin
        ld de,(_bc_video_page1_base)
@origin:
        add hl,de
        ld a,3
        call bc__video_hline_span
        call bc__video_hline_run
        inc (ix-5)
        ld a,(ix-5)
        cp 4
        jr nz,@part
        jp bc__video_line_return

; Translate endpoint pixel selections directly into physical pair bit masks.
; Left field = 47h, right field = B8h. Zero masks skip untouched endpoint pairs.
;
; Selects which pixels of this packed pair are inside the line at each
; endpoint.
;
; Model:
;
; first_mask selects this part's pixels >=x0; last_mask selects pixels<=x1.
;
; For a single group the run ANDs both masks, giving the exact intersection.
; Input part=IX-5 and normalized endpoints; output IX-1/-2. AF/B volatile.
@masks:
        ld a,(ix-5)
        add a,a
        ld b,a                       ; part's left pixel within an eight-pixel group
        ld a,(ix+4)
        and 7
        cp b
        jr c,@first_full
        jr z,@first_full
        dec a
        cp b
        ld a,0
        jr nz,@first_store
        ld a,0B8h
        jr @first_store
@first_full:
        ld a,0FFh
@first_store:
        ld (ix-1),a
        ld a,(ix+8)
        and 7
        cp b
        ld a,0
        jr c,@last_store
        ld a,47h
        jr z,@last_store
        ld a,0FFh
@last_store:
        ld (ix-2),a
        ret
ENDIF
