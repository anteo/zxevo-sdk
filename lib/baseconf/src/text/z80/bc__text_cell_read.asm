        MODULE bc__text_cell_read

SECTION code_clib
PUBLIC _bc__text_cell_read
EXTERN bc__text_cell_address
EXTERN bc__video_read_memory_regs

; SDCC caller-clean ABI: mode:8, surface:24, x:8, y:8. Return byte in L.
;
; Reads the character byte of one hardware text cell through the active video
; mapping.
;
; Model:
;
; (page,offset)=text_cell_address(mode,surface,x,y);
; return video_read_memory(page,offset);
;
; Caller holds a video lease and supplies in-range hardware-text coordinates.
; AF/BC/DE/HL volatile; IX/IY preserved. No copied surface or local scratch.
_bc__text_cell_read:
        push ix
        ld ix,0
        add ix,sp
        call bc__text_cell_address
        call bc__video_read_memory_regs
        pop ix
        ret
