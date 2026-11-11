; SDCC zx_font_t layout. The two presets share metrics and glyph data;
; each platform supplies the draw callback.
defc ZX_FONT_ADVANCE_OFFSET = 4
defc ZX_FONT_FLAGS_OFFSET = 5
defc ZX_FONT_DRAW_OFFSET = 6
defc ZX_TEXT_BACKGROUND_ARG = 13    ; callback frame after saving IX

        MACRO ZX_FONT8_DESCRIPTOR glyph_table, renderer, flags
        defw glyph_table
        defb 8,8,8,flags
        defw renderer
        ENDM

        MACRO ZX_FONT5_DESCRIPTOR glyph_table, renderer, flags
        defw glyph_table
        defb 5,8,6,flags
        defw renderer
        ENDM

; DE=validated descriptor, B=advance. Publish both fields, refresh the
; platform's console geometry and home the adjacent column/row bytes.
; Font metrics can live separately so geometry need not link glyph data.
; A macro binds those addresses directly without a runtime pointer table.
; HL=0 on exit; AF/BC/DE volatile.
        MACRO ZX_FONT_INSTALL font_slot, advance_slot, update_geometry, cursor
        ld (font_slot),de
        ld a,b
        ld (advance_slot),a
        call update_geometry
        ld hl,0
        ld (cursor),hl
        ENDM
