; initialize for TRACERS (team only)
compile_opt idl2
tracers_init

; compile
.compile tracers_aci_load

; download the data
timespan, '2025-09-26', 1 ; one day of data
timespan, '2025-09-28', 1 ; one day of data
tracers_aci_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads data for the time span given to your specified local path on external HDD and tplots

; tplot data from a given path
tracers_aci_tplot, ['/Volumes/wvushaverhd/TRACERS_data/flight/ACI/ts2/l2/aci/ipd/ts2_l2_aci_ipd_20250926_v1.0.0.cdf']

tlimit, ['2025-09-28/22:24:00', '2025-09-28/22:30:00']
tracers_aci_tplot, ['/Volumes/wvushaverhd/TRACERS_data/flight/ACI/ts2/l2/aci/ipd/ts2_l2_aci_ipd_20250928_v1.0.0.cdf']

; 16 look angle bins
; 47 energy bins
; Precipitating ions have energy fluxes typically between 1.e6 and 1.e8
;
; read in cdf files using Jasper's code
; Note that not setting download only does this automatically for l2 data
tracers_aci_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', data_filenames = fns, /downloadonly, level = 'l2'
