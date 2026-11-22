        MODULE zx_console_putc
EXTERN ts_console_putc_a
SECTION code_clib
PUBLIC _zx_console_putc

; Render a character and advance the cursor. An installed scroll handler
; runs on a wrap or newline at the bottom row.
;
; if (draw_config == UNSELECTED) return NOT_INITIALIZED;
; if (draw_window_leased) return BUSY;
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
        jp ts_console_putc_a
