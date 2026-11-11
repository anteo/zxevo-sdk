        MODULE bc__mem_apply_window
SECTION code_clib
PUBLIC _bc__mem_apply_window
EXTERN _bc__mem_shadow_scope_begin
EXTERN bc__mem_shadow_scope_end_regs
EXTERN _bc_get_active_map
EXTERN _bc_mem_window_cache

; Program one window in the hardware-selected map and update its cached entry.
;
; port = 0x3ff7 | (window << 14);
; page = (uint8_t)~config->physical_page;
; saved_bf = shadow_scope_begin();
; out(port, (page & 0x3f) | (config->kind == BC_RAM ? 0x40 : 0) |
;           (config->substitute_from_7ffd_or_dos ? 0x80 : 0));
; if (config->kind == BC_RAM) out(port & ~0x0800, page);
; out(port & ~0x0400, config->write_protected);
; shadow_scope_end(saved_bf);
; window_cache[bc_get_active_map()][window] = *config;
;
; SDCC window byte at SP+2, config pointer at SP+3. The caller validates
; window 0..3, kind (RAM=0, Flash=1), and both 0/1 flags. The four-byte
; config, code and stack must remain accessible throughout the remap.
; Stack saves hold the window and BF. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc__mem_apply_window:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        push af
        call _bc__mem_shadow_scope_begin
        pop af
        push af
        push hl                      ; L = saved BF

        rrca
        rrca
        or 3Fh                       ; type port high byte = 3Fh | window*64
        ld b,a
        ld c,0F7h
        ex de,hl
        ld d,(hl)                    ; kind
        inc hl
        ld a,(hl)
        cpl
        ld e,a                       ; full inverted page for the RAM port
        and 3Fh
        bit 0,d
        jr nz,@type_flags
        or 40h
@type_flags:
        inc hl
        bit 0,(hl)
        jr z,@type
        or 80h
@type:
        out (c),a
        bit 0,d
        jr nz,@protect
        res 3,b                      ; page port high byte = 37h | window*64
        out (c),e
        set 3,b
@protect:
        res 2,b                      ; protection port = 3Bh | window*64
        inc hl
        ld a,(hl)
        out (c),a

        pop de
        ld a,e
        call bc__mem_shadow_scope_end_regs
        dec hl
        dec hl
        dec hl
        pop af
        add a,a
        add a,a
        ld e,a
        ld d,0                       ; window offset within one map's cache
        push hl
        call _bc_get_active_map       ; temporary hardware map may differ from software state
        ld hl,_bc_mem_window_cache
        jr z,@cache
        ld hl,_bc_mem_window_cache+16
@cache:
        add hl,de
        ex de,hl
        pop hl
        ld bc,4
        ldir
        ret
