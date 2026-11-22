        MODULE bc__font_upload_overlap
SECTION code_clib
PUBLIC bc__font_upload_overlap

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
