; Private frame owned by zx__scroll_zx_plane (not its callers).
; IX+0 = saved IX, IX+2 = return address. Natural push order saves base/paint.
defc ZX_SCROLL_UP_BASE = -2       ; word: CPU plane origin
defc ZX_SCROLL_UP_BLANK = -3      ; byte: encoded fill
defc ZX_SCROLL_UP_ROWS = -4       ; byte: clamped pixel-row displacement
defc ZX_SCROLL_UP_Y = -5          ; byte: logical destination row
defc ZX_SCROLL_UP_COPY_ROWS = -6  ; byte: 192 - displacement
