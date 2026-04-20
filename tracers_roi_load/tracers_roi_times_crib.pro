compile_opt idl2

tracers_init ; set your TRACERS portal username and password

timespan, '2025-09-27', 1 ; one day of data

; load ROIs for TS1, TS2, and tandem for the same time period (default: spacecraft='all')
rois = tracers_roi_load()

; Note that this returns a structure with three sub-structures: rois.ts1, rois.ts2, and rois.tandem,
; each with their own tstart and tend arrays for the ROIs for that spacecraft or for tandem ROIs.
print, rois.ts1.tstart ; all TS1 start times in the window
print, rois.ts2.tend ; all TS2 end times in the window
print, rois.tandem.tstart ; all tandem start times in the window

; -----------------------------------
; TS1 ROIs between 2026-01-19 and 2026-01-20
; -----------------------------------
rois = tracers_roi_load(spacecraft = 'ts1', trange = ['2026-01-19', '2026-01-20'])

if rois.ts1.tstart[0] ne '' then begin
  n = n_elements(rois.ts1.tstart)
  for i = 0, n - 1 do print, rois.ts1.tstart[i] + '  -->  ' + rois.ts1.tend[i]
endif else print, 'No TS1 ROIs found in the requested time range.'

; -----------------------------------
; TS2 ROIs between 2026-01-19 and 2026-01-20
; -----------------------------------
rois = tracers_roi_load(spacecraft = 'ts2', trange = ['2026-01-19', '2026-01-20'])

if rois.ts2.tstart[0] ne '' then begin
  n = n_elements(rois.ts2.tstart)
  for i = 0, n - 1 do print, rois.ts2.tstart[i] + '  -->  ' + rois.ts2.tend[i]
endif else print, 'No TS2 ROIs found in the requested time range.'

; -----------------------------------
; Tandem ROIs between 2026-01-19 and 2026-01-20
; -----------------------------------
rois = tracers_roi_load(spacecraft = 'tandem', trange = ['2026-01-19', '2026-01-20'])

if rois.tandem.tstart[0] ne '' then begin
  n = n_elements(rois.tandem.tstart)
  for i = 0, n - 1 do print, rois.tandem.tstart[i] + '  -->  ' + rois.tandem.tend[i]
endif else print, 'No tandem ROIs found in the requested time range.'
