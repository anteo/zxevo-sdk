; Private IX frame shared by horizontal-scroll dispatch and row kernels.
; IX+0: saved IX, IX+2: return address; SDCC packed byte arguments follow.
defc BC_SCROLL_PIXELS = 4
defc BC_SCROLL_RIGHT = 5

; Persistent locals are allocated once per operation, not once per row.
defc BC_SCROLL_Y = -1
defc BC_SCROLL_BLANK = -2

; Packed: encoded paper pair, page-base XOR, and streaming pair cursors.
defc BC_SCROLL_PAGE_XOR = -3
defc BC_SCROLL_SOURCE_LEFT = -4
defc BC_SCROLL_DEST_PHASE = -5
defc BC_SCROLL_CARRY = -6
defc BC_SCROLL_PAIR_COUNT = -7
defc BC_SCROLL_PACKED_LOCALS = 7

; ATM640 uses the same first two fields and caches its attribute separately.
defc BC_SCROLL_ATTRIBUTE = -3
