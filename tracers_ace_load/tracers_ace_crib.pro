compile_opt idl2
@'qualcolors' ; you have the qualcolors library available
.compile loadcv
.compile loadcsvcolorbar

device, true = 24, decompose = 0, retain = 2
loadcv, 39 ; load rainbow+white color table

; initialize for TRACERS (team only)
tracers_init
tracers_login ; set your TRACERS portal username and password

; compile
.compile tracers_ace_load
.compile tra_ace_load_l2_data
.compile tra_ace_make_info_str

; download the data
timespan, '2025-09-26', 1 ; one day of data
tracers_ace_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads data for the time span given to your specified local path on external HDD and tplots

; read in cdf files using Jasper's code
; Note that not setting download only does this automatically for l2 data
tracers_ace_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/', data_filenames = fns, /downloadonly, level = 'l2'
dirname = file_dirname(fns, /mark_directory)
dirname = dirname[0].remove(-8)
tracers_ace_load_l2_data, path = dirname, sv = 'ts2', /tplot, /chare
; dependencies: get_highest_version.pro, tra_ace_make_info_str.pro

; spectra
get_data, 'ts2_ace_en_eflux', data = dat, limit = lim
store_data, 'ts2_ace_en_eflux', data = dat, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1, no_interp: 1}
