compile_opt idl2

; tracers_msc_tplot requires get_highest_version.pro from the ACE load routines
.compile get_highest_version
.compile tracers_msc_load
.compile tracers_msc_tplot

; initialize for TRACERS (team only)
tracers_init

; download the data
timespan, '2026-03-06', 1 ; one day of data
tracers_msc_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; load L2 MSC search coil data

tracers_msc_load, data_filenames = fns_msc, /downloadonly ; returns the full path and filenames of the downloaded
; data files for the given time span, doesn't create tplot variables
tracers_msc_tplot, fns_msc ; creates tplot variables from the downloaded data files

tplot, tnames('ts2_l2_msc_*')
