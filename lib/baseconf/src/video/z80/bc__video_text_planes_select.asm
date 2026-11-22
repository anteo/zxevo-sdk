        MODULE bc__video_text_planes_select
EXTERN _bc_video_cpu_base
EXTERN bc__video_map_page_regs
SECTION code_clib
PUBLIC bc__video_text_planes_select
bc__video_text_planes_select:
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
