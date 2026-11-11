        MODULE bc__text_put
SECTION code_clib
PUBLIC bc__text_put
EXTERN _bc_video_draw_surface_state
EXTERN _bc__text_cell_write
EXTERN bc__console_control
EXTERN bc__console_advance
EXTERN __console_x
EXTERN __console_y

; A = character, active hardware-text lease. Preserve IX/IY.
; The leaf alone receives packed SDCC mode/surface/coordinate arguments.
;
; Handles one character or cursor control under an existing hardware text
; lease.
;
; Model:
;
; if (c==TAB) do { put_space(); advance(); } while (cursor_x&7);
; else if (c<32) console_control(c);
; else { write_current_cell(c); advance(); }
;
; Active hardware-text lease and nonzero geometry are required; A is the
; input byte. AF/BC/DE/HL volatile, IX/IY preserved. Each write creates seven
; fresh packed C argument bytes; newline/wrapping never scrolls.
bc__text_put:
        cp 9
        jr z,@tab
        cp 32
        jp c,bc__console_control
@write:
        push af
        inc sp                       ; character:8
        ld a,(__console_y)
        ld b,a
        ld a,(__console_x)
        ld c,a
        push bc                      ; column:8, row:8
        ld hl,(_bc_video_draw_surface_state+1)
        push hl                      ; surface.page0, surface.page1
        ld a,(_bc_video_draw_surface_state)
        ld h,a
        ld l,a
        push hl                      ; mode:8, surface.mode:8
        call _bc__text_cell_write
        pop bc
        pop bc
        pop bc
        inc sp
        jp bc__console_advance
@tab:
        ld a,' '
        call @write
        ld a,(__console_x)
        and 7
        jr nz,@tab
        ret
