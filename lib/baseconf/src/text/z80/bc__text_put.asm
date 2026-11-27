        MODULE bc__text_put
SECTION code_clib
PUBLIC bc__text_put
EXTERN _bc_video_draw_surface_state
EXTERN _bc__text_cell_write
EXTERN bc__console_control_a
EXTERN bc__console_advance
EXTERN __console_x

; A = character, active hardware-text lease. Preserve IX/IY.
; The cell writer receives the packed SDCC surface and coordinates.
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
; input byte. AF/BC/DE/HL volatile, IX/IY preserved. Each write creates six
; fresh packed C argument bytes; newline/wrapping never scrolls.
bc__text_put:
        cp 9
        jr z,@tab
        cp 32
        jp c,bc__console_control_a
@write:
        ld b,a
        ld hl,(__console_x)          ; adjacent cursor bytes: x in L, y in H
        ld c,h
        push bc                      ; y, character
        ld b,l
        ld a,(_bc_video_draw_surface_state+2)
        ld c,a
        push bc                      ; surface.page1, x
        ld hl,(_bc_video_draw_surface_state)
        push hl                      ; surface.mode, surface.page0
        call _bc__text_cell_write
        pop bc
        pop bc
        pop bc
        jp bc__console_advance
@tab:
        ld a,' '
        call @write
        ld a,(__console_x)
        and 7
        jr nz,@tab
        ret
