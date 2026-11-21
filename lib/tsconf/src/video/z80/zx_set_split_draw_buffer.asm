        MODULE zx_set_split_draw_buffer
SECTION code_clib
PUBLIC _zx_set_split_draw_buffer
PUBLIC _zx_prepare_split_draw_buffer

; TSConf draw formats all use one physical base page.
; SDCC caller-clean. Return ZX_UNSUPPORTED in L and preserve paging and draw state.
_zx_prepare_split_draw_buffer:
        ld hl,2
        add hl,sp
        ld a,(hl)                    ; slot at SP+2
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
_zx_set_split_draw_buffer:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
