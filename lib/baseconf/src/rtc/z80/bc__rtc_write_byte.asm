        MODULE bc__rtc_write_byte
SECTION code_clib
PUBLIC _bc__rtc_write_byte
EXTERN _zx_interrupt_save_disable
EXTERN _zx_interrupt_restore
EXTERN _bc__mem_shadow_scope_begin
EXTERN _bc__mem_shadow_scope_end
EXTERN bc__rtc_write_scoped_regs

; Write one RTC byte with a temporary shadow-port scope and INT masked.
;
; irq = interrupt_save_disable(); bf = shadow_scope_begin();
; rtc_write_scoped(index,value);
; shadow_scope_end(bf); interrupt_restore(irq);
; return ZX_OK;
;
; SDCC index at SP+2, value at SP+3, status in L. H/E hold index/value
; across scope entry. The stack holds the prior INT and BF states.
; Preserve D/IX/IY, clobber AF/BC/E/HL.
_bc__rtc_write_byte:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
        ld h,a
        call _zx_interrupt_save_disable
        push hl                      ; saved INT state in L
        call _bc__mem_shadow_scope_begin
        push hl                      ; saved BF in L
        ld a,h
        call bc__rtc_write_scoped_regs
        pop hl
        call _bc__mem_shadow_scope_end
        pop hl
        call _zx_interrupt_restore
        ld l,0                       ; ZX_OK
        ret
