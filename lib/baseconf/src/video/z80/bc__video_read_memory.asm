        MODULE bc__video_read_memory

SECTION code_clib
PUBLIC bc__video_read_memory_regs
EXTERN bc__video_memory_address

; Register ABI: A = page, DE = offset, byte result in L.
;
; Reads a byte from the page and offset supplied in registers or returns zero
; if the page cannot be resolved.
;
; Model:
;
; if (address(page,offset).unavailable) return 0; return *address;
;
; Register contract above. Existing active operation and known page are
; checked centrally; no page map or bounds check is added. AF/B/HL volatile,
; C/DE/IX/IY preserved.
bc__video_read_memory_regs:
        call bc__video_memory_address
        jr nc,@read
        ld l,0
        ret
@read:
        ld l,(hl)
        ret
