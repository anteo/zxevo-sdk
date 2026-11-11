        MODULE baseconf_console_vpeek
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
; character=text_cell_read(mode,surface,column,row); end(); return character;
;
; Input B=row,C=column, result A=L=character; CF clear, Z reflects character.
; AF/BC/DE/HL volatile, IX/IY preserved. Six outgoing arguments are separate
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
        ld a,(_bc_video_draw_surface_state)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jr nc,@empty
        add a,5
        push bc                      ; x:8, y:8
        ld hl,(_bc_video_draw_surface_state+1)
        push hl                      ; surface.page0, surface.page1
        ld h,a
        ld l,a
        push hl                      ; mode:8, surface.mode:8
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
        pop bc                       ; discard the six argument bytes
        ld a,l
        or a
        ret
@empty:
ENDIF
        xor a
        ld l,a
        ret
