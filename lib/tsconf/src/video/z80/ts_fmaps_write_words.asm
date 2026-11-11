        MODULE ts_fmaps_write_words
SECTION code_clib
PUBLIC _ts_fmaps_write_words

; Upload palette or sprite words to an enabled FMAPS aperture.
;
; bytes = 2 * count;
; while (bytes--)
;     *destination++ = *source++;
;
; SDCC classic: destination at SP+2, source at SP+4, count at SP+6.
; No local frame. Clobbers AF, BC, DE and HL. Preserves IX, IY and SP.
; Count is 0..256. Caller owns FMAPS and excludes competing writes.
; Start at an even address so LDIR sends the low byte before the odd
; address write that commits the word.
_ts_fmaps_write_words:
        ld hl,6
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        sla c
        rl b
        ld a,b
        or c
        ret z
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ldir
        ret
