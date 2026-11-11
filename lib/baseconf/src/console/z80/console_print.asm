        MODULE baseconf_console_print
PUBLIC generic_console_printc
EXTERN __console_w
EXTERN __console_h
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN _bc__console_cell_write
SECTION code_clib

; B = row, C = column, D = character. Preserve IX/IY; return A=L=0.
; The surface and character arguments stay on the stack across video_begin,
; so there is no shared request buffer or struct-return C call.
;
; Writes a character at an explicit console position under a video lease.
;
; Model:
;
; if (column>=columns || row>=rows) return 0;
; if (begin()==OK) { cell_write(mode,surface,column,row,character); end(); } return 0;
;
; Register input B=row,C=column,D=character. Owns the video lease.
; AF/BC/DE/HL volatile; IX/IY preserved, A=L=0 on every exit. Seven outgoing
; packed cell arguments are below the caller frame and discarded even if begin
; fails; do not store persistent locals in that callee-owned argument area.
generic_console_printc:
        ld hl,__console_w
        ld a,c
        cp (hl)
        jr nc,@done
        ld hl,__console_h
        ld a,b
        cp (hl)
        jr nc,@done
        ld a,d
        push af
        inc sp                       ; character:8
        push bc                      ; x:8, y:8
        ld hl,(_bc_video_draw_surface_state+1)
        push hl                      ; surface.page0, surface.page1
        ld a,(_bc_video_draw_surface_state)
        ld h,a
        ld l,a
        push hl                      ; mode:8, surface.mode:8
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@discard
        call _bc__console_cell_write
        call _bc__video_end
@discard:
        pop bc
        pop bc
        pop bc
        inc sp                       ; discard the seven argument bytes
@done:
        xor a
        ld l,a
        ret
