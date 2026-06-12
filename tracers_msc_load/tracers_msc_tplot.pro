;+
; :Description:
;   Notes:
;     filenames must be for one day only!
;
;     MSC L2 'bac' CDF variable names are not known ahead of time, so
;     cdf2tplot is called with varformat='*' to load whatever variables
;     are present. Because tracers_msc_load processes data day by day, any
;     pre-existing tplot variables matching '[spacecraft]_l2_msc_*' are
;     snapshotted before cdf2tplot runs, and new data is appended/time-sorted
;     onto them afterward.
;
; :Arguments:
;   filenames: bidirectional, required, str
;     path and filenames to get to cdf files to convert to tplot
;
; :Keywords:
;   spacecraft: bidirectional, optional, str
;     spacecraft ('ts1' or 'ts2'), defaults to 'ts2'
;
; :Requirements:
;   - get_highest_version.pro from ACE load routines
;
;-
pro tracers_msc_tplot, filenames, spacecraft = spacecraft
  compile_opt idl2

  if undefined(spacecraft) then spacecraft = 'ts2' ; default to ts2
  if n_elements(spacecraft) eq 1 and (isa(spacecraft, /array, /string)) then spacecraft = spacecraft[0]

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
    mscfile = filenames[highv]

    ; snapshot pre-existing l2 msc variables before cdf2tplot overwrites them
    prefix = spacecraft + '_l2_msc'
    old_vnames = tnames(prefix + '_*')
    nold = n_elements(old_vnames)
    old_dat = ptrarr(nold)
    for iv = 0, nold - 1 do begin
      get_data, old_vnames[iv], data = tmp_old
      if isa(tmp_old, 'struct') then old_dat[iv] = ptr_new(tmp_old)
    endfor

    cdf2tplot, files = mscfile, varformat = '*'

    ; append new data onto any pre-existing variables and time-sort
    for iv = 0, nold - 1 do begin
      if ~ptr_valid(old_dat[iv]) then continue
      get_data, old_vnames[iv], data = new_dat
      if ~isa(new_dat, 'struct') then continue
      old_d = *old_dat[iv]
      combined_x = [old_d.x, new_dat.x]
      sort_idx = sort(combined_x)
      combined_y = [old_d.y, new_dat.y]
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
      store_data, old_vnames[iv], data = new_struct
    endfor
    ptr_free, old_dat
  endif ; over filenames found check
end
