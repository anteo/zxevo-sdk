        MODULE zx_set_cpu_speed
SECTION code_clib
PUBLIC _zx_set_cpu_speed
EXTERN ts__cache_mask
EXTERN _ts_io_set_system_config
EXTERN _ts_memory_set_cache

; Set the CPU clock without losing the known per-window cache mask.
;
; if (speed > 2) return INVALID_ARGUMENT;
; if (cache_mask == 0xff) return NOT_INITIALIZED;
; sysconfig(speed | (cache_mask == 15 ? 4 : 0));
; if (cache_mask != 0 && cache_mask != 15) cacheconfig(cache_mask);
; return OK;
;
; Fastcall L=speed, L=status. Preserve IX/IY, clobber AF/BC/HL.
; Serialize the register pair with other clock and cache users.
_zx_set_cpu_speed:
        ld a,l
        cp 3
        jr nc,@invalid
        ld a,(ts__cache_mask)
        cp 0ffh
        jr z,@unknown
        push af
        cp 0fh
        jr nz,@write
        set 2,l
@write:
        call _ts_io_set_system_config
        pop af
        or a
        jr z,@success
        cp 0fh
        jr z,@success
        ld l,a
        call _ts_memory_set_cache
@success:
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@unknown:
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret
