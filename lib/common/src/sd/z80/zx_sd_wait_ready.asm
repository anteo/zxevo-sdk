        MODULE zx_sd_wait_ready
EXTERN zx__sd_wait_regs
SECTION code_clib
PUBLIC _zx_sd_wait_ready
_zx_sd_wait_ready:
        ld a,0FFh
        jp zx__sd_wait_regs
