        MODULE bc_ers_fat_position_files

SECTION code_clib
PUBLIC _bc_ers_fat_position_files
EXTERN _bc_ers_profile

; Saves, restores, moves or queries the directory position and writes the
; returned position back to the caller.
;
; Model:
;
; if (operation >= 8 || !position) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x0b, A=operation, BC=*position); *position = BC; return OK;
;
; SDCC packs the operation at IX+4 and the position pointer at IX+5..6.
; Position is input/output, including for query operations.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_position_files:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+4)
        cp 8
        jp nc,bc_ers_fat_position_files_invalid
        ld e,(ix+5)
        ld d,(ix+6)
        ld a,d
        or e
        jp z,bc_ers_fat_position_files_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_position_files_unavailable
        ld a,(de)
        ld c,a
        inc de
        ld a,(de)
        ld b,a
        ld a,(ix+4)
        rst 08h
        defb 51h,0bh
        ld e,(ix+5)
        ld d,(ix+6)
        ld a,c
        ld (de),a
        inc de
        ld a,b
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_fat_position_files_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_fat_position_files_unavailable:
        pop ix
        ld hl,3
        ret
