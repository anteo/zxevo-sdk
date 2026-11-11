        MODULE bc_ers_device_find

SECTION code_clib
PUBLIC _bc_ers_device_find
EXTERN _bc_ers_profile

; Asks ERS to discover storage devices and returns the current partition
; details and discovery result.
;
; Model:
;
; if (!info) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x00);
; *info = { .current_partition=D, .partition_count=E, .fat_type=A, .found=!CF };
; return OK;
;
; Entry SP+2 = info pointer. Result capture IX: DE +0, BC +2, AF +4,
; info pointer +6, saved IX +8. Capture F before later stores affect flags.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_find:
        pop bc                      ; return address
        pop hl                      ; output pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_device_find_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_find_unavailable

        push ix
        push hl
        rst 08h
        defb 50h,00h
        push af
        push bc
        push de
        ld ix,0
        add ix,sp
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,(ix+1)                 ; D: current partition index
        ld (hl),a
        inc hl
        ld a,(ix+0)                 ; E: partition count
        ld (hl),a
        inc hl
        ld a,(ix+5)                 ; A: FAT type
        ld (hl),a
        inc hl
        ld a,(ix+4)                 ; F.C: no partition found
        and 1
        jr nz,found_none
        ld a,1
        jr found_done
found_none:
        xor a
found_done:
        ld (hl),a
        pop de
        pop bc
        pop af
        pop hl
        pop ix
        ld hl,0                     ; ZX_OK
        ret
bc_ers_device_find_invalid:
        ld hl,1
        ret
bc_ers_device_find_unavailable:
        ld hl,3
        ret
