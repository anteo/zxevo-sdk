        MODULE ts_console_load_text_font
SECTION code_clib
PUBLIC _ts_console_load_text_font
EXTERN zx__font8_data

; Upload the ASCII glyphs to codes 32..127 in a mapped native font page.
; Fastcall HL=aligned writable window. Preserve IX/IY, clobber AF/BC/DE/HL.
_ts_console_load_text_font:
        inc h                       ; each character takes eight bytes, 32*8=256
        ex de,hl
        ld hl,zx__font8_data
        ld bc,96*8
        ldir
        ret
