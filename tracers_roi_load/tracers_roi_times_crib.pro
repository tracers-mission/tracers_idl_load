compile_opt idl2

; This is still being worked on!!

tracers_init ; set your TRACERS portal username and password

timespan, '2025-09-27', 1 ; one day of data

tracers_roi_load

tracers_roi_times_load

; -----------------------------------
; TS1 ROIs between 2026-01-19 and 2026-01-20
; -----------------------------------
tracers_roi_load, spacecraft = 'ts1', trange = ['2026-01-19', '2026-01-20'], roi_out = rois

if rois.ts1.tstart[0] ne '' then begin
  n = n_elements(rois.ts1.tstart)
  for i = 0, n - 1 do print, rois.ts1.tstart[i] + '  -->  ' + rois.ts1.tend[i]
endif else print, 'No TS1 ROIs found in the requested time range.'
