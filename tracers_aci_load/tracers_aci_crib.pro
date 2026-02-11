; initialize for TRACERS (team only)
compile_opt idl2
tracers_init
tracers_login ; set your TRACERS portal username and password

; compile
.compile tracers_aci_load

; download the data
timespan, '2025-09-26', 1 ; one day of data
tracers_aci_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads data for the time span given to your specified local path on external HDD and tplots

; read in cdf files using Jasper's code
; Note that not setting download only does this automatically for l2 data
tracers_aci_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', data_filenames = fns, /downloadonly, level = 'l2'
