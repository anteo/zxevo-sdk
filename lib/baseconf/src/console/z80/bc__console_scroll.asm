        MODULE bc__console_scroll

SECTION code_clib
PUBLIC _bc__console_scroll
EXTERN _bc__video_scroll_up8
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN _bc__video_scroll_text_rows
EXTERN _bc__video_clear_text_row
EXTERN _bc__text_encode_attribute
EXTERN __console_w
EXTERN __console_h

; SDCC caller-clean ABI, no arguments. Preserve IX/IY and the cursor.
; The text scroll and final-row clear share their first six argument bytes.
;
; Scrolls the console up one row and clears the exposed row while retaining
; the cursor position.
;
; Model:
;
; if (!hardware_text_mode) return video_scroll_up8();
; if (begin() != OK) return;
; if (rows>=2) scroll_text_rows(rows-1,columns);
; clear_text_row(rows-1,columns,encode_attribute()); end();
;
; Caller supplies nonzero geometry. AF/BC/DE/HL volatile, IX/IY and cursor
; preserved. Text outgoing block: mode +0, surface +1..3, last_row/count +4,
; columns +5, attribute +6 relative to IX. Bitmap mode owns its own lease path.
_bc__console_scroll:
        ld a,(_bc_video_draw_surface_state)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jp nc,_bc__video_scroll_up8
        push ix
        dec sp                       ; attribute for the final-row clear
        ld a,(__console_h)
        dec a
        ld l,a
        ld a,(__console_w)
        ld h,a
        push hl                      ; row_count/last_row:8, columns:8
        ld hl,(_bc_video_draw_surface_state+1)
        push hl                      ; surface.page0, surface.page1
        ld a,(_bc_video_draw_surface_state)
        ld h,a
        ld l,a
        push hl                      ; mode:8, surface.mode:8
        ld ix,0
        add ix,sp                    ; IX = the seven helper arguments
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@discard
        ld a,(__console_h)
        cp 2
        jr c,@clear_last
        call _bc__video_scroll_text_rows
@clear_last:
        call _bc__text_encode_attribute
        ld (ix+6),l
        call _bc__video_clear_text_row
        call _bc__video_end
@discard:
        pop bc
        pop bc
        pop bc
        inc sp                       ; discard seven argument bytes
        pop ix
        ret
ELSE
defc _bc__console_scroll = _bc__video_scroll_up8
ENDIF
