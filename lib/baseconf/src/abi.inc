; Internal z88dk/SDCC stack adapters for BaseConf. Word-copy offsets start
; at SP before the macro pushes anything. Input arguments remain intact.

; Load a little-endian word from the IX frame into HL. Preserve flags.
        MACRO BC_ABI_LOAD_IX_WORD offset
        ld l,(ix+offset)
        ld h,(ix+offset+1)
        ENDM

; Push a copy of a word from the IX frame. Clobber HL, preserve flags.
        MACRO BC_ABI_PUSH_IX_WORD offset
        BC_ABI_LOAD_IX_WORD offset
        push hl
        ENDM

; Push the byte in A as a packed SDCC argument.
        MACRO BC_ABI_PUSH_BYTE
        push af
        inc sp
        ENDM

        MACRO BC_ABI_PUSH_WORDS_FORWARD words, offset
        ld hl,offset
        add hl,sp
        REPT words
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push de
        ENDR
        ENDM

        MACRO BC_ABI_PUSH_WORDS_REVERSE words, offset
        ld hl,offset+2*words-1
        add hl,sp
        REPT words
        ld d,(hl)
        dec hl
        ld e,(hl)
        dec hl
        push de
        ENDR
        ENDM

        MACRO BC_ABI_DROP_WORDS words
        REPT words
        pop bc
        ENDR
        ENDM

; Adapt a 2-, 3- or 4-word Small-C callee entry to a caller-clean target. Relocate the
; original return address above the outgoing arguments. Drop them after the
; call with BC so both byte (L) and word (HL) results survive. The four-word
; bridge uses shadow HL briefly and never keeps state there across a call.
        MACRO BC_ABI_SMALLC_CALLEE target, words
IF words == 4
        pop af
        pop bc
        pop de
        pop hl
        exx
        pop hl
        push af
        push hl
        exx
        push hl
        push de
        push bc
ELSE
IF words == 3
        pop af
        pop bc
        pop de
        pop hl
        push af
        push hl
        push de
        push bc
ELSE
        pop hl
        pop bc
        ex (sp),hl
        push hl
        push bc
ENDIF
ENDIF
        call target
        BC_ABI_DROP_WORDS words
        ret
        ENDM

; Small-C caller-clean pair (second word nearest SP): HL=first, DE=second.
; Preserve AF/IX/IY.
        MACRO BC_ABI_LOAD_SMALLC_PAIR
        pop bc
        pop de
        pop hl
        push hl
        push de
        push bc
        ENDM

; Load consecutive SDCC words at SP+offset as HL=first, DE=second.
        MACRO BC_ABI_LOAD_SDCC_PAIR offset
        ld hl,offset
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,b
        ld l,c
        ENDM
