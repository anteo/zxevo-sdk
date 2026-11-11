        MODULE bc__video_write_memory

SECTION code_clib
PUBLIC bc__video_write_memory_regs
EXTERN bc__video_memory_address

; Register ABI for ASM callers: A = page, DE = offset, C = value.
; Preserve C/DE/IX/IY, including when the page is unavailable.
;
; Writes one byte through the register-based video memory entry when the
; selected page is mapped.
;
; Model:
;
; if (!address(page,offset).unavailable) *address=value;
;
; Register contract above. Existing active operation and known page are
; checked centrally; no page map or bounds check is added. AF/B/HL volatile,
; C/DE/IX/IY preserved; invalid writes have no memory side effect.
bc__video_write_memory_regs:
        call bc__video_memory_address
        ret c
        ld (hl),c
        ret
