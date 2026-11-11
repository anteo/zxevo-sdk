        MODULE ts_window_lease_state
SECTION bss_clib
PUBLIC _ts__memory_window_owner

; Resident pointer to the only active public window lease, or zero.
_ts__memory_window_owner:
        defw 0
