IFNDEF CRT_ENABLE_ZX_LIFECYCLE
defc CRT_ENABLE_ZX_LIFECYCLE = 1
ENDIF

IF CRT_ENABLE_ZX_LIFECYCLE
EXTERN _zx_init
EXTERN _zx_shutdown
ENDIF

; Start the SDK once SP, DATA and BSS are ready. On failure branch to the
; caller's handler with a zero-extended zx_status_t in HL.
        MACRO ZX_CRT_INIT on_failure
IF CRT_ENABLE_ZX_LIFECYCLE
        call _zx_init
        ld a,l
        or a
        ld h,0
        jr nz,on_failure
ENDIF
        ENDM

; Run CRT cleanup while the SDK is available, then shut down the SDK.
; HL is the 16-bit exit result on entry and return. Preserve a nonzero
; init/app result. Otherwise report the shutdown status.
        MACRO ZX_CRT_CLEANUP
        push hl
        call crt0_exit
IF CRT_ENABLE_ZX_LIFECYCLE
        call _zx_shutdown
        pop de
        ld a,d
        or e
        ex de,hl
        jr nz,zx_crt_exit_result
        ld l,e
zx_crt_exit_result:
ELSE
        pop hl
ENDIF
        ENDM
