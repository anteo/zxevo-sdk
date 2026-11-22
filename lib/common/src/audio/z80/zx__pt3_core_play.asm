IF !__CPU_INTEL__ & !__CPU_GBZ80__ & !__CPU_RABBIT__ & !__CPU_Z180__
;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;ROM version (specially for Axor)
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

        MODULE zx__pt3_core_play
SECTION code_sound_ay
PUBLIC zx__pt3_core_play
EXTERN zx__pt3_state
DEFC PT3_ORIGIN = zx__pt3_state
INCLUDE "audio/z80/pt3.inc"
EXTERN zx__pt3_ay_out
EXTERN zx__pt3_ay_out_from_a
EXTERN zx__pt3_core_mute

; Advance the initialized player by one tick and update the AY registers.
CHECKLP:
        LD HL,SETUP
        SET 7,(HL)
        BIT 0,(HL)
        RET Z
        POP HL
        LD HL,DelyCnt
        INC (HL)
        LD HL,ChanA+CHP_NtSkCn
        INC (HL)
        JP zx__pt3_core_mute

; Pattern decoder
PD_OrSm:
        LD (IX-12+CHP_Env_En),0
        CALL SETORN
        LD A,(BC)
        INC BC
        RRCA

PD_SAM:
        ADD A,A
PD_SAM_:
        LD E,A
        LD D,0
;DEFC SamPtrs = ASMPC+1
;	LD HL,$2121
        LD HL,(SamPtrs)
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
;DEFC MODADDR = ASMPC+1
;	LD HL,$2121
        LD HL,(MODADDR)
        ADD HL,DE
        LD (IX-12+CHP_SamPtr),L
        LD (IX-12+CHP_SamPtr+1),H
        JR PD_LOOP

PD_VOL:
        RLCA
        RLCA
        RLCA
        RLCA
        LD (IX-12+CHP_Volume),A
        JR PD_LP2

PD_EOff:
        LD (IX-12+CHP_Env_En),A
        LD (IX-12+CHP_PsInOr),A
        JR PD_LP2

PD_SorE:
        DEC A
        JR NZ,PD_ENV
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_NNtSkp),A
        JR PD_LP2

PD_ENV:
        CALL SETENV
        JR PD_LP2

PD_ORN:
        CALL SETORN
        JR PD_LOOP

PD_ESAM:
        LD (IX-12+CHP_Env_En),A
        LD (IX-12+CHP_PsInOr),A
        CALL NZ,SETENV
        LD A,(BC)
        INC BC
        JR PD_SAM_

PTDECOD:
        LD A,(IX-12+CHP_Note)
;	LD (PrNote+1),A
        LD (PrNote),A
        LD L,(IX-12+CHP_CrTnSl)
        LD H,(IX-12+CHP_CrTnSl+1)
;	LD (PrSlide+1),HL
        LD (PrSlide),HL

PD_LOOP:
        LD DE,$2010
PD_LP2:
        LD A,(BC)
        INC BC
        ADD A,E
        JR C,PD_OrSm
        ADD A,D
        JR Z,PD_FIN
        JR C,PD_SAM
        ADD A,E
        JR Z,PD_REL
        JR C,PD_VOL
        ADD A,E
        JR Z,PD_EOff
        JR C,PD_SorE
        ADD A,96
        JR C,PD_NOTE
        ADD A,E
        JR C,PD_ORN
        ADD A,D
        JR C,PD_NOIS
        ADD A,E
        JR C,PD_ESAM
        ADD A,A
        LD E,A
        LD HL,SPCCOMS+$FF20-$2000
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        PUSH DE
        JR PD_LOOP

PD_NOIS:
        LD (Ns_Base),A
        JR PD_LP2

PD_REL:
        RES 0,(IX-12+CHP_Flags)
        JR PD_RES

PD_NOTE:
        LD (IX-12+CHP_Note),A
        SET 0,(IX-12+CHP_Flags)
        XOR A

PD_RES:
;	LD (PDSP_+1),SP
        LD (PDSP_),SP
        LD SP,IX
        LD H,A
        LD L,A
        PUSH HL
        PUSH HL
        PUSH HL
        PUSH HL
        PUSH HL
        PUSH HL
;PDSP_:
;	LD SP,$3131
        LD SP,(PDSP_)

PD_FIN:
        LD A,(IX-12+CHP_NNtSkp)
        LD (IX-12+CHP_NtSkCn),A
        RET

C_PORTM:
        RES 2,(IX-12+CHP_Flags)
        LD A,(BC)
        INC BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
        INC BC
        INC BC
        LD (IX-12+CHP_TnSlDl),A
        LD (IX-12+CHP_TSlCnt),A
        LD DE,NT_
        LD A,(IX-12+CHP_Note)
        LD (IX-12+CHP_SlToNt),A
        ADD A,A
        LD L,A
        LD H,0
        ADD HL,DE
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        PUSH HL
;PrNote:
;	LD A,$3E
        LD A,(PrNote)
        LD (IX-12+CHP_Note),A
        ADD A,A
        LD L,A
        LD H,0
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        POP HL
        SBC HL,DE
        LD (IX-12+CHP_TnDelt),L
        LD (IX-12+CHP_TnDelt+1),H
        LD E,(IX-12+CHP_CrTnSl)
        LD D,(IX-12+CHP_CrTnSl+1)
;DEFC Version = ASMPC+1
;	LD A,$3E
        LD A,(Version)
        CP 6
        JR C,OLDPRTM ;Old 3xxx for PT v3.5-
;PrSlide:
;	LD DE,$1111
        LD DE,(PrSlide)
        LD (IX-12+CHP_CrTnSl),E
        LD (IX-12+CHP_CrTnSl+1),D
OLDPRTM:
        LD A,(BC) ;SIGNED TONE STEP
        INC BC
        EX AF,AF'
        LD A,(BC)
        INC BC
        AND A
        JR Z,NOSIG
        EX DE,HL
NOSIG:
        SBC HL,DE
        JP P,SET_STP
        CPL
        EX AF,AF'
        NEG
        EX AF,AF'
SET_STP:
        LD (IX-12+CHP_TSlStp+1),A
        EX AF,AF'
        LD (IX-12+CHP_TSlStp),A
        LD (IX-12+CHP_COnOff),0
        RET

C_GLISS:
        SET 2,(IX-12+CHP_Flags)
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_TnSlDl),A
        AND A
        JR NZ,GL36
        LD A,(Version) ;AlCo PT3.7+
        CP 7
        SBC A,A
        INC A
GL36:
        LD (IX-12+CHP_TSlCnt),A
        LD A,(BC)
        INC BC
        EX AF,AF'
        LD A,(BC)
        INC BC
        JR SET_STP

C_SMPOS:
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_PsInSm),A
        RET

C_ORPOS:
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_PsInOr),A
        RET

C_VIBRT:
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_OnOffD),A
        LD (IX-12+CHP_COnOff),A
        LD A,(BC)
        INC BC
        LD (IX-12+CHP_OffOnD),A
        XOR A
        LD (IX-12+CHP_TSlCnt),A
        LD (IX-12+CHP_CrTnSl),A
        LD (IX-12+CHP_CrTnSl+1),A
        RET

C_ENGLS:
        LD A,(BC)
        INC BC
        LD (Env_Del),A
        LD (CurEDel),A
        LD A,(BC)
        INC BC
        LD L,A
        LD A,(BC)
        INC BC
        LD H,A
        LD (ESldAdd),HL
        RET

C_DELAY:
        LD A,(BC)
        INC BC
        LD (Delay),A
        RET

SETENV:
        LD (IX-12+CHP_Env_En),E
        LD (AYREGS+EnvTp),A
        LD A,(BC)
        INC BC
        LD H,A
        LD A,(BC)
        INC BC
        LD L,A
        LD (EnvBase),HL
        XOR A
        LD (IX-12+CHP_PsInOr),A
        LD (CurEDel),A
        LD H,A
        LD L,A
        LD (CurESld),HL
C_NOP:
        RET

SETORN:
        ADD A,A
        LD E,A
        LD D,0
        LD (IX-12+CHP_PsInOr),D
;DEFC OrnPtrs = ASMPC+1
;	LD HL,$2121
        LD HL,(OrnPtrs)
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
;DEFC MDADDR2 = ASMPC+1
;	LD HL,$2121
        LD HL,(MODADDR)
        ADD HL,DE
        LD (IX-12+CHP_OrnPtr),L
        LD (IX-12+CHP_OrnPtr+1),H
        RET

;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS:
        DEFW C_NOP
        DEFW C_GLISS
        DEFW C_PORTM
        DEFW C_SMPOS
        DEFW C_ORPOS
        DEFW C_VIBRT
        DEFW C_NOP
        DEFW C_NOP
        DEFW C_ENGLS
        DEFW C_DELAY
        DEFW C_NOP
        DEFW C_NOP
        DEFW C_NOP
        DEFW C_NOP
        DEFW C_NOP
        DEFW C_NOP

CHREGS:
        XOR A
        LD (Ampl),A
        BIT 0,(IX+CHP_Flags)
        PUSH HL
        JP Z,CH_EXIT
;	LD (CSP_+1),SP
        LD (CSP_),SP
        LD L,(IX+CHP_OrnPtr)
        LD H,(IX+CHP_OrnPtr+1)
        LD SP,HL
        POP DE
        LD H,A
        LD A,(IX+CHP_PsInOr)
        LD L,A
        ADD HL,SP
        INC A
        CP D
        JR C,CH_ORPS
        LD A,E
CH_ORPS:
        LD (IX+CHP_PsInOr),A
        LD A,(IX+CHP_Note)
        ADD A,(HL)
        JP P,CH_NTP
        XOR A
CH_NTP:
        CP 96
        JR C,CH_NOK
        LD A,95
CH_NOK:
        ADD A,A
        EX AF,AF'
        LD L,(IX+CHP_SamPtr)
        LD H,(IX+CHP_SamPtr+1)
        LD SP,HL
        POP DE
        LD H,0
        LD A,(IX+CHP_PsInSm)
        LD B,A
        ADD A,A
        ADD A,A
        LD L,A
        ADD HL,SP
        LD SP,HL
        LD A,B
        INC A
        CP D
        JR C,CH_SMPS
        LD A,E
CH_SMPS:
        LD (IX+CHP_PsInSm),A
        POP BC
        POP HL
        LD E,(IX+CHP_TnAcc)
        LD D,(IX+CHP_TnAcc+1)
        ADD HL,DE
        BIT 6,B
        JR Z,CH_NOAC
        LD (IX+CHP_TnAcc),L
        LD (IX+CHP_TnAcc+1),H
CH_NOAC:
        EX DE,HL
        EX AF,AF'
        LD L,A
        LD H,0
        LD SP,NT_
        ADD HL,SP
        LD SP,HL
        POP HL
        ADD HL,DE
        LD E,(IX+CHP_CrTnSl)
        LD D,(IX+CHP_CrTnSl+1)
        ADD HL,DE
;CSP_:
;	LD SP,$3131
        LD SP,(CSP_)
        EX (SP),HL
        XOR A
        OR (IX+CHP_TSlCnt)
        JR Z,CH_AMP
        DEC (IX+CHP_TSlCnt)
        JR NZ,CH_AMP
        LD A,(IX+CHP_TnSlDl)
        LD (IX+CHP_TSlCnt),A
        LD L,(IX+CHP_TSlStp)
        LD H,(IX+CHP_TSlStp+1)
        LD A,H
        ADD HL,DE
        LD (IX+CHP_CrTnSl),L
        LD (IX+CHP_CrTnSl+1),H
        BIT 2,(IX+CHP_Flags)
        JR NZ,CH_AMP
        LD E,(IX+CHP_TnDelt)
        LD D,(IX+CHP_TnDelt+1)
        AND A
        JR Z,CH_STPP
        EX DE,HL
CH_STPP:
        SBC HL,DE
        JP M,CH_AMP
        LD A,(IX+CHP_SlToNt)
        LD (IX+CHP_Note),A
        XOR A
        LD (IX+CHP_TSlCnt),A
        LD (IX+CHP_CrTnSl),A
        LD (IX+CHP_CrTnSl+1),A
CH_AMP:
        LD A,(IX+CHP_CrAmSl)
        BIT 7,C
        JR Z,CH_NOAM
        BIT 6,C
        JR Z,CH_AMIN
        CP 15
        JR Z,CH_NOAM
        INC A
        JR CH_SVAM
CH_AMIN:
        CP -15
        JR Z,CH_NOAM
        DEC A
CH_SVAM:
        LD (IX+CHP_CrAmSl),A
CH_NOAM:
        LD L,A
        LD A,B
        AND 15
        ADD A,L
        JP P,CH_APOS
        XOR A
CH_APOS:
        CP 16
        JR C,CH_VOL
        LD A,15
CH_VOL:
        OR (IX+CHP_Volume)
        LD L,A
        LD H,0
        LD DE,VT_
        ADD HL,DE
        LD A,(HL)
CH_ENV:
        BIT 0,C
        JR NZ,CH_NOEN
        OR (IX+CHP_Env_En)
CH_NOEN:
        LD (Ampl),A
        BIT 7,B
        LD A,C
        JR Z,NO_ENSL
        RLA
        RLA
        SRA A
        SRA A
        SRA A
        ADD A,(IX+CHP_CrEnSl) ;SEE COMMENT BELOW
        BIT 5,B
        JR Z,NO_ENAC
        LD (IX+CHP_CrEnSl),A
NO_ENAC:
        LD HL,AddToEn
        ADD A,(HL) ;BUG IN PT3 - NEED WORD HERE.
		   ;FIX IT IN NEXT VERSION?
        LD (HL),A
        JR CH_MIX
NO_ENSL:
        RRA
        ADD A,(IX+CHP_CrNsSl)
        LD (AddToNs),A
        BIT 5,B
        JR Z,CH_MIX
        LD (IX+CHP_CrNsSl),A
CH_MIX:
        LD A,B
        RRA
        AND $48
CH_EXIT:
        LD HL,AYREGS+Mixer
        OR (HL)
        RRCA
        LD (HL),A
        POP HL
        XOR A
        OR (IX+CHP_COnOff)
        RET Z
        DEC (IX+CHP_COnOff)
        RET NZ
        XOR (IX+CHP_Flags)
        LD (IX+CHP_Flags),A
        RRA
        LD A,(IX+CHP_OnOffD)
        JR C,CH_ONDL
        LD A,(IX+CHP_OffOnD)
CH_ONDL:
        LD (IX+CHP_COnOff),A
        RET

zx__pt3_core_play:
        XOR A
        LD (AddToEn),A
        LD (AYREGS+Mixer),A
        DEC A
        LD (AYREGS+EnvTp),A
        LD HL,DelyCnt
        DEC (HL)
        JP NZ,PL2
        LD HL,ChanA+CHP_NtSkCn
        DEC (HL)
        JR NZ,PL1B
;DEFC AdInPtA = ASMPC+1
;	LD BC,$0101
        LD BC,(AdInPtA)
        LD A,(BC)
        AND A
        JR NZ,PL1A
        LD D,A
        LD (Ns_Base),A
        LD HL,(CrPsPtr)
        INC HL
        LD A,(HL)
        INC A
        JR NZ,PLNLP
        CALL CHECKLP
;DEFC LPosPtr = ASMPC+1
;	LD HL,$2121
        LD HL,(LPosPtr)
        LD A,(HL)
        INC A
PLNLP:
        LD (CrPsPtr),HL
        DEC A
        ADD A,A
        LD E,A
        RL D
;DEFC PatsPtr = ASMPC+1
;	LD HL,$2121
        LD HL,(PatsPtr)
        ADD HL,DE
        LD DE,(MODADDR)
;	LD (PSP_+1),SP
        LD (PSP_),SP
        LD SP,HL
        POP HL
        ADD HL,DE
        LD B,H
        LD C,L
        POP HL
        ADD HL,DE
        LD (AdInPtB),HL
        POP HL
        ADD HL,DE
        LD (AdInPtC),HL
;PSP_:
;	LD SP,$3131
        LD SP,(PSP_)
PL1A:
        LD IX,ChanA+12
        CALL PTDECOD
        LD (AdInPtA),BC

PL1B:
        LD HL,ChanB+CHP_NtSkCn
        DEC (HL)
        JR NZ,PL1C
        LD IX,ChanB+12
;DEFC AdInPtB = ASMPC+1
;	LD BC,$0101
        LD BC,(AdInPtB)
        CALL PTDECOD
        LD (AdInPtB),BC

PL1C:
        LD HL,ChanC+CHP_NtSkCn
        DEC (HL)
        JR NZ,PL1D
        LD IX,ChanC+12
;DEFC AdInPtC = ASMPC+1
;	LD BC,$0101
        LD BC,(AdInPtC)
        CALL PTDECOD
        LD (AdInPtC),BC

;DEFC Delay = ASMPC+1
PL1D:
;	LD A,$3E
        LD A,(Delay)
        LD (DelyCnt),A

PL2:
        LD IX,ChanA
        LD HL,(AYREGS+TonA)
        CALL CHREGS
        LD (AYREGS+TonA),HL
        LD A,(Ampl)
        LD (AYREGS+AmplA),A
        LD IX,ChanB
        LD HL,(AYREGS+TonB)
        CALL CHREGS
        LD (AYREGS+TonB),HL
        LD A,(Ampl)
        LD (AYREGS+AmplB),A
        LD IX,ChanC
        LD HL,(AYREGS+TonC)
        CALL CHREGS
;	LD A,(Ampl) ;Ampl = AYREGS+AmplC
;	LD (AYREGS+AmplC),A
        LD (AYREGS+TonC),HL

        LD HL,(Ns_Base_AddToNs)
        LD A,H
        ADD A,L
        LD (AYREGS+Noise),A

;DEFC AddToEn = ASMPC+1
;	LD A,$3E
        LD A,(AddToEn)
        LD E,A
        ADD A,A
        SBC A,A
        LD D,A
        LD HL,(EnvBase)
        ADD HL,DE
        LD DE,(CurESld)
        ADD HL,DE
        LD (AYREGS+Env),HL

        XOR A
        LD HL,CurEDel
        OR (HL)
        JP Z,zx__pt3_ay_out_from_a
        DEC (HL)
        JP NZ,zx__pt3_ay_out
;DEFC Env_Del = ASMPC+1
;	LD A,$3E
        LD A,(Env_Del)
        LD (HL),A
;DEFC ESldAdd = ASMPC+1
;	LD HL,$2121
        LD HL,(ESldAdd)
        ADD HL,DE
        LD (CurESld),HL
        JP zx__pt3_ay_out
ENDIF
