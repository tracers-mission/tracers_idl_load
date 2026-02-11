;+
; :Description:
;   Notes:
;     filenames must be for one day only! Different from other tplot routines so far 2/10/2026
;
; :Arguments:
;   filenames: bidirectional, required, any
;     Placeholder docs for argument, keyword, or property
;
; :Requirements:
;   - get_highest_version.pro from ACE load routines
;
;-
pro tracers_aci_tplot, filenames
  compile_opt idl2

  cdf_leap_second_init

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

    for ifil = 0, nfilesexists - 1 do begin
      cdf2tplot, files = filenames[ifil], varformat = '*'
      tvars = [tvars, tnames()]

      get_data, 'ts2_l2_aci_tscs_def', data = dat, limit = lim, dlimit = dlim ; differential energy flux
      ntimes = n_elements(dat.x)
      nen = n_elements(dat.v1)
      energy_steps = dat.v1

      ave_flux = fltarr(ntimes, nen) ; y: flux values averaged over all angles
      eflux = fltarr(ntimes, nen)
      energies = fltarr(ntimes, nen) ; v: all energies

      for i = 0, ntimes - 1 do begin ; all times
        for j = 0, nen - 1 do begin ; all energies
          m = moment(dat.y[i, *, j]) ; average over all angles
          ave_flux[i, j] = m[0]
          energies[i, j] = energy_steps[j]
        end ; over energies
      end ; over times

      espec = transpose(total(data.y, 2)) / 16.

      store_data, 'ts2_l2_aci_an_eflux', data = {x: dat.x, y: ave_flux, v: energies}, limit = {ylog: 1, zlog: 1, ytitle: 'Energy [eV]', ztitle: 'Diff. En. Flux', spec: 1, ystyle: 1, no_interp: 1}
      stop
    end ; for files
  endif ; over filenames found check
end

; program
