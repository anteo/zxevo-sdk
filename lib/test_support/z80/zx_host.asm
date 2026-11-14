; Initialize the mailbox in W1 without modifying the request written by the host.
; Clobbers AF, BC, DE and HL.
zx_host_init:
    ld hl, .magic
    ld de, ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_MAGIC
    ld bc, 4
    ldir
    ld a, ZX_HOST_PROTOCOL_VERSION
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_VERSION), a
    xor a
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_STATE), a
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_FLAGS), a
    ld (ZX_HOST_LOG_ADDRESS), a
    ret
.magic:
    db ZX_HOST_MAGIC_0, ZX_HOST_MAGIC_1, ZX_HOST_MAGIC_2, ZX_HOST_MAGIC_3

; Replace the log with the NUL-terminated string at HL, or clear it when HL is 0.
; Clobbers AF, BC, DE and HL.
zx_host_write_log:
    ld de, ZX_HOST_LOG_ADDRESS
    ld a, h
    or l
    jr z, .terminate
    ld bc, ZX_HOST_LOG_SIZE - 1
.copy:
    ld a, (hl)
    or a
    jr z, .terminate
    ld (de), a
    inc de
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, .copy
.terminate:
    xor a
    ld (de), a
    ret

; Publish the state in A after the caller has written the result and log.
zx_host_finish:
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_STATE), a
    ret
