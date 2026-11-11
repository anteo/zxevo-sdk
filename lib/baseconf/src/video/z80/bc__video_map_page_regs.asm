        MODULE bc__video_map_page_regs
SECTION code_clib
PUBLIC bc__video_map_page_regs
EXTERN _bc_video_cpu_base
EXTERN _bc_video_mapped_page
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Select the CPU base of an already mapped draw page. Model:
;
; if (cpu_base && mapped_page == page) return OK;
; if      (page == surface.page0) base = page0_base;
; else if (page == surface.page1) base = page1_base;
; else                           return UNAVAILABLE;
; if (!base) return UNAVAILABLE;
; cpu_base = base; mapped_page = page; return OK;
;
; C = page, return A=L=status and Z iff OK. Preserve BC/DE/IX/IY; clobber
; AF/HL. Both bases come from the prepared lease (or its begin setup).
; Selection changes software state only; failed selection leaves it untouched.
bc__video_map_page_regs:
        ld hl,(_bc_video_cpu_base)
        ld a,h
        or l
        jr z,@select
        ld a,(_bc_video_mapped_page)
        cp c
        jr z,@ok
@select:
        ld a,(_bc_video_draw_surface_state+1)
        cp c
        ld hl,(_bc_video_page0_base)
        jr z,@base                   ; page0 wins when the two page IDs match
        ld a,(_bc_video_draw_surface_state+2)
        cp c
        jr nz,@unavailable
        ld hl,(_bc_video_page1_base)
@base:
        ld a,h
        or l
        jr z,@unavailable
        ld (_bc_video_cpu_base),hl
        ld a,c
        ld (_bc_video_mapped_page),a
@ok:
        xor a
        ld l,a
        ret
@unavailable:
        ld a,3                       ; ZX_UNAVAILABLE
        or a
        ld l,a
        ret
