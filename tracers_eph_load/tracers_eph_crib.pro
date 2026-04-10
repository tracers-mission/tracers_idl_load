compile_opt idl2

@'qualcolors' ; you have the qualcolors library available
.compile loadcv

device, true = 24, decompose = 0, retain = 2
loadcv, 39 ; load rainbow+white color table

; initialize for TRACERS (team only)
tracers_init

; download the data
timespan, '2025-09-26', 1 ; one day of data
tracers_eph_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', data_filenames = fns ; loads definitive data for the time span given to your specified local path on external HDD
tracers_eph_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', datatype = ['pred', 'def'] ; loads predictive and defnitive data for the
; time span given to your specified local path on external HDD
tracers_eph_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', spacecraft = ['ts1'], datatype = ['pred']
tracers_eph_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', spacecraft = ['ts2'], datatype = ['pred']
