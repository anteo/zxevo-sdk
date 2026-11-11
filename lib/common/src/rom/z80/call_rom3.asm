        MODULE call_rom3
SECTION code_clib
PUBLIC call_rom3

; z88dk zx_clib supplies the ROM address as a word following CALL call_rom3.
; Enter that routine with the main registers intact and return past the word.
; The caller keeps the Spectrum ROM mapped in W0. The trampoline clobbers BC'.
call_rom3:
        exx
        ex (sp),hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ex (sp),hl
        push bc
        exx
        ret
