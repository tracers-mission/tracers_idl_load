;+
; :Description:
;   Notes:
;     filenames must be for one day only! Different from other tplot routines so far 2/10/2026
;
; :Arguments:
;   filenames: bidirectional, required, any
;     Placeholder docs for argument, keyword, or property
;
; :Keywords:
;   sv: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;
; :Requirements:
;   - get_highest_version.pro from ACE load routines
;
;-
pro tracers_aci_tplot, filenames, sv = sv
  compile_opt idl2

  if undefined(sv) then sv = 'ts2' ; default to ts2
  if n_elements(sv) eq 1 and (isa(sv, /array, /string)) then sv = sv[0]

  ; cdf_leap_second_init

  if (size(filenames, /type) eq 7) then begin
    ; only proceed if filenames are found
    finfo = file_info(filenames)
    indx = where(finfo.exists, nfilesexists, comp = jndx, ncomp = n)
    for j = 0, (n - 1) do print, 'File not found: ', filenames[jndx[j]]
    if (nfilesexists eq 0) then begin
      dprint, 'No files found for the time range... Returning.'
      return
    endif
    filenames = filenames[indx]

    tmp = file_basename(filenames)
    vstr = stregex(tmp, '(v)(.+\..+\..+)(\.cdf)', /extract, /subexpr)
    highv = get_highest_version(vstr[2, *], 3)
    acil2file = filenames[highv]

    ; tvars = [] ; highest version file only
    ; cdf2tplot, files = acil2file, varformat = '*'
    ; tvars = [tvars, tnames()]

    tvars = []

    ; for ifil = 0, nfilesexists - 1 do begin
    ; cdf2tplot, files = filenames[ifil], varformat = '*'
    cdf2tplot, files = acil2file, varformat = '*'
    tvars = [tvars, tnames()]

    ; differential energy flux!
    ; ------------------------------------
    tmp_vname = sv + '_l2_aci_tscs_def'
    get_data, tmp_vname, data = dat, limit = lim, dlimit = dlim ; differential energy flux
    ntimes = n_elements(dat.x)
    nen = n_elements(dat.v1)
    nang = n_elements(dat.v2) ; look angles
    energy_steps = dat.v1
    angle_Steps = dat.v2

    ave_flux = fltarr(ntimes, nen) ; y: flux values averaged over all angles
    eflux = fltarr(ntimes, nen)
    energies = fltarr(ntimes, nen) ; v: all energies
    angles = fltarr(ntimes, nang) ; all angles

    for i = 0, ntimes - 1 do begin ; all times
      for j = 0, nen - 1 do begin ; all energies
        m = moment(dat.y[i, j, *]) ; average over all angles
        ave_flux[i, j] = m[0]
        energies[i, j] = energy_steps[j]
      end ; over energies
      for k = 0, nang - 1 do begin ; all look angles
        angles[i, k] = angle_Steps[k]
      end
    end ; over times
    ; store_data, 'ts2_l2_aci_an_eflux', data = {x: dat.x, y: ave_flux, v: energies}, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1, no_interp: 1}

    espec = total(dat.y, 3) / 16.
    store_Data, sv + '_l2_aci_en_eflux', data = {x: dat.x, y: espec, v: energies}, $
      limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', $
        spec: 1, yrange: [8., 2.e4], ystyle: 1} ; , ystyle: 1, no_interp: 1}

    aspec = total(dat.y, 2) / 47.
    store_data, sv + '_l2_aci_an_eflux', data = {x: dat.x, v: angles, y: aspec, zlog: 1, ytitle: 'Anode Angle', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1} ; , no_interp: 1}

    ; COUNTS!
    ; ------------------------------------
    tmp_vname = sv + '_l2_aci_tscs_def_sorted_counts'
    get_data, tmp_vname, data = dat, limit = lim, dlimit = dlim ; counts
    ntimes = n_elements(dat.x)
    nen = n_elements(dat.v1)
    nang = n_elements(dat.v2) ; look angles
    energy_steps = dat.v1
    angle_Steps = dat.v2

    ave_flux = fltarr(ntimes, nen) ; y: flux values averaged over all angles
    eflux = fltarr(ntimes, nen)
    energies = fltarr(ntimes, nen) ; v: all energies
    angles = fltarr(ntimes, nang) ; all angles

    for i = 0, ntimes - 1 do begin ; all times
      for j = 0, nen - 1 do begin ; all energies
        ; m = moment(dat.y[i, *, j]) ; average over all angles
        ; ave_flux[i, j] = m[0]
        energies[i, j] = energy_steps[j]
      end ; over energies
      for k = 0, nang - 1 do begin ; all look angles
        angles[i, k] = angle_Steps[k]
      end ; angles
    end ; over times
    especc = total(dat.y, 3) / 16.
    store_Data, sv + '_l2_aci_en_counts', data = {x: dat.x, y: especc, v: energies}, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Avg Counts', spec: 1, ystyle: 1, zrange: [1.e-2, 1.e2]} ; , no_interp: 1}

    aspecc = total(dat.y, 2) / 47.
    store_Data, sv + '_l2_aci_an_counts', data = {x: dat.x, y: aspecc, v: angles}, limit = {ylog: 0, zlog: 1, ytitle: 'Anode Angle', ztitle: 'Avg Counts', spec: 1, ystyle: 1, zrange: [1.e-2, 1.e2]} ; , no_interp: 1}

    ; end ; for files
  endif ; over filenames found check
end

; program
