        MODULE generic_console_vpeek
PUBLIC generic_console_vpeek
SECTION code_clib
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN __console_w
EXTERN __console_h
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN _bc__text_cell_read
ENDIF

; B = row, C = column. Return A=L=character, or zero outside hardware text
; modes/on failure. Carry is clear, Z reflects the character. Preserve IX/IY.
;
; Reads the character at a hardware text position, returning zero when the
; position or mode cannot be read.
;
; Model:
;
; if (outside_console || !hardware_text_mode || begin()!=OK) return 0;
; character=text_cell_read(surface,column,row); end(); return character;
;
; Input B=row,C=column, result A=L=character; CF clear, Z reflects character.
; AF/BC/DE/HL volatile, IX/IY preserved. Five outgoing argument bytes are separate
; from the saved character pushed across video_end. The end status is ignored.
generic_console_vpeek:
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
        ld hl,__console_w
        ld a,c
        cp (hl)
        jr nc,@empty
        ld hl,__console_h
        ld a,b
        cp (hl)
        jr nc,@empty
        ld hl,(_bc_video_draw_surface_state) ; surface.mode in L, page0 in H
        ld a,l
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jr nc,@empty
        push bc                      ; x:8, y:8
        ld a,(_bc_video_draw_surface_state+2)
        push af
        inc sp                       ; surface.page1
        push hl                      ; surface.mode, surface.page0
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@failed
        call _bc__text_cell_read
        push hl                      ; retain the character across video_end
        call _bc__video_end
        pop hl
        jr @finish
@failed:
        ld l,0
@finish:
        pop bc
        pop bc
        inc sp                       ; discard the fifth argument byte
        ld a,l
        or a
        ret
@empty:
ENDIF
        xor a
        ld l,a
        ret
