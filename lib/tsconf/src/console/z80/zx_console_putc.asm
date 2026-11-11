        MODULE zx_console_putc
SECTION code_clib
PUBLIC _zx_console_putc
PUBLIC ts_console_putc_a
EXTERN ts_draw_config
EXTERN ts_console_size
EXTERN ts_console_position
EXTERN ts__console_write_cell
EXTERN zx__console_control
EXTERN zx__console_advance
EXTERN zx__console_newline
EXTERN _zx__console_text_bg
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts__packed_check_window
ENDIF

; Render a character and advance the cursor. An installed scroll handler
; runs on a wrap or newline at the bottom row.
;
; if (draw_config == UNSELECTED) return NOT_INITIALIZED;
; if (native_text && text_bg == TRANSPARENT) return UNSUPPORTED;
; if (c == TAB) do { write_and_advance(' '); } while (column & 7);
; else if (c < 32) cursor_control(c);
; else { if (packed && !can_claim_w3()) return BUSY; write_and_advance(c); }
; if (advanced_past_last_row && scroll_handler) scroll_handler();
;
; SDCC code at SP+2, internal entry A=code. Status in L. Caller keeps
; the selected screen mapped and serializes access. Clobbers AF/BC/DE/HL.
; Preserve IX/IY. Writer receives B=row, C=column.
_zx_console_putc:
        ld hl,2
        add hl,sp
        ld a,(hl)
ts_console_putc_a:
        ld d,a
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
IFDEF TSCONF_VIDEO_TEXT
        and 3
        cp 3
        jr nz,@cursor
        ld a,(_zx__console_text_bg)
        or a
        ld l,5                       ; ZX_UNSUPPORTED
        ret nz
@cursor:
ENDIF
        ld bc,(ts_console_position)
        ld a,d
        cp 9
        jr z,@tab
        cp 32
        jr c,@control
@cell:
IFDEF TSCONF_VIDEO_PACKED
        push af
        ld a,(ts_draw_config)
        and 3
        dec a
        cp 2
        jr nc,@ready
        push bc
        ld a,(ts_draw_page)
        ld d,a
        call ts__packed_check_window
        pop bc
        jr c,@busy
@ready:
        pop af
ENDIF
        ld hl,_zx__console_text_bg
        ld e,(hl)
        call ts__console_write_cell
        ld bc,(ts_console_position)
        ld de,(ts_console_size)
        call zx__console_advance
        jr nc,@scroll
@store:
        ld (ts_console_position),bc
        ld l,0                       ; ZX_OK
        ret
@control:
        ld de,(ts_console_size)
        cp 10
        jr z,@newline
        call zx__console_control
        jr @store
@newline:
        call zx__console_newline
        jr c,@store
@scroll:
        ld hl,(ts__console_scroll_callback)
        ld a,h
        or l
        jr z,@store
        push bc
        call @run_scroll
        pop bc
        ld a,l
        or a
        ret nz
        jr @store
@run_scroll:
        jp (hl)
@tab:
        ld a,' '
        call @cell
        ld a,l
        or a
        ret nz
        ld a,c
        and 7
        jr nz,@tab
        ret
IFDEF TSCONF_VIDEO_PACKED
@busy:
        pop af
        ld l,2                       ; ZX_BUSY
        ret
ENDIF

SECTION bss_clib
PUBLIC ts__console_scroll_callback
ts__console_scroll_callback: defw 0
