        MODULE bc__font_upload_range
SECTION code_clib
PUBLIC bc__font_upload_range

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
