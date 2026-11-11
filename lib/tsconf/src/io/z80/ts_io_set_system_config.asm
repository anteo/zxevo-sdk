        MODULE ts_io_set_system_config
SECTION code_clib
PUBLIC _ts_io_set_system_config
EXTERN ts__cpu_speed
EXTERN ts__cache_mask

; Write SysConfig and record its clock selector and uniform cache mask.
;
; OUT(20AFh, config);
; speed = min(config & 3, 2); cache_mask = (config & 4) ? 15 : 0;
;
; Fastcall L=config, preserved. Clobber AF/BC. Serialize register access.
_ts_io_set_system_config:
        ld bc,20afh
        out (c),l
        ld a,l
        and 3
        cp 3
        jr nz,@clock
        dec a                        ; reserved selector also clocks at 14 MHz
@clock:
        ld (ts__cpu_speed),a
        ld a,l
        and 4
        jr z,@cache
        ld a,0fh
@cache:
        ld (ts__cache_mask),a
        ret
