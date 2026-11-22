;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;ROM version (specially for Axor)
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

DEFC TonA  = 0
DEFC TonB  = 2
DEFC TonC  = 4
DEFC Noise = 6
DEFC Mixer = 7
DEFC AmplA = 8
DEFC AmplB = 9
DEFC AmplC = 10
DEFC Env   = 11
DEFC EnvTp = 13

; PT3 channel record. The pattern decoder addresses fields with IX = channel + 12.
        DEFVARS 0 {
        CHP_PsInOr   ds.b 1
        CHP_PsInSm   ds.b 1
        CHP_CrAmSl   ds.b 1
        CHP_CrNsSl   ds.b 1
        CHP_CrEnSl   ds.b 1
        CHP_TSlCnt   ds.b 1
        CHP_CrTnSl   ds.w 1
        CHP_TnAcc    ds.w 1
        CHP_COnOff   ds.b 1
        CHP_OnOffD   ds.b 1
        CHP_OffOnD   ds.b 1
        CHP_OrnPtr   ds.w 1
        CHP_SamPtr   ds.w 1
        CHP_NNtSkp   ds.b 1
        CHP_Note     ds.b 1
        CHP_SlToNt   ds.b 1
        CHP_Env_En   ds.b 1
        CHP_Flags    ds.b 1    ; bit 0: enabled, bit 2: simple glissando
        CHP_TnSlDl   ds.b 1
        CHP_TSlStp   ds.w 1
        CHP_TnDelt   ds.w 1
        CHP_NtSkCn   ds.b 1
        CHP_Volume   ds.b 1
        CHP
        }

; The ROM player keeps channels, AY registers and generated tables in one RAM
; block. Several original fields intentionally overlap. L3/M2 and the saved
; stack pointers are scratch storage used by different stages of the player.
DEFC SETUP = PT3_ORIGIN
DEFC CrPsPtr = SETUP+1
DEFC AddToEn = CrPsPtr+2
DEFC AdInPtA = AddToEn+1
DEFC AdInPtB = AdInPtA+2
DEFC AdInPtC = AdInPtB+2
DEFC Env_Del = AdInPtC+2
DEFC MODADDR = Env_Del+1
DEFC ESldAdd = MODADDR+2
DEFC Delay = ESldAdd+2
DEFC PDSP_ = Delay+1
DEFC CSP_ = PDSP_
DEFC PSP_ = PDSP_
DEFC SamPtrs = PDSP_+2
DEFC OrnPtrs = SamPtrs+2
DEFC PatsPtr = OrnPtrs+2
DEFC LPosPtr = PatsPtr+2
DEFC PrSlide = LPosPtr+2
DEFC L3 = PrSlide
DEFC M2 = PrSlide
DEFC PrNote = PrSlide+2
DEFC Version = PrNote+1

DEFC VAR0START = Version+1
DEFC ChanA = VAR0START
DEFC ChanB = ChanA+CHP
DEFC ChanC = ChanB+CHP
DEFC DelyCnt = ChanC+CHP
DEFC CurESld = DelyCnt+1
DEFC CurEDel = CurESld+2
DEFC Ns_Base = CurEDel+1
DEFC Ns_Base_AddToNs = Ns_Base
DEFC AddToNs = Ns_Base+1
DEFC AYREGS = AddToNs+1
DEFC Ampl = AYREGS+AmplC

; The low-volume rows are silent and double as register and table scratch.
DEFC VT_ = AYREGS
DEFC EnvBase = VT_+14
DEFC T1_ = VT_+16
DEFC VAR0END = T1_
DEFC T_OLD_1 = T1_
DEFC T_OLD_2 = T_OLD_1+24
DEFC T_OLD_3 = T_OLD_2+24
DEFC T_OLD_0 = T_OLD_3+2
DEFC T_NEW_0 = T_OLD_0
DEFC T_NEW_1 = T_OLD_1
DEFC T_NEW_2 = T_NEW_0+24
DEFC T_NEW_3 = T_OLD_3
DEFC NT_ = VT_+256
DEFC PT3_STATE_END = NT_+192
