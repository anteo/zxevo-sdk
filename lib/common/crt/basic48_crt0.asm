        MODULE zx_basic48_crt0

defc crt0 = 1
INCLUDE "zcc_opt.def"
INCLUDE "crt_stdio.inc"
INCLUDE "crt_zx_lifecycle.inc"

EXTERN _main
PUBLIC __Exit
PUBLIC l_dcal

IFNDEF CRT_USE_ROM_FONT
defc CRT_USE_ROM_FONT = 1
ENDIF
IF CRT_USE_ROM_FONT
; BASIC 48 maps the ASCII 32..127 glyphs in ROM at 3D00h.
PUBLIC zx__font8_data
defc zx__font8_data = 3d00h
ENDIF

IFNDEF CRT_ORG_CODE
defc CRT_ORG_CODE = 8000h
ENDIF
defc __crt_model = 0
defc __CPU_CLOCK = 3500000
defc TAR__register_sp = -1
INCLUDE "crt/classic/crt_rules.inc"

        org CRT_ORG_CODE

; Enter C from BASIC 48 USR and return the program result to the ROM.
;
; save_basic_registers_and_sp();
; crt0_init();
; init_atexit();
; result = zx_init();
; if (result == OK) result = main();
; else print_init_error(result);
; crt0_exit();
; status = zx_shutdown();
; if (result == 0) result = status;
; return_to_basic(result);
;
; Entry is in writable RAM. USR supplies a return address on the BASIC
; stack. Keep the BASIC ROM, workspace and saved stack mapped on return.
; C uses the incoming SP. Saved IX and IY are below the BASIC return address.
; The saved SP points at the saved IX word, above any CRT and C stack use.
; BASIC receives BC = result, HL' = 2758h, its IX, IY and original stack.
start:
        push iy
        push ix
        ld (restore_sp+1),sp
        call crt0_init
INCLUDE "crt/classic/crt_init_atexit.inc"
        ZX_CRT_INIT zx_crt_init_failed
        call _main

__Exit:
        ZX_CRT_CLEANUP
        ; Restore BASIC's alternate HL as in the Spectrum CRT.
        exx
        ld hl,2758h
        exx
        ld b,h
        ld c,l
restore_sp:
        ld sp,0
        pop ix
        pop iy
        ret

l_dcal:
        jp (hl)

IF CRT_ENABLE_ZX_LIFECYCLE
; Report a failed SDK startup through the BASIC 48 ROM's upper screen.
;
; channel = current_channel;
; open_system_screen();
; rom_print("zx_init() failed (");
; rom_print_decimal(status);
; rom_print(")\r");
; restore_channel(channel);
; goto exit_with(status);
;
; HL = zero-extended status. Requires the BASIC ROM and workspace, with
; IY pointing to the BASIC system variables. Stack holds the saved channel
; pointer and status across ROM calls. HL is restored for the exit path.
zx_crt_init_failed:
        ld de,(5c51h)               ; CURCHL
        push de
        push hl
        ld a,0feh                   ; internal stream -2, upper screen
        call 1601h                  ; CHAN-OPEN
        ld hl,zx_crt_init_message
zx_crt_init_print:
        ld a,(hl)
        or a
        jr z,zx_crt_init_print_status
        inc hl
        rst 10h
        jr zx_crt_init_print
zx_crt_init_print_status:
        pop bc
        push bc
        call 1a1bh                  ; OUT-NUM-1 prints BC in decimal
        ld a,')'
        rst 10h
        ld a,13
        rst 10h
        pop hl
        ex (sp),hl                  ; recover channel pointer, save status
        call 1615h                  ; CHAN-FLAG restores the caller's channel
        pop hl
        jr __Exit

zx_crt_init_message:
        defm "zx_init() failed ("
        defb 0
ENDIF

        ZX_CRT_STDIO
INCLUDE "crt/classic/crt_runtime_selection.inc"
INCLUDE "crt/classic/crt_section.inc"
