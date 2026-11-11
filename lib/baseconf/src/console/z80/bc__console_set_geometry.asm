        MODULE bc__console_set_geometry
SECTION code_clib
PUBLIC _bc__console_set_geometry
EXTERN __console_w
EXTERN __console_h
EXTERN __console_x
EXTERN zx__console_in_bounds
EXTERN _bc_video_draw_surface_state
EXTERN _bc_console_font_advance
EXTERN zx__font_cell_columns

; SDCC columns:8, rows:8. Graphics columns describe eight-pixel cells;
; hardware-text columns are already character cells. Preserve IX/IY.
; This entry depends only on geometry metrics, never on a font descriptor.
;
; Stores the new console dimensions, adjusts bitmap columns to the
; selected font advance and resets an out-of-bounds cursor.
;
; Model:
;
; rows=input_rows; columns=input_columns;
; if (graphics_mode) columns=min(255,(input_columns*8)/font_advance);
; if (cursor_x>=columns || cursor_y>=rows) cursor_x=cursor_y=0;
;
; No descriptor access or lease acquisition. AF/BC/DE/HL volatile, IX/IY
; preserved. New dimensions, rather than a possibly stale video cache, determine
; the conversion from eight-pixel cells to the selected font advance.
_bc__console_set_geometry:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld a,(hl)
        ld (__console_h),a
        ld a,(_bc_video_draw_surface_state)
        sub 5
        cp 2
        ld a,c
        jr c,@store_width
        ld a,(_bc_console_font_advance)
        ld e,a
        ld a,c
        call zx__font_cell_columns
@store_width:
        ld (__console_w),a
        ld bc,(__console_x)
        ld de,(__console_w)
        call zx__console_in_bounds
        ret c
        ld hl,0
        ld (__console_x),hl
        ret
