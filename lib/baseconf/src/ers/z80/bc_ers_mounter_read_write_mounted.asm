        MODULE bc_ers_mounter_read_write_mounted

SECTION code_clib
PUBLIC _bc_ers_mounter_read_write_mounted
EXTERN _bc_ers_profile

; Transfers one 256-byte sector to or from an image mounted on a virtual
; drive.
;
; Model:
;
; if (drive >= 4 || !buffer || sector == 0) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x01, A=drive | (write ? 0x80 : 0), D=track, E=sector, HL=buffer);
; return OK;
;
; IX frame used here: drive +4, write +5, track +6, sector +7, buffer +8.
; Track is zero-based, sector is one-based; buffer holds one 256-byte sector.
; Firmware transfer flags are not exposed through the returned status.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_read_write_mounted:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+4)
        cp 4
        jp nc,bc_ers_mounter_read_write_mounted_invalid
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jp z,bc_ers_mounter_read_write_mounted_invalid
        ld a,(ix+7)
        or a
        jp z,bc_ers_mounter_read_write_mounted_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_read_write_mounted_unavailable
        ld e,(ix+7)
        ld d,(ix+6)
        ld a,(ix+5)
        or a
        ld a,(ix+4)
        jr z,bc_ers_mounter_read_write_mounted_read
        or 80h
bc_ers_mounter_read_write_mounted_read:
        rst 08h
        defb 53h,01h
        pop ix
        ld hl,0
        ret
bc_ers_mounter_read_write_mounted_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_mounter_read_write_mounted_unavailable:
        pop ix
        ld hl,3
        ret
