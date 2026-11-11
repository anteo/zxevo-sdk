        MODULE ts_io_set_interrupt_mask
SECTION code_clib
PUBLIC _ts_io_set_interrupt_mask

; Set the interrupt source mask. Fastcall L = value. Clobbers BC only.
_ts_io_set_interrupt_mask:
        ld bc,2aafh
        out (c),l
        ret
