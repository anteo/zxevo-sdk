        MODULE ts_cpu_clock_state
SECTION data_clib
PUBLIC ts__cpu_speed
PUBLIC ts__cache_mask
PUBLIC _ts__cache_mask
defc _ts__cache_mask = ts__cache_mask

; SysConfig and CacheConfig are write-only. FFh means the SDK does not yet
; know the corresponding state, independently of the hardware reset values.
ts__cpu_speed: defb 0ffh
ts__cache_mask: defb 0ffh
