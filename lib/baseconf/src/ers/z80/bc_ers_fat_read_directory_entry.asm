        MODULE bc_ers_fat_read_directory_entry

SECTION code_clib
PUBLIC _bc_ers_fat_read_directory_entry
EXTERN _bc_ers_profile

; Copies one FAT directory entry from the requested position into the
; caller's buffer.
;
; Model:
;
; if (!entry) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x01, BC=position, HL=entry); return OK;
;
; IX frame: position word +4, entry pointer +6. Caller provides a 32-byte record.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_read_directory_entry:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,h
        or l
        jp z,bc_ers_fat_read_directory_entry_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_read_directory_entry_unavailable
        ld c,(ix+4)
        ld b,(ix+5)
        rst 08h
        defb 51h,01h
        pop ix
        ld hl,0
        ret
bc_ers_fat_read_directory_entry_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_fat_read_directory_entry_unavailable:
        pop ix
        ld hl,3
        ret
