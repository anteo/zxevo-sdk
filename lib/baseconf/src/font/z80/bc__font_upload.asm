        MODULE bc__font_upload

SECTION code_clib
PUBLIC bc__font_upload_validate
PUBLIC bc__font_upload_range
PUBLIC bc__font_upload_overlap
PUBLIC bc__font_upload_copy

; HL = font, DE = destination. Preserve both; CF = invalid CPU range.
; An aligned 2 KiB destination in W1..W3 cannot wrap or cross a window.
;
; Checks that the source and aligned destination are valid, separate CPU
; ranges for a 2 KiB font upload.
;
; Model:
;
; invalid=!valid_2k(font) || destination<0x4000 ||
; (destination&0x7ff)!=0 || overlap_2k(font,destination).
;
; Checks CPU ranges only; caller guarantees the current physical mappings and
; absence of aliases. AF/BC volatile; HL/DE/IX/IY preserved; CF=invalid.
bc__font_upload_validate:
        call bc__font_upload_range
        ret c
        ld a,d
        and 7
        or e
        jr nz,@invalid
        ld a,d
        cp 40h
        jr c,@invalid
        jp bc__font_upload_overlap
@invalid:
        scf
        ret

; Preserve HL/DE; CF = null or a 2 KiB range extending beyond FFFFh.
;
; Checks whether a non-null pointer can address all 2 KiB of a font buffer
; without wrapping.
;
; Model:
;
; invalid=(pointer==0 || pointer>0xf800).
;
; ADD of the inclusive last-byte offset 07FFh detects wrap; F800h remains
; valid because its last byte is FFFFh. AF/BC volatile; HL/DE/IX/IY preserved.
bc__font_upload_range:
        ld a,h
        or l
        scf
        ret z
        push hl
        ld bc,07FFh
        add hl,bc
        pop hl
        ret

; HL/DE = valid 2 KiB range starts. Preserve both; CF = overlap.
; (HL - DE + 07FFh) modulo 10000h is below 0FFFh exactly when
; the start-address difference is -07FFh..+07FFh. Adjacent ranges pass.
;
; Reports whether two 2 KiB buffers overlap in the CPU address space.
;
; Model:
;
; overlap=(a<=b ? b-a<2048 : a-b<2048).
;
; Both starts have already passed valid_2k(); only CPU-address intersection is
; checked. AF/BC volatile; HL/DE/IX/IY preserved; CF=overlap.
bc__font_upload_overlap:
        push hl
        or a
        sbc hl,de
        ld bc,07FFh
        add hl,bc
        ld bc,0FFFh
        or a
        sbc hl,bc
        pop hl
        ret

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
