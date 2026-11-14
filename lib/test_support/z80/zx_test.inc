    include "zx_host_config.inc"

ZX_TEST_FLAG_SHOT equ 0x01
ZX_TEST_FLAG_MORE equ 0x02
ZX_TEST_FLAG_DATA equ 0x04
ZX_TEST_FLAG_BEGIN equ 0x08
ZX_TEST_OUTPUT_CAPACITY equ 512

    macro ZX_TEST_BEGIN title
        jr .report
.message:
        db title, 0
.report:
        ld hl, .message
        call zx_test_step_begin
    endm

    macro ZX_TEST_MARKER
        xor a
        ld hl, 0
        call zx_test_step
    endm

    macro ZX_TEST_SHOT
        ld a, ZX_TEST_FLAG_SHOT
        ld hl, 0
        call zx_test_step
    endm

; kind: 0 = hex dump, 1 = text, 2 = binary, 3 = TOML with optional NUL terminator.
; The buffer stays mapped until resume.
    macro ZX_TEST_DATA address, length, kind
        assert length > 0 && address >= 0 && address + length <= 0x10000
        assert kind >= 0 && kind <= 3
        jr .report
.message:
        db "DATA "
        ZX_TEST_DECIMAL address
        db " "
        ZX_TEST_DECIMAL length
        db " ", '0' + kind, 0
.report:
        ld hl, .message
        ld a, ZX_TEST_FLAG_DATA
        call zx_test_step
    endm

; Append a TOML field after CALL zx_test_output_begin. Use a bare TOML key
; and an operand accepted by LD A,source or LD DE,source, respectively.
    macro ZX_TEST_FIELD key, source
        jr .emit
.field:
        db key, " = 0x"
.digits:
        db "00", 10, 0
.emit:
        ld a, source
        ld hl, .digits
        call zx_test_format_hex8
        ld hl, .field
        call zx_test_output_append
    endm

    macro ZX_TEST_FIELD16 key, source
        jr .emit
.field:
        db key, " = 0x"
.digits:
        db "0000", 10, 0
.emit:
        ld de, source
        ld hl, .digits
        ld a, d
        call zx_test_format_hex8
        ld a, e
        call zx_test_format_hex8
        ld hl, .field
        call zx_test_output_append
    endm

    macro ZX_TEST_TOML
        ZX_TEST_DATA zx_test_output_buffer, ZX_TEST_OUTPUT_CAPACITY, 3
    endm

    macro ZX_TEST_DECIMAL value
        db '0' + (((value) / 10000) % 10), '0' + (((value) / 1000) % 10)
        db '0' + (((value) / 100) % 10), '0' + (((value) / 10) % 10), '0' + ((value) % 10)
    endm
