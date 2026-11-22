        MODULE bc__font_upload_copy
SECTION code_clib
PUBLIC bc__font_upload_copy

; HL = font, DE = destination, A = original BF with bit 2 clear.
; Caller masks INT and excludes NMI. Only LDIR writes memory while BF.2
; is set: the saved BF and return address are pushed before enabling it.
;
; Copies the font through the hardware font-write gate and restores the
; original gate setting.
;
; Model:
;
; BF=saved_BF|4; copy_2048(font,destination); BF=saved_BF;
;
; BF.2 mirrors each CPU memory write into font[address&0x7ff] while ordinary
; RAM is also written. Save all stack data before opening the gate; no CALL,
; PUSH or unrelated stores are allowed until it closes. AF/BC/DE/HL volatile;
; IX/IY preserved; HL/DE advance by 0800h. Does not mask/restore interrupts.
bc__font_upload_copy:
        push af
        set 2,a
        ld bc,00BFh
        out (c),a
        ld bc,0800h
        ldir
        ld bc,00BFh
        pop af
        out (c),a
        ret
