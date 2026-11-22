        MODULE bc__video_draw_glyph_atm320
IFDEF BASECONF_VIDEO_TEXT_PACKED
IFDEF BASECONF_VIDEO_TEXT_ATM_320
EXTERN bc__video_glyph_packed_setup
SECTION code_clib
PUBLIC bc__video_draw_glyph_atm320

; Draws an eight-by-eight glyph on the packed ATM320 surface using its linear
; scanline layout.
;
; Model:
;
; offset=row*320+column;
; table={pack(paper,paper),pack(paper,ink),pack(ink,paper),pack(ink,ink)};
; for each raster, consume four two-bit glyph groups and write their table entries
; to page0/plane0, page1/plane0, page0/plane1, page1/plane1;
;
; Native inputs: HL=glyph[8], C=column, B=row, E=ink, D=paper/overlay.
; Dispatcher has checked the pointer/lease/mode; caller supplies an in-bounds
; 8x8 cell and both mapped pages. AF/BC/DE/HL volatile; IX/IY preserved.
; No clipping, page remapping or persistent global scratch.
; Native tail setup, with an IX-anchored table frame instead of 32 packed bytes.
; BC_GLYPH_PACKED_OFFSET/SOURCE name its two-byte fields. Table is +0..3;
; flags are saved at +5 (AF +4..5), offset +6, source +8, saved IX +10.
; Pentagon raster stride is 0100h; ATM320 stride is 40.
bc__video_draw_glyph_atm320:
        push ix
        push hl                      ; source pointer
        ld a,c                       ; retain column across the multiply
        ld l,b
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl                    ; row*64
        push hl
        add hl,hl
        add hl,hl
        pop bc
        add hl,bc                    ; row*320
        ld c,a
        ld b,0
        add hl,bc                    ; + byte column
        ld a,1                       ; vertical stride = 40
        jp bc__video_glyph_packed_setup
ENDIF
ENDIF
