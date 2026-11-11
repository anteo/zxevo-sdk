        MODULE bc__console_geometry
SECTION code_clib
PUBLIC _bc__console_geometry
EXTERN _bc_video_draw_surface_state
EXTERN _bc_console_font_advance
EXTERN _bc__video_height
EXTERN bc__console_columns_regs
EXTERN zx__font_column_byte
EXTERN __console_w
EXTERN __console_h

; Updates the console dimensions for the active video mode and font advance.
;
; Model:
;
; if (hardware_text_mode) { columns=80; rows=25; }
; else { columns=min(255,video_width()/font_advance); rows=video_height()/8; }
;
; No lease is acquired and no font descriptor is dereferenced. AF/BC/DE/HL
; volatile; IX/IY preserved. Store only low-byte dimensions, as the C API does.
_bc__console_geometry:
        ld a,(_bc_video_draw_surface_state)
        sub 5
        cp 2
        jr nc,@bitmap
        ld a,80
        ld (__console_w),a
        ld a,25
        ld (__console_h),a
        ret
@bitmap:
        ld a,(_bc_console_font_advance)
        ld e,a
        call bc__console_columns_regs
        call zx__font_column_byte
        ld (__console_w),a
        call _bc__video_height
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld a,l
        ld (__console_h),a
        ret
