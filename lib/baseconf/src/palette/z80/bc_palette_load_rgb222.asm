        MODULE bc_palette_load_rgb222
SECTION code_clib
PUBLIC _bc_palette_load_rgb222
EXTERN _bc_mem_initialized
EXTERN _bc_mem_active_window_lease
EXTERN _bc_video_operation_depth
EXTERN _bc_newirq_enabled
EXTERN _bc_read_video_output
EXTERN bc__palette_encode_rgb222_regs
EXTERN bc__mem_readback_register_regs
EXTERN _bc__mem_shadow_scope_open
EXTERN bc__mem_shadow_scope_end_regs
EXTERN bc__palette_fdd_control_from_status_regs
EXTERN bc__video_system_port_for_regs
EXTERN bc__palette_restore_atm_ports_regs
EXTERN _zx_set_border_color

defc PAL_BYTES = -16           ; 16 pre-encoded hardware bytes, indices 0..15
defc PAL_OUTPUT = -20          ; bc_video_output_t, four bytes
defc PAL_BF = -21
defc PAL_CONFIG = -22
defc PAL_FDD = -23
defc PAL_BORDER = -24
defc PAL_FRAME_SIZE = 24

; Load all RGB222 entries during the initial border after a standard frame IRQ.
; The frame wait is essential: BD_COLORRD reports the current encoded RGB,
; not a palette index or blanking flag, so polling it cannot select an entry.
;
; Model:
;
; require(initialized && IFF && !video_lease && !window_lease && !newirq);
; encoded[16] = encode_checked_rgb222(colors[16]);
; require(read_video_output().raster in {PENTAGON,60HZ} && !rgb444);
; HALT(); DI(); /* sole frame ISR returns within the documented time budget */
; save_bf_config_fdd_border(); enable_shadow_and_palette_writes();
; for (index=0; index<16; ++index) {
;     OUT(index&8 ? 0x80f6 : 0x80fc,index&7);
;     OUT(0x80ff,encoded[index]);
; }
; restore_fdd_config_border_bf(); EI(); return OK;
;
; Fastcall HL=16 bytes 00RRGGBB in ascending index order; status in L.
; AF/BC/DE/HL volatile, IX/IY preserved. IX anchors 24 private bytes after
; saved IX/IY; PAL_OUTPUT is separate from the outgoing pointer argument.
; Caller excludes NMI, external IRQs and changes to raster/palette/paging/AVR.
; Only the standard non-latched frame IRQ may wake HALT; its handler must
; preserve registers and return within 4096 T at 3.5MHz (1.17ms). This is not
; an ISR-callable function. No progress/timeout is possible if IRQ is absent.
;
; RTL video_sync_v gives at least 42 lines from frame IRQ to active pixels for
; the accepted rasters (224 T/line at 3.5MHz). Post-HALT setup, 16 writes and
; restoration take less than 4096 T at 3.5MHz, so the whole packet fits before
; active video even with the stated ISR budget. Cache/turbo only shorten it.
; video_top disables border_sync for these rasters: FC/F6 chooses the actual
; palette index before FF. Raster 48/128 synchronizes border changes and is
; rejected. FC/F6 avoid FE beeper writes and accidental 7FFD address decode.
_bc_palette_load_rgb222:
        ld a,i
        jp po,unsafe_entry
        ld a,h
        or l
        jp z,invalid_entry
        ld de,15
        add hl,de
        jp c,invalid_entry
        or a
        sbc hl,de
        ld a,(_bc_mem_initialized)
        or a
        jp z,uninitialized_entry
        ld a,(_bc_video_operation_depth)
        or a
        jp nz,busy_entry
        push hl
        ld hl,(_bc_mem_active_window_lease)
        ld a,h
        or l
        pop hl
        jp nz,busy_entry
        ld a,(_bc_newirq_enabled)
        or a
        jp nz,unsafe_entry
        push ix
        push iy
        ld ix,0
        add ix,sp
        ex de,hl                     ; DE=source
        ld hl,-PAL_FRAME_SIZE
        add hl,sp
        ld sp,hl
        push ix
        pop iy
        ld bc,PAL_BYTES
        add iy,bc                    ; IY=encoded palette
        ex de,hl                     ; HL=source
        ld b,16
@encode:
        ld a,(hl)
        cp 64
        jp nc,invalid_frame
        ld e,a
        and 3
        ld c,a                       ; blue
        ld a,e
        rrca
        rrca
        and 3
        ld d,a                       ; green
        ld a,e
        rrca
        rrca
        rrca
        rrca
        and 3
        ld e,a                       ; red
        push hl
        call bc__palette_encode_rgb222_regs ; preserves B/IY
        pop hl
        ld (iy+0),a
        inc iy
        inc hl
        djnz @encode

        push ix
        pop hl
        ld de,PAL_OUTPUT
        add hl,de
        push hl
        call _bc_read_video_output
        pop de
        ld a,l
        or a
        jp nz,return_frame
        ld a,(ix+PAL_OUTPUT)
        cp 2
        jp nc,unsupported_frame
        ld bc,00bfh
        in a,(c)
        bit 5,a
        jp nz,unavailable_frame
        ; All rejection paths above precede any palette/beam manipulation.
        halt
        di
        ; Snapshot after the IRQ, so its normal state changes are retained.
        ld bc,00bfh
        in a,(c)
        ld (ix+PAL_BF),a
        ld b,0ch
        call bc__mem_readback_register_regs
        ld (ix+PAL_CONFIG),l
        ld b,0fh
        call bc__mem_readback_register_regs
        ld a,l
        and 15
        ld (ix+PAL_BORDER),a
        ld l,(ix+PAL_BF)
        call _bc__mem_shadow_scope_open
        ld bc,00ffh
        in a,(c)
        call bc__palette_fdd_control_from_status_regs
        ld (ix+PAL_FDD),a
        ld a,(ix+PAL_CONFIG)
        ld c,1
        call bc__video_system_port_for_regs
        ld b,h
        ld c,l
        ld a,(ix+PAL_CONFIG)
        and 15
        out (c),a                    ; open FF palette strobe
        push ix
        pop hl
        ld de,PAL_BYTES
        add hl,de
        ld e,0
        ld b,080h
@write:
        ld a,e
        and 7
        ld c,0fch
        bit 3,e
        jr z,@border
        ld c,0f6h
@border:
        out (c),a
        ld c,0ffh
        ld a,(hl)
        out (c),a
        inc hl
        inc e
        ld a,e
        cp 16
        jr nz,@write
        ld e,(ix+PAL_CONFIG)
        ld d,(ix+PAL_FDD)
        call bc__palette_restore_atm_ports_regs
        ld l,(ix+PAL_BORDER)
        call _zx_set_border_color
        ld a,(ix+PAL_BF)
        call bc__mem_shadow_scope_end_regs
        ld l,0
        ld sp,ix
        pop iy
        pop ix
        ei
        ret

invalid_frame:
        ld l,1
        jr return_frame
unsupported_frame:
        ld l,5
        jr return_frame
unavailable_frame:
        ld l,3
return_frame:
        ld sp,ix
        pop iy
        pop ix
        ret
invalid_entry:
        ld l,1
        ret
busy_entry:
        ld l,2
        ret
uninitialized_entry:
        ld l,4
        ret
unsafe_entry:
        ld l,6
        ret
