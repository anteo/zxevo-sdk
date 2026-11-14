; Private common blitter frame, IX anchored after saving caller IX.
; Positive fields: return +2, descriptor +4, x +6, y +8, optional key +10.
; All negative fields are persistent locals, never outgoing C arguments.
defc BLIT_SRC = -2             ; current source row pointer
defc BLIT_STRIDE = -4          ; original source row stride
defc BLIT_WIDTH = -6           ; clipped row width, pixels
defc BLIT_HEIGHT = -8          ; remaining row count
defc BLIT_X = -10              ; clipped destination x
defc BLIT_Y = -12              ; current destination y
defc BLIT_HALF = -13           ; first source pixel: 0=high, 1=low nibble
defc BLIT_KEY = -14            ; 0..15 or FFh for opaque
defc BLIT_AXIS_SKIP = -16      ; clipping helper's skipped source pixels/rows
defc BLIT_SCREEN_WIDTH = -18
defc BLIT_SCREEN_HEIGHT = -20
defc BLIT_SOURCE_END = -22     ; exclusive end of original source footprint
defc BLIT_COUNT = -24          ; span backend: remaining pixels
defc BLIT_SRC_HALF = -25       ; span backend: current source nibble
defc BLIT_DEST_PHASE = -26     ; span backend: destination x modulo 8
defc BLIT_FRAME_SIZE = 26
