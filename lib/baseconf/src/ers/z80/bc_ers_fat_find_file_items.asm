        MODULE bc_ers_fat_find_file_items

SECTION code_clib
PUBLIC _bc_ers_fat_find_file_items
EXTERN _bc_ers_profile

; Builds the ERS file list using the current filter and returns its count and
; physical RAM page.
;
; Model:
;
; if (!list) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x06); list->count = BC; list->ram_sortfiles_page = ~A; return OK;
;
; IX frame: list pointer +4; IX then addresses output {count:16,page:8}.
; The service preserves output IX and returns the inverted port byte in A.
; The wrapper converts it to a physical page number without mapping the page.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_find_file_items:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_fat_find_file_items_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_find_file_items_unavailable
        push hl
        pop ix
        rst 08h
        defb 51h,06h
        ld (ix+0),c
        ld (ix+1),b
        cpl
        ld (ix+2),a
        pop ix
        ld hl,0
        ret
bc_ers_fat_find_file_items_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_fat_find_file_items_unavailable:
        pop ix
        ld hl,3
        ret
