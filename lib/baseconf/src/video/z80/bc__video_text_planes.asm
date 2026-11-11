        MODULE bc__video_text_planes
INCLUDE "video/text_rows.inc"
SECTION code_clib
PUBLIC bc__video_text_character_planes
PUBLIC bc__video_text_attribute_planes
EXTERN bc__video_map_page_regs
EXTERN _bc_video_cpu_base

; Resolve a text plane pair in the surface supplied by the caller. Model:
;
; if (characters)
;     page, even, odd = atm ? (page1, 0x01c0, 0x21c0) : (page0, 0x01c0, 0x11c0);
; else
;     page, even, odd = atm ? (page0, 0x21c0, 0x01c1) : (page0, 0x31c0, 0x21c1);
; if (select_page(page) != ZX_OK) return failure;
; return cpu_base + even, cpu_base + odd;
;
; IX addresses text_rows.inc arguments, with an active prepared lease.
; Return HL/DE = even/odd origins on Z. NZ indicates a selection failure.
; Preserve IX/IY, clobber AF/BC/DE/HL. One saved word keeps the even offset
; across the page selector. The odd attribute byte starts one byte later.
bc__video_text_character_planes:
        ld c,(ix+BC_TEXT_ROWS_PAGE0)
        ld a,(ix+BC_TEXT_ROWS_MODE)
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        ld de,11C0h
        jr nz,@characters
        ld c,(ix+BC_TEXT_ROWS_PAGE1)
        ld d,21h
@characters:
        ld hl,01C0h
        jr bc_video_text_planes_select

bc__video_text_attribute_planes:
        ld c,(ix+BC_TEXT_ROWS_PAGE0)
        ld a,(ix+BC_TEXT_ROWS_MODE)
        cp 5
        ld hl,31C0h
        ld de,21C1h
        jr nz,bc_video_text_planes_select
        ld hl,21C0h
        ld de,01C1h
bc_video_text_planes_select:
        push hl
        call bc__video_map_page_regs
        pop hl
        ret nz
        ld bc,(_bc_video_cpu_base)
        add hl,bc                    ; 16-bit ADD preserves the selector's Z
        ex de,hl
        add hl,bc
        ex de,hl
        ret
