        MODULE zx_console_clear
SECTION code_clib
PUBLIC _zx_console_clear
EXTERN ts_console_size
EXTERN ts_console_position
EXTERN ts_draw_config
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_console_zx_attribute
EXTERN ts_draw_base
EXTERN zx__clear_screen
ELSE
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_draw_base
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_console_text_attribute
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN zx__paper
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
EXTERN ts_packed_map_relative
ENDIF
EXTERN zx__fill_bytes

; Clear the selected console and return the cursor to its origin.
;
; if (draw_config == UNSELECTED) return NOT_INITIALIZED;
; if (mode == ZX) zx__clear_screen(base, zx_attribute());
; else if (mode == TEXT) for each console row { fill(codes, ' '); fill(attrs, attr); }
; else { if (!claim_w3()) return BUSY; fill_packed_pages(); release_w3(); }
; position = 0; return OK;
;
; ZX and text need a mapped surface. Packed modes borrow W3 and restore it.
; A saved BC word holds the current row and width, or page counter and paint
; byte. AF/BC/DE/HL volatile, IX/IY preserved. SDCC result in L.
_zx_console_clear:
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        and 3
IFDEF TSCONF_VIDEO_ZX
        jr z,@zx
ENDIF
IFDEF TSCONF_VIDEO_TEXT
        cp 3
        jr z,@text
ENDIF

IFDEF TSCONF_VIDEO_PACKED
        ld hl,ts_draw_page
        ld d,(hl)
        push af
        call ts_packed_begin_window
        pop bc                       ; B = saved mode, keep carry from begin
        ld l,2                       ; ZX_BUSY
        ret c
        ld a,b
        cp 2
        ld a,(zx__paper)
IFDEF TSCONF_VIDEO_256C
        ld b,16
IFDEF TSCONF_VIDEO_16C
        jr z,@page_color
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_16C
        ld b,8
        and 0fh
        ld c,a
        rlca
        rlca
        rlca
        rlca
        or c                         ; two identical nibbles
ENDIF
@page_color:
        ld c,a
@page:
        push bc
        ld a,b
        dec a
        call ts_packed_map_relative
        pop bc
        push bc
        ld a,c
        ld hl,0c000h
        ld bc,4000h
        call zx__fill_bytes
        pop bc
        djnz @page
        call ts_packed_end
        jr @reset
ENDIF

IFDEF TSCONF_VIDEO_ZX
@zx:
        ld a,(ts_draw_base)
        ld h,a
        ld l,0
        call ts_console_zx_attribute
        call zx__clear_screen
        jr @reset
ENDIF

IFDEF TSCONF_VIDEO_TEXT
@text:
        ld a,(ts_console_size)
        ld c,a                       ; C=visible columns, B=row
        ld b,0
@text_row:
        push bc
        ld a,(ts_draw_base)
        or b
        ld h,a
        ld l,0
        ld b,0
        ld a,' '
        call zx__fill_bytes
        ld l,80h                     ; same row, attribute half
        pop bc
        push bc
        ld b,0
        call ts_console_text_attribute
        call zx__fill_bytes
        pop bc
        inc b
        ld a,(ts_console_size+1)
        cp b
        jr nz,@text_row
ENDIF
@reset:
        ld hl,0
        ld (ts_console_position),hl
        ret
