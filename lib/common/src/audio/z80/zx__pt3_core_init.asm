IF !__CPU_INTEL__ & !__CPU_GBZ80__ & !__CPU_RABBIT__ & !__CPU_Z180__
;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;ROM version (specially for Axor)
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

        MODULE zx__pt3_core_init
SECTION code_sound_ay
PUBLIC zx__pt3_core_init
EXTERN zx__pt3_state
DEFC PT3_ORIGIN = zx__pt3_state
INCLUDE "audio/z80/pt3.inc"
EXTERN zx__pt3_ay_out_from_a

; Initialize the player from the PT3 module at HL.
zx__pt3_core_init:
;HL - AddressOfModule

        LD (MODADDR),HL
        PUSH HL
        LD DE,100
        ADD HL,DE
        LD A,(HL)
        LD (Delay),A
        PUSH HL
        POP IX
        ADD HL,DE
        LD (CrPsPtr),HL
        LD E,(IX+102-100)
        ADD HL,DE
        INC HL
        LD (LPosPtr),HL
        POP DE
        LD L,(IX+103-100)
        LD H,(IX+104-100)
        ADD HL,DE
        LD (PatsPtr),HL
        LD HL,169
        ADD HL,DE
        LD (OrnPtrs),HL
        LD HL,105
        ADD HL,DE
        LD (SamPtrs),HL
        LD HL,SETUP
        RES 7,(HL)

;note table data depacker
        LD DE,T_PACK
        LD BC,T1_+(2*49)-1
TP_0:
        LD A,(DE)
        INC DE
        CP 15*2
        JR NC,TP_1
        LD H,A
        LD A,(DE)
        LD L,A
        INC DE
        JR TP_2
TP_1:
        PUSH DE
        LD D,0
        LD E,A
        ADD HL,DE
        ADD HL,DE
        POP DE
TP_2:
        LD A,H
        LD (BC),A
        DEC BC
        LD A,L
        LD (BC),A
        DEC BC
        SUB +($F8*2) % 256
        JR NZ,TP_0

        LD HL,VAR0START
        LD (HL),A
        LD DE,VAR0START+1
        LD BC,VAR0END-VAR0START-1
        LDIR
        INC A
        LD (DelyCnt),A
        LD HL,$F001 ;H - CHP_Volume, L - CHP_NtSkCn
        LD (ChanA+CHP_NtSkCn),HL
        LD (ChanB+CHP_NtSkCn),HL
        LD (ChanC+CHP_NtSkCn),HL

        LD HL,EMPTYSAMORN
        LD (AdInPtA),HL ;ptr to zero
        LD (ChanA+CHP_OrnPtr),HL ;ornament 0 is "0,1,0"
        LD (ChanB+CHP_OrnPtr),HL ;in all versions from
        LD (ChanC+CHP_OrnPtr),HL ;3.xx to 3.6x and VTII

        LD (ChanA+CHP_SamPtr),HL ;S1 There is no default
        LD (ChanB+CHP_SamPtr),HL ;S2 sample in PT3, so, you
        LD (ChanC+CHP_SamPtr),HL ;S3 can comment S1,2,3; see
				    ;also EMPTYSAMORN comment

        LD A,(IX+13-100) ;EXTRACT VERSION NUMBER
        SUB $30
        JR C,L20
        CP 10
        JR C,L21
L20:
        LD A,6
L21:
        LD (Version),A
        PUSH AF
        CP 4
        LD A,(IX+99-100) ;TONE TABLE NUMBER
        RLA
        AND 7

;NoteTableCreator (c) Ivan Roshin
;A - NoteTableNumber*2+VersionForNoteTable
;(xx1b - 3.xx..3.4r, xx0b - 3.4x..3.6x..VTII1.0)

        LD HL,NT_DATA
        PUSH DE
        LD D,B
        ADD A,A
        LD E,A
        ADD HL,DE
        LD E,(HL)
        INC HL
        SRL E
        SBC A,A
        AND $A7 ;$00 (NOP) or $A7 (AND A)
        LD (L3),A
        LD A,201 ;RET temporary
        LD (L3+1),A ;temporary
        EX DE,HL
        POP BC ;BC=T1_
        ADD HL,BC

        LD A,(DE)

        ADD A,+(T_ % 256)
        LD C,A
        ADC A,T_/256

        SUB C
        LD B,A
        PUSH BC
        LD DE,NT_
        PUSH DE

        LD B,12
L1:
        PUSH BC
        LD C,(HL)
        INC HL
        PUSH HL
        LD B,(HL)

        PUSH DE
        EX DE,HL
        LD DE,23
        LD IXH,8

L2:
        SRL B
        RR C
        CALL L3 ;temporary
;L3:
;	DB $19	;AND A or NOP
        LD A,C
        ADC A,D	;=ADC 0
        LD (HL),A
        INC HL
        LD A,B
        ADC A,D
        LD (HL),A
        ADD HL,DE
        DEC IXH
        JR NZ,L2

        POP DE
        INC DE
        INC DE
        POP HL
        INC HL
        POP BC
        DJNZ L1

        POP HL
        POP DE

        LD A,E
        CP +(TCOLD_1) % 256
        JR NZ,CORR_1
        LD A,$FD
        LD (NT_+$2E),A

CORR_1:
        LD A,(DE)
        AND A
        JR Z,TC_EXIT
        RRA
        PUSH AF
        ADD A,A
        LD C,A
        ADD HL,BC
        POP AF
        JR NC,CORR_2
        DEC (HL)
        DEC (HL)
CORR_2:
        INC (HL)
        AND A
        SBC HL,BC
        INC DE
        JR CORR_1

TC_EXIT:

        POP AF

;VolTableCreator (c) Ivan Roshin
;A - VersionForVolumeTable (0..4 - 3.xx..3.4x;
			   ;5.. - 3.5x..3.6x..VTII1.0)

        CP 5
        LD HL,$11
        LD D,H
        LD E,H
        LD A,$17
        JR NC,M1
        DEC L
        LD E,L
        XOR A
M1:
        LD (M2),A

        LD IX,VT_+16
        LD C,$10

INITV2:
        PUSH HL

        ADD HL,DE
        EX DE,HL
        SBC HL,HL

INITV1:
        LD A,L
;M2:
;	DB $7D
        CALL M2 ;temporary
        LD A,H
        ADC A,0
        LD (IX),A
        INC IX
        ADD HL,DE
        INC C
        LD A,C
        AND 15
        JR NZ,INITV1

        POP HL
        LD A,E
        CP $77
        JR NZ,M3
        INC E
M3:
        LD A,C
        AND A
        JR NZ,INITV2

        JP zx__pt3_ay_out_from_a

NT_DATA:
        DEFB (T_NEW_0-T1_)*2
        DEFB TCNEW_0-T_
        DEFB (T_OLD_0-T1_)*2+1
        DEFB TCOLD_0-T_
        DEFB (T_NEW_1-T1_)*2+1
        DEFB TCNEW_1-T_
        DEFB (T_OLD_1-T1_)*2+1
        DEFB TCOLD_1-T_
        DEFB (T_NEW_2-T1_)*2
        DEFB TCNEW_2-T_
        DEFB (T_OLD_2-T1_)*2
        DEFB TCOLD_2-T_
        DEFB (T_NEW_3-T1_)*2
        DEFB TCNEW_3-T_
        DEFB (T_OLD_3-T1_)*2
        DEFB TCOLD_3-T_

T_:

TCOLD_0:
        DEFB $00+1,$04+1,$08+1,$0A+1,$0C+1,$0E+1,$12+1,$14+1
        DEFB $18+1,$24+1,$3C+1,0
TCOLD_1:
        DEFB $5C+1,0
TCOLD_2:
        DEFB $30+1,$36+1,$4C+1,$52+1,$5E+1,$70+1,$82,$8C,$9C
        DEFB $9E,$A0,$A6,$A8,$AA,$AC,$AE,$AE,0
TCNEW_3:
        DEFB $56+1
TCOLD_3:
        DEFB $1E+1,$22+1,$24+1,$28+1,$2C+1,$2E+1,$32+1,$BE+1,0
TCNEW_0:
        DEFB $1C+1,$20+1,$22+1,$26+1,$2A+1,$2C+1,$30+1,$54+1
        DEFB $BC+1,$BE+1,0
DEFC TCNEW_1 = TCOLD_1
TCNEW_2:
        DEFB $1A+1,$20+1,$24+1,$28+1,$2A+1,$3A+1,$4C+1,$5E+1
        DEFB $BA+1,$BC+1,$BE+1,0

DEFC EMPTYSAMORN = ASMPC-1
        DEFB 1,0,$90 ;delete $90 if you don't need default sample

;first 12 values of tone tables (packed)

T_PACK:
        DEFB ($06EC*2/256) % 256,($06EC*2) % 256
        DEFB $0755-$06EC
        DEFB $07C5-$0755
        DEFB $083B-$07C5
        DEFB $08B8-$083B
        DEFB $093D-$08B8
        DEFB $09CA-$093D
        DEFB $0A5F-$09CA
        DEFB $0AFC-$0A5F
        DEFB $0BA4-$0AFC
        DEFB $0C55-$0BA4
        DEFB $0D10-$0C55
        DEFB ($066D*2/256) % 256, ($066D*2) % 256
        DEFB $06CF-$066D
        DEFB $0737-$06CF
        DEFB $07A4-$0737
        DEFB $0819-$07A4
        DEFB $0894-$0819
        DEFB $0917-$0894
        DEFB $09A1-$0917
        DEFB $0A33-$09A1
        DEFB $0ACF-$0A33
        DEFB $0B73-$0ACF
        DEFB $0C22-$0B73
        DEFB $0CDA-$0C22
        DEFB ($0704*2/256) % 256, ($0704*2) % 256
        DEFB $076E-$0704
        DEFB $07E0-$076E
        DEFB $0858-$07E0
        DEFB $08D6-$0858
        DEFB $095C-$08D6
        DEFB $09EC-$095C
        DEFB $0A82-$09EC
        DEFB $0B22-$0A82
        DEFB $0BCC-$0B22
        DEFB $0C80-$0BCC
        DEFB $0D3E-$0C80
        DEFB ($07E0*2/256) % 256,($07E0*2) % 256
        DEFB $0858-$07E0
        DEFB $08E0-$0858
        DEFB $0960-$08E0
        DEFB $09F0-$0960
        DEFB $0A88-$09F0
        DEFB $0B28-$0A88
        DEFB $0BD8-$0B28
        DEFB $0C80-$0BD8
        DEFB $0D60-$0C80
        DEFB $0E10-$0D60
        DEFB $0EF8-$0E10

; Player identification.
        DEFM "=VTII PT3 Player r.7ROM="

;This file has been adapted to the z80asm assembler in z88dk and is based on the
;file PT3Play/ROM/PT3PROM.asm in http://bulba.untergrund.net/PTxTools.7z, which
;uses the SjASM assembler syntax. The code section can be executed from RAM or
;ROM, contains no self-modifying code, and can be assembled at any address.
;The data section contains the variables and self-modifying code and can be
;located at any address in RAM. The MUTE routine has been extended to also
;disable all channels.

;Features
;--------
;-Can run in ROM (self-modified code is not used).
;-Can be compiled at any address (i.e. no need rounding ORG
; address).
;-Variables (VARS) can be located at any address (not only after
;code block).
;-INIT subroutine detects module version and rightly generates
; both note and volume tables outside of code block (in VARS).
;-Two portamento (spc. command 3xxx) algorithms (depending of
; module version).
;-New 1.XX and 2.XX special command behaviour (only for PT v3.7
; and higher).
;-Any Tempo value are accepted (including Tempo=1 and Tempo=2).
;-Fully compatible with Ay_Emul PT3 player codes.
;-See also notes at the end of this source code.

;Warning!!! PLAY subroutine can crash if no module are loaded
;into RAM or INIT subroutine was not called before.

;Call MUTE or INIT one more time to mute sound after stopping
;playing

;Release 0 steps:
;11.Sep.2004 - Note tables creator
;12.Sep.2004 - Volume tables creator; INIT subroutine
;13.Sep.2004 - Play counters, position counters
;14.Sep.2004 - Patterns decoder subroutine
;15.Sep.2004 - Resting (no code)
;16.Sep.2004 - CHREGS subroutine; global debugging; 1st stable
;version was born
;17.Sep.2004 - Debugging and optimization. First release!
;Release 1 steps:
;20.Sep.2004 - local vars moved to code (selfmodified code
;smaller and faster)
;22.Sep.2004 - added mute sound entry at START+8; position
;pointer moved to START+11; added setup and status byte at
;START+10 noloop mode and loop passed flags added
;Release 2 steps:
;28.Sep.2004 - Optimization: code around CHREGS's volume and
;vibrato faster now; zeroing PD_RES through stack; Ton and Ampl
;moved from channel vars to global ones; first position selector
;removed from INIT; optimization for packers(Ivan Roshin method)
;Release 3 steps:
;2.Oct.2004 - optimization in INIT and PD_LOOP (thanks to Ivan
;Roshin)
;4.Oct.2004 - load delay from (hl) in INIT (2 bytes shorter)
;5.Oct.2004 - optimization in PD_LOOP (->PD_LP2)
;7.Oct.2004 - swaping some commands for better packing
;Release 4 steps:
;9.Oct.2004 - optimization around LD HL,SPCCOMS (thanks to Ivan
;Roshin); in PTDECOD swapped BC and DE to optimize C_PORTM;
;removed sam and orn len and loop channel vars; CHREGS totally
;optimized
;Release 5 steps:
;11.Oct.2004 - PD_OrSm and C_PORTM optimized; Ivan Roshin's
;volume tables creator algorithm (51 bytes shorter than mine)
;12.Oct.2004 - Ivan Roshin's note tables creator algorithm (74
;bytes shorter than mine)
;Release 6 steps:
;14.Oct.2004 - loop and next position calculations moved to INIT
;15.Oct.2004 - AdInPt moved to code
;19.Oct.2004 - Env_Del moved to code
;20.Oct.2004 - Version PUSH and POP (1 byte shorter, thanks to
;Ivan Roshin)
;22.Oct.2004 - Env_En moved from Flags' bit to byte (shorter and
;faster code)
;25.Oct.2004 - SETENV optimized
;29.Oct.2004 - Optimized around AddToEn (SBC A,A, thanks to Ivan
;Roshin)
;3.Nov.2004 - Note tables data was compressed; with depacker it
;is 9 bytes shorter than uncompressed (thanks to Ivan Roshin)
;4.Nov.2004 - default sample and ornament both are fixed now
;and placed into code block (6 bytes shorter)
;7.Nov.2004 - LD A,(Ns_Base):LD L,A changed to LD HL,(Ns_Base)
;(thanks to Dima Bystrov)
;9.Nov.2004 - Ns_Base and AddToNs are merged to Ns_Base_AddToNs;
;LD A,255 changed to DEC A (at start of PLAY); added ROUT_A0
;12.Nov.2004 - NtSkCn&Volume are merged (8 bytes smaller init);
;LD BC,T1_ changed to PUSH DE...POP BC in note table creator
;19.Dec.2004 - NT_DATA reorganized (6 bytes shorter, thanks to
;Ivan Roshin); C_PORTM and C_GLISS are merged via SET_STP (48
;tacts slower, but 8 bytes smaller, thanks to Ivan Roshin)
;15.Apr.2007 - all in-code variables and self-modified code
;moved to VARS (specially for Axor), code can run in ROM now.
;29.Apr.2007 - new 1.xx and 2.xx interpretation for PT 3.7+.

;Size:
;Code block $664 bytes
;Variables $23B bytes (can be stripped)
;Size in RAM $664+$23B=$89F (2207) bytes

;Notes:
;Pro Tracker 3.4r can not be detected by header, so PT3.4r tone
;tables really used only for modules of 3.3 and older versions.
ENDIF
