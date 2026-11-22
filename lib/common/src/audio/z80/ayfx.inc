; Private AYFX channel layout. Pointers are zero only for inactive channels.
        DEFVARS 0 {
        AFX_PTR_LO  ds.b 1
        AFX_PTR_HI  ds.b 1
        AFX_AGE_LO  ds.b 1
        AFX_AGE_HI  ds.b 1
        AFX_VOLUME  ds.b 1
        AFX_TONE_LO ds.b 1
        AFX_TONE_HI ds.b 1
        AFX_NOISE   ds.b 1
        AFX_CHANNEL_SIZE
        }
defc AFX_CHANNEL_BYTES = 3 * AFX_CHANNEL_SIZE
