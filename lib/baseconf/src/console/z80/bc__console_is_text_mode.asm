        MODULE bc__console_is_text_mode

SECTION code_clib
PUBLIC _bc__console_is_text_mode

; SDCC caller-clean ABI: mode:8 at SP+2. Return boolean in L; preserve IX/IY.
; Predicate: L=(mode==ATM_TEXT_80 || mode==EVO_TEXT_80). No lease required.
; AF/HL volatile; BC/DE/IX/IY preserved. The input is one caller-clean byte.
_bc__console_is_text_mode:
        ld hl,2
        add hl,sp
        ld a,(hl)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        ld l,0
        ret nc
        inc l
        ret
