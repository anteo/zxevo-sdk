        MODULE baseconf_crt0

defc ZX_CRT_PLATFORM_CODE = 1
defc ZX_CRT_NO_DEFAULT_HEAP = 1

PUBLIC __SYSVAR_BORDCR
defc __SYSVAR_BORDCR = 23624

        MACRO ZX_CRT_EMIT_PLATFORM_CODE
defc TAR__fputc_cons_generic = CRT_ENABLE_STDIO
PUBLIC call_rom3

; Call a Spectrum ROM routine whose address follows the call instruction.
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
        ENDM

INCLUDE "z80_crt0.asm"
