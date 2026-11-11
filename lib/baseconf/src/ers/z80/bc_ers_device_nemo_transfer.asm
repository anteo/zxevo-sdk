        MODULE bc_ers_device_nemo_transfer

SECTION code_clib
PUBLIC _bc_ers_device_nemo_transfer
EXTERN _bc_ers_profile

defc BC_NEMO_DIRECTION = 4
defc BC_NEMO_DEVICE = 5
defc BC_NEMO_COUNT = 6
defc BC_NEMO_SECTOR = 7
defc BC_NEMO_BUFFER = 11
defc BC_NEMO_RESULT = 13

; Reads or writes sectors through Nemo IDE and reports the driver status,
; returned sector and next buffer address.
;
; Model:
;
; if (direction > WRITE || !buffer || !result) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x07, direction == WRITE ? 3 : 2, A=count, A_alt=device, BCDE=sector, HL=buffer);
; *result = { .device_status=A, .sector=BCDE, .next_buffer=HL }; return OK;
;
; SDCC packs direction, device and count as one byte each. IX addresses the
; saved IX and return address, followed by these bytes, the 32-bit LBA and
; the two 16-bit pointers. The BC_NEMO_* offsets start after those four bytes.
; Returned AF/HL/DE/BC are stacked before IX becomes result; restore all before
; serializing the seven-byte result in little-endian order.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_nemo_transfer:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+BC_NEMO_DIRECTION)
        cp 2
        jp nc,bc_ers_device_nemo_transfer_invalid
        ld l,(ix+BC_NEMO_BUFFER)
        ld h,(ix+BC_NEMO_BUFFER+1)
        ld a,h
        or l
        jp z,bc_ers_device_nemo_transfer_invalid
        ld l,(ix+BC_NEMO_RESULT)
        ld h,(ix+BC_NEMO_RESULT+1)
        ld a,h
        or l
        jp z,bc_ers_device_nemo_transfer_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_nemo_transfer_unavailable
        ld a,(ix+BC_NEMO_DIRECTION)
        or a
        jr z,bc_ers_device_nemo_transfer_read
        call bc_ers_device_nemo_transfer_load_inputs
        rst 08h
        defb 50h,07h,03h
        jr bc_ers_device_nemo_transfer_save
bc_ers_device_nemo_transfer_read:
        call bc_ers_device_nemo_transfer_load_inputs
        rst 08h
        defb 50h,07h,02h
bc_ers_device_nemo_transfer_save:
        push bc
        push de
        push hl
        push af
        ld l,(ix+BC_NEMO_RESULT)
        ld h,(ix+BC_NEMO_RESULT+1)
        push hl
        pop ix                     ; result pointer
        pop af
        pop hl
        pop de
        pop bc
        ld (ix+0),a               ; device status
        ld (ix+1),e               ; sector, little endian
        ld (ix+2),d
        ld (ix+3),c
        ld (ix+4),b
        ld (ix+5),l               ; next buffer
        ld (ix+6),h
        pop ix
        ld hl,0
        ret
; Register bridge for the common read/write dispatch above:
; A_alt=device; A=count; BCDE=sector; HL=buffer.
; Input IX is the persistent argument frame; preserve IX/IY and reuse no C
; outgoing argument area. AF_alt/AF/BC/DE/HL are replaced with driver inputs.
bc_ers_device_nemo_transfer_load_inputs:
        ld a,(ix+BC_NEMO_DEVICE)  ; alternate A = device
        ex af,af'
        ld a,(ix+BC_NEMO_COUNT)   ; A = sector count
        ld e,(ix+BC_NEMO_SECTOR)  ; sector low word
        ld d,(ix+BC_NEMO_SECTOR+1)
        ld c,(ix+BC_NEMO_SECTOR+2) ; sector high word
        ld b,(ix+BC_NEMO_SECTOR+3)
        ld l,(ix+BC_NEMO_BUFFER)
        ld h,(ix+BC_NEMO_BUFFER+1)
        ret
bc_ers_device_nemo_transfer_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_device_nemo_transfer_unavailable:
        pop ix
        ld hl,3
        ret
