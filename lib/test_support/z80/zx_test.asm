; Set up the test with maskable interrupts disabled. Clobbers AF, BC, DE and HL.
zx_test_init:
    di
    xor a
    ld (zx_test_step_number), a
    jp zx_host_init

; Announce the step name at HL and wait for host acknowledgement.
; Clobbers AF, BC, DE and HL.
zx_test_step_begin:
    ld a, ZX_TEST_FLAG_MORE | ZX_TEST_FLAG_BEGIN
    jr zx_test_step_event

; Send the output descriptor at HL (0 for no log) and the flags in A. Wait
; until the host has collected the result. Clobbers AF, BC, DE and HL.
zx_test_step:
    or ZX_TEST_FLAG_MORE
    call zx_test_step_event
    ld hl, zx_test_step_number
    inc (hl)
    ret

zx_test_step_event:
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_RESULT2), a
    call zx_host_write_log
    ld a, (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_SEQUENCE)
    ld c, a
    xor a
    call zx_test_publish
.wait:
    ld a, (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_SEQUENCE)
    cp c
    jr z, .wait
    ret

; Complete the test with status A (0 = pass, 1 = fail) and a log string in HL.
; Pass HL = 0 when there is no completion message.
zx_test_finish:
    push af
    call zx_host_write_log
    xor a
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_RESULT2), a
    pop af
    call zx_test_publish
.finished:
    jr .finished

zx_test_publish:
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_RESULT0), a
    ld a, (zx_test_step_number)
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_RESULT1), a
    xor a
    ld (ZX_HOST_HEADER_ADDRESS + ZX_HOST_FIELD_RESULT3), a
    ld a, ZX_HOST_STATE_DONE
    jp zx_host_finish

zx_test_step_number:
    db 0

; Reset the NUL-terminated TOML buffer. Clobbers HL.
zx_test_output_begin:
    ld hl, zx_test_output_buffer
    ld (zx_test_output_cursor), hl
    ld (hl), 0
    ret

; Append the NUL-terminated field at HL. Keep one byte for the terminator.
; Clobbers AF, BC, DE and HL. An overflow terminates the test with FAIL.
zx_test_output_append:
    ld de, (zx_test_output_cursor)
    ld bc, zx_test_output_end - 1
.next:
    ld a, (hl)
    or a
    jr z, .finish
    ld a, d
    cp b
    jr nz, .copy
    ld a, e
    cp c
    jr z, .overflow
.copy:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    jr .next
.finish:
    ld (de), a
    ld (zx_test_output_cursor), de
    ret
.overflow:
    ld a, 1
    ld hl, .overflow_message
    jp zx_test_finish
.overflow_message:
    db "TOML output buffer is full", 0

; Write A as two hexadecimal digits and advance HL. Preserves BC and DE.
zx_test_format_hex8:
    push af
    rrca
    rrca
    rrca
    rrca
    call .digit
    pop af
.digit:
    and 0x0f
    add a, '0'
    cp '9' + 1
    jr c, .store
    add a, 'A' - '9' - 1
.store:
    ld (hl), a
    inc hl
    ret

zx_test_output_cursor:
    dw 0
zx_test_output_buffer:
    defs ZX_TEST_OUTPUT_CAPACITY, 0
zx_test_output_end:
