        MODULE bc__text_clear
SECTION code_clib
PUBLIC bc__text_clear
EXTERN _bc__video_begin
EXTERN _bc__text_encode_attribute
EXTERN _bc__video_clear_text_row
EXTERN _bc__video_end
EXTERN _bc_video_draw_surface_state
EXTERN __console_x
EXTERN __console_y
EXTERN __console_w
EXTERN __console_h

; Hardware-text clear is independent of bitmap clear/font backends.
; Keep the row counter locally and build the row helper's arguments per call.
;
; Replaces hardware text cells with spaces in the current colors and returns
; the cursor to the top-left cell.
;
; Model:
;
; if (video_begin()!=OK) return status;
; for (row=0; row<rows; ++row) clear_text_row(row,columns,encode_attribute());
; cursor_x=cursor_y=0; return video_end();
;
; Caller has selected a hardware-text surface. No arguments; owns the
; lease. Status in L, AF/BC/DE/HL volatile, IX/IY preserved. IX-1 is the
; persistent row counter. Discard the seven outgoing bytes after each call.
bc__text_clear:
        call _bc__video_begin
        ld a,l
        or a
        ret nz
        push ix
        ld ix,0
        add ix,sp
        xor a
        push af
        inc sp                       ; row at IX-1
@row:
        ld a,(ix-1)
        ld hl,__console_h
        cp (hl)
        jr nc,@end
        call _bc__text_encode_attribute
        ld a,l
        push af
        inc sp                       ; attribute:8
        ld a,(__console_w)
        ld h,a
        ld l,(ix-1)
        push hl                      ; row:8, columns:8
        ld hl,(_bc_video_draw_surface_state+1)
        push hl
        ld a,(_bc_video_draw_surface_state)
        ld h,a
        ld l,a
        push hl                      ; mode:8, surface.mode:8
        call _bc__video_clear_text_row
        pop bc
        pop bc
        pop bc
        inc sp
        inc (ix-1)
        jr @row
@end:
        xor a
        ld (__console_x),a
        ld (__console_y),a
        ld sp,ix
        pop ix
        jp _bc__video_end
