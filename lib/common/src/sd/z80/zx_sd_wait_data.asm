        MODULE zx_sd_wait_data
EXTERN zx__sd_wait_regs
SECTION code_clib
PUBLIC _zx_sd_wait_data

; Wait for the SPI read-data token FEh using the caller's poll budget.
_zx_sd_wait_data:
        ld a,0FEh
        jp zx__sd_wait_regs
