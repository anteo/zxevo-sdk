        MODULE ts__video_validate_mode
SECTION code_clib
PUBLIC ts__video_validate_mode

; Check the shared ZX number or a tagged TSConf VConfig byte.
;
; return mode == 0 || (tag == 1 && config != 0 && !(config & 0x0c));
;
; A=high byte, E=low byte. Z if valid. Clobbers AF only.
ts__video_validate_mode:
        or a
        jr nz,@native
        or e
        ret
@native:
        dec a
        ret nz
        ld a,e
        or a
        jr nz,@check_bits
        inc a                       ; reject a tagged zero; plain ZX uses mode 0
        ret
@check_bits:
        and 0ch                     ; bits 2 and 3 are outside the mode API
        ret
