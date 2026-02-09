;+
; initialize environment
; load TRACERS data and tplot it!
;-
; pro tracers_load_tplot_crib
compile_opt idl2

tracers_login
tracers_init ; set your TRACERS portal username and password

timespan, '2025-09-27', 1 ; one day of data

; EFI Load Routine
; -----------------------------------
tracers_efi_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads l2 data for the time span given to your specified local path on external HDD

; ACE Load/tplot
; -----------------------------------
tracers_ace_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads data for the time span given to your specified local path on external HDD and tplots

; Solar Wind Data Load
; -----------------------------------
tracers_sw_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; load solar wind data onto external HD

; Ephemeris/Orbit Data Load
; -----------------------------------
tracers_eph_load, datatype = ['pred', 'def'] ; loads predictive and defnitive data

; Tplot some stuff
; ----------------------------------
options, 'ts2_ead_mlt_eph_def', ytitle = 'MLT (def)'
options, 'ts2_ead_mlat_eph_def', ytitle = 'MLAT (def)'
options, 'ts2_ead_altitude_geod_eph_def', ytitle = 'Alt (def)'
tplot_options, 'xmargin', [20, 15]
tplot_options, var_label = ['ts2_ead_mlt_eph_def', 'ts2_ead_mlat_eph_def', 'ts2_ead_altitude_geod_eph_def']

; you may need to go back into Jasper's code and redo his limits structure

get_data, 'ts2_ace_en_eflux', data = dat, limit = lim
store_data, 'ts2_ace_en_eflux', data = dat, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1, no_interp: 1}

tplot, ['ts2_ace_en_eflux', 'ts2_l2_edc_gei', 'bdc_sw']

stop
; end
