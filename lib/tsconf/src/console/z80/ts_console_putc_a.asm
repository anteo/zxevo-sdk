        MODULE ts_console_putc_a
EXTERN _ts__draw_window_leased
EXTERN _zx__console_text_bg
EXTERN ts__console_scroll_callback
EXTERN ts__console_write_cell
EXTERN ts_console_position
EXTERN ts_console_size
EXTERN ts_draw_config
EXTERN zx__console_advance
EXTERN zx__console_control
EXTERN zx__console_newline
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts__packed_check_window
EXTERN ts_draw_page
ENDIF
SECTION code_clib
PUBLIC ts_console_putc_a
ts_console_putc_a:
        ld d,a
        ld a,(_ts__draw_window_leased)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
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
