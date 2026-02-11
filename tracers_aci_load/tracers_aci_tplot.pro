;+
; :Arguments:
;   filenames: bidirectional, required, any
;     Placeholder docs for argument, keyword, or property
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
    suf = '_aci_' + strmid(tmp, 4, 3) ; suffix for variables def or pre (definitive or predictive)

    tvars = []
    stop
    vstr = stregex(filenames, '(v)(.+\..+\..+)(\.cdf)', /extract, /subexpr)
    highv = get_highest_version(vstr[2, *], 3)
    acel2file = filenames[highv]

    stop
    for ifil = 0, nfilesexists - 1 do begin
      cdf2tplot, files = filenames[ifil], varformat = '*', suffix = suf[ifil]
      tvars = [tvars, tnames()]
    end ; for files
  endif ; over filenames found check
end

; program
