SECTION code_user
PUBLIC _main

_main:
        ld hl,0
        ret

; Use two nonadjacent physical pages with different offsets within W3.
SECTION BANK_1B
        ORG 0x1bc040
        defb 0x1b,0x55,0xaa,0x4d

SECTION BANK_A5
        ORG 0xa5c123
        defb 0xa5,0x6e,0x91,0x27,0x32
