        MODULE bc__video_memory_address

SECTION code_clib
PUBLIC bc__video_memory_address
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Register ABI: A = page, DE = offset. Return HL = address, CF = unavailable.
; Preserve C/DE/IX/IY. SDCC bc_surface_t is { mode:8, page0:8, page1:8 }.
;
; Resolves a selected surface page and byte offset to a CPU address,
; reporting when no matching page is available.
;
; Model:
;
; if (!lease) return unavailable;
; if (page==surface.page0) base=page0_base;
; else if (page==surface.page1) base=page1_base; else return unavailable;
; return (uint16_t)(base+offset);
;
; Bases must already be prepared by the lease owner. AF/B/HL volatile;
; C/DE/IX/IY preserved. A zero CPU base is not rejected; page0 wins when both
; physical pages match. CF is cleared after addition even if the address wraps.
bc__video_memory_address:
        ld b,a
        ld a,(_bc_video_operation_depth)
        or a
        jr z,@unavailable
        ld a,(_bc_video_draw_surface_state+1)
        cp b
        ld hl,(_bc_video_page0_base)
        jr z,@address
        ld a,(_bc_video_draw_surface_state+2)
        cp b
        jr nz,@unavailable
        ld hl,(_bc_video_page1_base)
@address:
        add hl,de
        or a                         ; wrapping address arithmetic is permitted
        ret
@unavailable:
        scf
        ret
