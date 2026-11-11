        MODULE bc_ers_fat_read_file

SECTION code_clib
PUBLIC _bc_ers_fat_read_file
EXTERN _bc_ers_profile

defc BC_FAT_READ_SECTORS = 4
defc BC_FAT_READ_BUFFER = 5
defc BC_FAT_READ_RESULT = 7

; Reads sectors from the open file and reports the advanced buffer address
; and firmware end or error flag.
;
; Model:
;
; if (!buffer || !result) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x09, A=sectors, HL=buffer); result->next_address = HL; result->carry = CF;
; return OK; /* CF reports firmware end/error independently of ZX_OK */
;
; The caller pushes one byte for sectors followed by two 16-bit pointers.
; IX addresses saved IX and the return address before the arguments.
; AF is stacked while storing the next address to preserve the returned CF.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_read_file:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+BC_FAT_READ_BUFFER)
        ld h,(ix+BC_FAT_READ_BUFFER+1)
        ld a,h
        or l
        jp z,bc_ers_fat_read_file_invalid
        ld e,(ix+BC_FAT_READ_RESULT)
        ld d,(ix+BC_FAT_READ_RESULT+1)
        ld a,d
        or e
        jp z,bc_ers_fat_read_file_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_read_file_unavailable
        ld a,(ix+BC_FAT_READ_SECTORS)
        rst 08h
        defb 51h,09h
        push af
        ld e,(ix+BC_FAT_READ_RESULT)
        ld d,(ix+BC_FAT_READ_RESULT+1)
        ld a,l
        ld (de),a
        inc de
        ld a,h
        ld (de),a
        inc de
        pop af
        ld a,0
        adc a,0
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_fat_read_file_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_fat_read_file_unavailable:
        pop ix
        ld hl,3
        ret
