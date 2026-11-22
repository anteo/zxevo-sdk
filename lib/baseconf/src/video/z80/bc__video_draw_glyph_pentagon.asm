        MODULE bc__video_draw_glyph_pentagon
IFDEF BASECONF_VIDEO_TEXT_PACKED
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
EXTERN bc__video_glyph_packed_setup
SECTION code_clib
PUBLIC bc__video_draw_glyph_pentagon

; Register ABI: HL = glyph, C = column, B = row, E = foreground,
; D = paper with bit 7 set for transparency. Pointer, lease and mode checked.
; Coordinates are
; in-range 8x8 cells. Preserve IX/IY. Stack holds a four-byte color-pair table,
; the source pointer and offset, and a stride/overlay flag byte.
; Draws an eight-by-eight glyph on the packed Pentagon surface using its
; ZX-style row layout.
;
; Model:
;
; offset=zx__offset(row*8,column);
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
bc__video_draw_glyph_pentagon:
        push ix
        push hl                      ; source pointer
        ld a,b
        and 18h
        ld h,a
        ld a,b
        and 7
        rlca
        rlca
        rlca
        rlca
        rlca
        or c
        ld l,a                       ; ZX-style first raster offset
        xor a                        ; vertical stride = 256
        jp bc__video_glyph_packed_setup
ENDIF
ENDIF
