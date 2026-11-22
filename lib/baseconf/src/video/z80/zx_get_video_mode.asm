        MODULE zx_get_video_mode
EXTERN bc__video_read_mode_regs
SECTION code_clib
PUBLIC _zx_get_video_mode

; Return the live FPGA video mode in HL.
defc _zx_get_video_mode = bc__video_read_mode_regs
