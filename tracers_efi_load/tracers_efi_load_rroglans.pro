;+
; :Description:
;   As of May 2026, EFI data must be manually despun due to issues with the pointing information.
;   Therefore, requests for data must be made directly to the EFI team.
;   This procedure is designed to load the manually despun data files.
;
; :Arguments:
;   filenames: bidirectional, required, String | Array<any>
;     path and filenames to EFI cdf files
;   timerange: bidirectional, required, any
;     must include timerange due to handling issue of TT20000 values
;     to get time range, you may run:
;         timespan, '2026-01-01', 2 ; two days starting from Jan 1, 2026 for example
;         timerange = timerange()
;     or you can directly specify the start and end times as:
;         timerange = ['2026-01-01/00:00:00', '2026-01-02/00:00:00']
;
;-
pro tracers_efi_load_rroglans, filenames, timerange
  compile_opt idl2

  if (size(filenames, /type) eq 7) then begin ; check that its strings
    ; only proceed if filenames are found
    finfo = file_info(filenames)
    indx = where(finfo.exists, nfilesexists, comp = jndx, ncomp = n)
    for j = 0, (n - 1) do print, 'File not found: ', filenames[jndx[j]]
    if (nfilesexists eq 0) then begin
      dprint, 'No files found for the time range... Returning.'
      return
    endif
    filenames = filenames[indx]

    ; turn into tplot variables
    cdf2tplot, filenames, varformat = '*'
    ; reset timespan because of handling issue of TT20000 values (it sets global tplot timespan from raw TT20000 values, which is not desired)
    timespan, timerange

    ; set the tplot variable attributes
    if total(tnames('ts?_l2_igrf_fvc') ne '') ge 1 then options, 'ts?_l2_igrf_fvc', labflag = 1, labels = ['BX!DIGRF!N', 'BY!DIGRF!N', 'BZ!DIGRF!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_vxb_fvc') ne '') ge 1 then options, 'ts?_l2_vxb_fvc', labflag = 1, labels = ['EX!DVXB!N', 'EY!DVXB!N', 'EZ!DVXB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_esub_fvc') ne '') ge 1 then options, 'ts?_l2_esub_fvc', labflag = 1, labels = ['EX!DESUB!N', 'EY!DESUB!N', 'EZ!DESUB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_exb_fvc') ne '') ge 1 then options, 'ts?_l2_exb_fvc', labflag = 1, labels = ['VX!DEXB!N', 'VY!DEXB!N', 'VZ!DEXB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_edc_fvc') ne '') ge 1 then options, 'ts?_l2_edc_fvc', labflag = 1, labels = ['EX!DEDC!N', 'EY!DEDC!N', 'EZ!DEDC!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_vxb_TSCS') ne '') ge 1 then options, 'ts?_l2_vxb_TSCS', labflag = 1, labels = ['EX!DVXB!N', 'EY!DVXB!N', 'EZ!DVXB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_esub_TSCS') ne '') ge 1 then options, 'ts?_l2_esub_TSCS', labflag = 1, labels = ['EX!DESUB!N', 'EY!DESUB!N', 'EZ!DESUB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_exb_TSCS') ne '') ge 1 then options, 'ts?_l2_exb_TSCS', labflag = 1, labels = ['VX!DEXB!N', 'VY!DEXB!N', 'VZ!DEXB!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_igrf_TSCS') ne '') ge 1 then options, 'ts?_l2_igrf_TSCS', labflag = 1, labels = ['BX!DIGRF!N', 'BY!DIGRF!N', 'BZ!DIGRF!N'], colors = ['r', 'g', 'b']
    if total(tnames('ts?_l2_edc_TSCS') ne '') ge 1 then options, 'ts?_l2_edc_TSCS', labflag = 1, labels = ['EX!DEDC!N', 'EY!DEDC!N', 'EZ!DEDC!N'], colors = ['r', 'g', 'b']
  endif
end
