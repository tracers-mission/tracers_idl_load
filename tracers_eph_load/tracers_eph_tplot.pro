;+
; :Arguments:
;   filenames: bidirectional, required, any
;     Placeholder docs for argument, keyword, or property
;
; :Notes:
;   This procedure assumes that the relevant TRACERS Eph data has already been
;   loaded in using tracers_eph_load.
;   MODIFICATION HISTORY:
;   Written by Skylar Shaver, Jan 2026
;
; :Future work:
;   - set colors for vectors and other limit information
;
;-
pro tracers_eph_tplot, filenames
  compile_opt idl2

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
    suf = '_eph_' + strmid(tmp, 4, 3) ; suffix for variables def or pre (definitive or predictive)

    def_files = filenames[where(suf eq '_eph_def', ndef, /null)]
    pre_files = filenames[where(suf eq '_eph_pre', npre, /null)]
    if ndef gt 0 then cdf2tplot, files = def_files, varformat = '*', suffix = '_eph_def'
    if npre gt 0 then cdf2tplot, files = pre_files, varformat = '*', suffix = '_eph_pre'
  endif ; over filenames found check
end

; program
