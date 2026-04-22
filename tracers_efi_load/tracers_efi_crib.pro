; Load Tracers Data
; ------------------
; set time span
compile_opt idl2

@'qualcolors' ; you have the qualcolors library available

device, true = 24, decompose = 0, retain = 2
loadcv, 39  ; load rainbow+white color table

; initialize for TRACERS 
tracers_init

; download the data
timespan, '2025-09-26', 1 ; one day of data
tracers_efi_load, local_path = '/Users/SkyShaver/Data/TRACERS_data/' ; loads l2 data for the time span given to your specified local path
tracers_efi_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads l2 data for the time span given to your specified local path on external HDD
tracers_efi_load, url_username = 'tracers-username', url_password = 'tracers-password' ; use these keywords if you havent set the 'TRACERS_USER_PASS' environment variable


tracers_efi_load, data_filenames = fns_ts2_l2, /downloadonly ; returns the full path and filenames of the downloaded data files for the given time span, doesnt create tplot variables
tracers_efi_load, data_filenames = fns_ts1_l2, spacecraft='ts1', /downloadonly 
fns = [fns_ts2_l2, fns_ts1_l2] ; combine both spacecraft file lists
tracers_efi_tplot, fns, spacecraft=['ts1', 'ts2'], level='l2' creates tplot variables from the downloaded data files

tplot, ['ts2_l2_edc_gei', 'ts2_l2_hf','ts2_l2_eac']
tplot, ['ts2_l2_hf_spec', 'ts2_efi_hf_spec_filt_kHz']


; Want solar wind data?
;------------------------
timespan, '2025-09-26', 1 ; one day of data
tracers_sw_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; load solar wind data

tracers_sw_load, data_filenames = fns_sw, /downloadonly ; returns the full path and filenames of the downloaded data files for the given time span, doesnt create tplot variables
tracers_sw_tplot, fns_sw ; creates tplot variables from the downloaded data files
