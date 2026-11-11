        MODULE ts_set_cpu_speed_and_cache
SECTION code_clib
PUBLIC _ts_set_cpu_speed_and_cache
EXTERN _ts_io_set_system_config

; Select the CPU clock and apply the same cache setting to all four windows.
;
; if (speed > ZX_CPU_14_MHZ) return ZX_INVALID_ARGUMENT;
; OUT(0x20af, speed | (cache_enabled ? 4 : 0));
; return ZX_OK;
;
; SDCC speed at SP+2, cache_enabled at SP+3, status in L.
; Clobbers AF/BC/E/HL. Preserves D/IX/IY.
_ts_set_cpu_speed_and_cache:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 3
        jr nc,@invalid
        ld e,a
        inc hl
        ld a,(hl)
        or a
        jr z,@write
        set 2,e
@write:
        ld l,e
        call _ts_io_set_system_config
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
