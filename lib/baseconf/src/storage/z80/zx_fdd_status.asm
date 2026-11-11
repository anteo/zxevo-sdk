        MODULE zx_fdd_status
SECTION code_clib
PUBLIC _zx_fdd_status
EXTERN _bc__mem_shadow_scope_begin
EXTERN _bc__mem_shadow_scope_end

; Read the FDD system/status byte under a temporary shadow-port scope.
;
; if (!status) return ZX_INVALID_ARGUMENT;
; saved_bf = shadow_scope_begin();
; *status = in(0x00ff);
; shadow_scope_end(saved_bf);
; return ZX_OK;
;
; Fastcall HL=output pointer, status in L. Preserve IX/IY,
; clobber AF/BC/DE/HL. INT state is unchanged.
_zx_fdd_status:
        ex de,hl
        ld a,d
        or e
        jr z,@invalid
        call _bc__mem_shadow_scope_begin
        ld bc,00FFh
        in a,(c)
        ld (de),a
        call _bc__mem_shadow_scope_end
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
