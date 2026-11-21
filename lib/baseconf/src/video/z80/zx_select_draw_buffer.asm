        MODULE zx_select_draw_buffer
INCLUDE "video/draw_buffer.inc"
SECTION code_clib
PUBLIC _zx_select_draw_buffer
EXTERN _bc__video_bind_draw_buffer
EXTERN _bc_video_prepared_buffers
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_operation_depth
EXTERN _bc_mem_active_window_lease
EXTERN _bc_video_slot_banks
EXTERN _bc_video_bound_slots
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Select a prepared slot. Prepare checked the stack and fixed RAM mappings.
; The caller keeps code and stack resident while using these slots.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; on first use or a change of pins/format: validate the slot and set up the renderer;
; if (graphics_operation || window_lease) return ZX_BUSY;
; draw_surface.pages = slot.pages;
; for each window: publish CPU base; if bank differs, map it and update cache;
; return ZX_OK;
;
; SDCC fastcall L=slot, L=status. Preserve IX/IY, clobber AF/BC/DE/HL.
; Direct absolute loads bind the operands for the two fixed slots. They both
; use the same window-write sequence. AF on the stack saves the original BF.

; Install one window using its bound cache address. base holds the aligned
; CPU address for the renderer. bank is E or D from the prepared page pair.
        MACRO SELECT_PAGE window, cache_ptr, base, bank
        LOCAL mapped
        ld a,(window)
        ld (base+1),a
        or 037h
        ld b,a
        ld hl,(cache_ptr)
        ld a,bank
        cp (hl)
        jr z,mapped
        ld (hl),a
        cpl
        out (c),a
mapped:
        ENDM

        MACRO SELECT_SLOT slot, bit_number
        LOCAL ready, opened
        ld a,(_bc_video_bound_slots)
        bit bit_number,a
        jr nz,ready
        ld hl,slot
        call _bc__video_bind_draw_buffer
        ld a,l
        or a
        ret nz
ready:
        ld hl,(_bc_mem_active_window_lease)
        ld a,(_bc_video_operation_depth)
        or h
        or l
        jp nz,busy
        in a,(0bfh)
        push af
        bit 0,a
        jr nz,opened
        or 1
        out (0bfh),a
opened:
        ld de,(slot+BC_DRAW_PAGES)
        ld (_bc_video_draw_surface_state+1),de
        ld c,0f7h
        SELECT_PAGE slot,   _bc_video_slot_banks+4*bit_number,   _bc_video_page0_base, e
        SELECT_PAGE slot+1, _bc_video_slot_banks+4*bit_number+2, _bc_video_page1_base, d
        pop af
        jp finish
        ENDM

_zx_select_draw_buffer:
        ld a,l
        dec a
        jp z,slot1
        inc a
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nz
        SELECT_SLOT _bc_video_prepared_buffers, 0
slot1:
        SELECT_SLOT _bc_video_prepared_buffers+BC_DRAW_SLOT_SIZE, 1
busy:
        ld l,2                       ; ZX_BUSY
        ret

; Restore BF only when selection opened shadow I/O.
finish:
        bit 0,a
        ld l,0
        ret nz
        out (0bfh),a
        ret
