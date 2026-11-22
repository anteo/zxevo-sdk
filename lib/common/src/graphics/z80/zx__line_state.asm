        MODULE zx__line_state
SECTION bss_graphics
PUBLIC zx__line_major
PUBLIC zx__line_minor
PUBLIC zx__line_last
PUBLIC zx__line_major_delta
PUBLIC zx__line_minor_delta
PUBLIC zx__line_major_step
PUBLIC zx__line_minor_step
PUBLIC zx__line_error
PUBLIC zx__line_y_major

; Shared with the slow clipper. Both paths initialize these fields in place.
zx__line_major:       defw 0
zx__line_minor:       defw 0
zx__line_last:        defw 0
zx__line_major_delta: defw 0
zx__line_minor_delta: defw 0
zx__line_major_step:  defw 0
zx__line_minor_step:  defw 0
zx__line_error:       defw 0
zx__line_y_major:     defb 0
