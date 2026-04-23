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
;   level: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;   spacecraft: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;
; :Requirements:
;   - get_highest_version.pro from ACE load routines
;
;-
pro tracers_aci_tplot, filenames, spacecraft = spacecraft, level = level
  compile_opt idl2

  if undefined(spacecraft) then spacecraft = 'ts2' ; default to ts2
  if n_elements(spacecraft) eq 1 and (isa(spacecraft, /array, /string)) then spacecraft = spacecraft[0]

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

    ; save pre-existing raw CDF variables before cdf2tplot overwrites them
    raw_vnames = [spacecraft + '_l2_aci_tscs_def', $
                  spacecraft + '_l2_aci_tscs_def_errors', $
                  spacecraft + '_l2_aci_tscs_def_sorted_counts', $
                  spacecraft + '_l2_aci_tscs_pitch_angle', $
                  spacecraft + '_l2_aci_gei2000_look_direction_theta', $
                  spacecraft + '_l2_aci_gei2000_look_direction_phi', $
                  spacecraft + '_l2_aci_quat_tscs_to_gei2000']
    nraw = n_elements(raw_vnames)
    raw_old = ptrarr(nraw)
    for iv = 0, nraw - 1 do begin
      get_data, raw_vnames[iv], data = tmp_old
      if isa(tmp_old, 'struct') then raw_old[iv] = ptr_new(tmp_old)
    endfor

    ; for ifil = 0, nfilesexists - 1 do begin
    ; cdf2tplot, files = filenames[ifil], varformat = '*'
    cdf2tplot, files = acil2file, varformat = '*'
    tvars = [tvars, tnames()]

    ; append new data onto any pre-existing raw CDF variables and time-sort
    for iv = 0, nraw - 1 do begin
      if ~ptr_valid(raw_old[iv]) then continue
      get_data, raw_vnames[iv], data = new_dat
      if ~isa(new_dat, 'struct') then continue
      old_dat = *raw_old[iv]
      combined_x = [old_dat.x, new_dat.x]
      sort_idx = sort(combined_x)
      combined_y = [old_dat.y, new_dat.y]
      ndims = size(combined_y, /n_dimensions)
      case ndims of
        3: combined_y = combined_y[sort_idx, *, *]
        2: combined_y = combined_y[sort_idx, *]
        else: combined_y = combined_y[sort_idx]
      endcase
      new_struct = {x: combined_x[sort_idx], y: combined_y}
      if tag_exist(new_dat, 'v2') then new_struct = create_struct(new_struct, 'v1', new_dat.v1, 'v2', new_dat.v2) $
      else if tag_exist(new_dat, 'v1') then new_struct = create_struct(new_struct, 'v1', new_dat.v1) $
      else if tag_exist(new_dat, 'v') then new_struct = create_struct(new_struct, 'v', new_dat.v)
      store_data, raw_vnames[iv], data = new_struct
    endfor
    ptr_free, raw_old

    ; differential energy flux!
    ; ------------------------------------
    tmp_vname = spacecraft + '_l2_aci_tscs_def'
    get_data, tmp_vname, data = dat, limit = lim, dlimit = dlim ; differential energy flux
    if isa(dat, 'struct') then begin
      ntimes = n_elements(dat.x)
      nen = n_elements(dat.v1)
      nang = n_elements(dat.v2) ; look angles
      energy_steps = dat.v1
      angle_Steps = dat.v2

      ; --- unused / in-progress: per-cell moment loop (ave_flux never stored) ---
      ; ave_flux = fltarr(ntimes, nen) ; y: flux values averaged over all angles
      ; eflux = fltarr(ntimes, nen)
      ; energies = fltarr(ntimes, nen) ; v: all energies
      ; angles = fltarr(ntimes, nang) ; all angles
      ;
      ; for i = 0, ntimes - 1 do begin ; all times
      ; for j = 0, nen - 1 do begin ; all energies
      ; m = moment(dat.y[i, j, *]) ; average over all angles
      ; ave_flux[i, j] = m[0]
      ; energies[i, j] = energy_steps[j]
      ; end ; over energies
      ; for k = 0, nang - 1 do begin ; all look angles
      ; angles[i, k] = angle_Steps[k]
      ; end
      ; end ; over times
      ; store_data, 'ts2_l2_aci_an_eflux', data = {x: dat.x, y: ave_flux, v: energies}, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1, no_interp: 1}
      ; --- end unused block ---

      ; angle-averaged energy spectrogram: mean over 16 anode angles
      espec_avg = total(dat.y, 3) / nang
      store_data, spacecraft + '_l2_aci_en_eflux_avg', data = {x: dat.x, y: espec_avg, v: energy_steps}, $
        limit = {ylog: 1, zlog: 1, ytitle: strupcase(spacecraft) + '!CEnergy [eV]', ztitle: 'Avg Diff. En. Flux', $
          spec: 1, yrange: [8., 2.e4], ystyle: 1}

      ; angle-integrated energy spectrogram: sum over 16 anode angles
      espec_int = total(dat.y, 3)
      store_data, spacecraft + '_l2_aci_en_eflux_int', data = {x: dat.x, y: espec_int, v: energy_steps}, $
        limit = {ylog: 1, zlog: 1, ytitle: strupcase(spacecraft) + '!CEnergy [eV]', ztitle: 'Int. Diff. En. Flux', $
          spec: 1, yrange: [8., 2.e4], ystyle: 1}

      ; energy-averaged angle spectrogram: mean over 47 energy channels
      aspec = total(dat.y, 2) / nen
      store_data, spacecraft + '_l2_aci_an_eflux_avg', data = {x: dat.x, y: aspec, v: angle_Steps}, $
        limit = {ylog: 0, zlog: 1, ytitle: strupcase(spacecraft) + '!CAnode Angle', ztitle: 'Avg Diff. En. Flux', spec: 1, ystyle: 1}
    endif else dprint, 'WARNING: ' + tmp_vname + ' not found in CDF — skipping diff. energy flux variables.'

    ; COUNTS!
    ; ------------------------------------
    tmp_vname = spacecraft + '_l2_aci_tscs_def_sorted_counts'
    get_data, tmp_vname, data = dat, limit = lim, dlimit = dlim ; counts
    if isa(dat, 'struct') then begin
      ntimes = n_elements(dat.x)
      nen = n_elements(dat.v1)
      nang = n_elements(dat.v2) ; look angles
      energy_steps = dat.v1
      angle_Steps = dat.v2

      ; --- unused / in-progress: per-cell moment loop (ave_flux never stored) ---
      ; ave_flux = fltarr(ntimes, nen) ; y: flux values averaged over all angles
      ; eflux = fltarr(ntimes, nen)
      ; energies = fltarr(ntimes, nen) ; v: all energies
      ; angles = fltarr(ntimes, nang) ; all angles
      ;
      ; for i = 0, ntimes - 1 do begin ; all times
      ; for j = 0, nen - 1 do begin ; all energies
      ; ; m = moment(dat.y[i, *, j]) ; average over all angles
      ; ; ave_flux[i, j] = m[0]
      ; energies[i, j] = energy_steps[j]
      ; end ; over energies
      ; for k = 0, nang - 1 do begin ; all look angles
      ; angles[i, k] = angle_Steps[k]
      ; end ; angles
      ; end ; over times
      ; --- end unused block ---

      ; angle-averaged counts energy spectrogram: mean over 16 anode angles
      especc_avg = total(dat.y, 3) / nang
      store_data, spacecraft + '_l2_aci_en_counts_avg', data = {x: dat.x, y: especc_avg, v: energy_steps}, $
        limit = {ylog: 1, zlog: 1, ytitle: strupcase(spacecraft) + '!CEnergy [eV]', ztitle: 'Avg Counts', $
          spec: 1, ystyle: 1, zrange: [1.e-2, 1.e2]}

      ; angle-integrated counts energy spectrogram: sum over 16 anode angles
      especc_int = total(dat.y, 3)
      store_data, spacecraft + '_l2_aci_en_counts_int', data = {x: dat.x, y: especc_int, v: energy_steps}, $
        limit = {ylog: 1, zlog: 1, ytitle: strupcase(spacecraft) + '!CEnergy [eV]', ztitle: 'Int. Counts', $
          spec: 1, ystyle: 1, zrange: [1.e-2, 1.e2]}

      ; energy-averaged angle spectrogram: mean over 47 energy channels
      aspecc = total(dat.y, 2) / nen
      store_data, spacecraft + '_l2_aci_an_counts_avg', data = {x: dat.x, y: aspecc, v: angle_Steps}, $
        limit = {ylog: 0, zlog: 1, ytitle: strupcase(spacecraft) + '!CAnode Angle', ztitle: 'Avg Counts', spec: 1, ystyle: 1, zrange: [1.e-2, 1.e2]}
    endif else dprint, 'WARNING: ' + tmp_vname + ' not found in CDF — skipping counts variables.'

    ; PITCH ANGLE
    ; ------------------------------------
    ; TODO: add pitch angle derived products (e.g., pitch angle distributions, flux vs pitch angle)
    tmp_vname = spacecraft + '_l2_aci_tscs_pitch_angle'
    get_data, tmp_vname, data = dat, limit = lim, dlimit = dlim
    if isa(dat, 'struct') then begin
      ; placeholder: store raw pitch angle variable for plotting
      store_data, spacecraft + '_l2_aci_pitch_angle', data = dat, $
        limit = {ytitle: strupcase(spacecraft) + '!CPitch Angle [deg]'}
    endif else dprint, 'WARNING: ' + tmp_vname + ' not found in CDF — skipping pitch angle variables.'

    ; end ; for files
  endif ; over filenames found check
end

; program
