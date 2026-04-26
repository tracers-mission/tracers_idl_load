;+
; :Description:
;   NAME: tracers_efi_tplot
;   PURPOSE: Set tplot options for TRACERS EFI data
;   CATEGORY: TRACERS EFI
;   CALLING SEQUENCE: tracers_efi_tplot
;   DESCRIPTION:
;    This procedure sets tplot options for TRACERS EFI data variables.
;    It customizes the appearance of plots for electric field data (EDC),
;    voltage data (VDC), housekeeping (HSK), and high-frequency spectra (EHF).
;    It also creates derived variables for easier analysis.
;   INPUTS:
;    pathnames to files
;   OUTPUTS:
;    None.
;   EXAMPLES:
;    tracers_efi_tplot
;    This command sets the tplot options for TRACERS EFI data.
;   NOTES:
;    This procedure assumes that the relevant TRACERS EFI data has already been
;    loaded using tracers_efi_load.
;   MODIFICATION HISTORY:
;    Written by Skylar Shaver, Jan 2026
;
;    Future:
;     - Add customization for ts1 vs ts2 spacecraft on tplot options
;
; :Arguments:
;   filenames: bidirectional, required, Array<String>
;     path and filenames to cdf files to convert to tplot variables
;
; :Keywords:
;   level: bidirectional, optional, str
;     which level of data to create tplot variables for
;   spacecraft: bidirectional, optional, str
;     which spacecraft to create tplot variables for
;
;-
pro tracers_efi_tplot, filenames, spacecraft = spacecraft, level = level
  compile_opt idl2

  if undefined(spacecraft) then spacecraft = ['ts2'] else spacecraft = strlowcase(spacecraft) ; default to ts2
  if (isa(spacecraft, /array) eq 0) then spacecraft = [strlowcase(spacecraft)] ; make into array if single string given
  if undefined(level) then level = 'l2' else level = strlowcase(level)

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

    indx = where(strmatch(filenames, '*edc_*'), nedcfiles)
    if (nedcfiles gt 0) then begin
      edcfile = filenames[indx]
      cdf2tplot, files = edcfile, varformat = '*', tplotnames = tvars_edc
      doedc = 1
    endif else doedc = 0

    indx = where(strmatch(filenames, '*edc-roi_*'), nedcroifiles)
    if (nedcroifiles gt 0) then begin
      edcroifile = filenames[indx]
      cdf2tplot, files = edcroifile, varformat = '*', tplotnames = tvars_roi, midfix = 'edc-roi_', midpos = 'edc_'
      doedcroi = 1
    endif else doedcroi = 0

    indx = where(strmatch(filenames, '*edc-bor_*'), nedcborfiles)
    if (nedcborfiles gt 0) then begin
      edcborfile = filenames[indx]
      cdf2tplot, files = edcborfile, varformat = '*', tplotnames = tvars_bor, midfix = 'edc-bor_', midpos = 'edc_'
      doedcbor = 1
    endif else doedcbor = 0

    indx = where(strmatch(filenames, '*ehf_*'), nehffiles)
    if (nehffiles gt 0) then begin
      ehffile = filenames[indx]
      cdf2tplot, files = ehffile, varformat = '*', tplotnames = tvars_ehf
      doehf = 1
    endif else doehf = 0

    indx = where(strmatch(filenames, '*vdc_*'), nvdcfiles)
    if (nvdcfiles gt 0) then begin
      vdcfile = filenames[indx]
      cdf2tplot, files = vdcfile, varformat = '*', tplotnames = tvars_vdc
      dovdc = 1
    endif else dovdc = 0

    indx = where(strmatch(filenames, '*vdc-roi_*'), nvdcroifiles)
    if (nvdcroifiles gt 0) then begin
      vdcroifile = filenames[indx]
      cdf2tplot, files = vdcroifile, varformat = '*', tplotnames = tvars_roi, midfix = 'vdc-roi_', midpos = 'vdc_'
      dovdcroi = 1
    endif else dovdcroi = 0

    indx = where(strmatch(filenames, '*vdc-bor_*'), nvdcborfiles)
    if (nvdcborfiles gt 0) then begin
      vdcborfile = filenames[indx]
      cdf2tplot, files = vdcborfile, varformat = '*', tplotnames = tvars_bor, midfix = 'vdc-bor_', midpos = 'vdc_'
      dovdcbor = 1
    endif else dovdcbor = 0

    indx = where(strmatch(filenames, '*hsk_*'), nhskfiles)
    if (nhskfiles gt 0) then begin
      hskfile = filenames[indx]
      cdf2tplot, files = hskfile, varformat = '*', tplotnames = tvars_hsk
      dohsk = 1
    endif else dohsk = 0

    indx = where(strmatch(filenames, '*eac_*'), neacfiles)
    if (neacfiles gt 0) then begin
      eacfile = filenames[indx]
      cdf2tplot, files = eacfile, varformat = '*', tplotnames = tvars_eac
      doeac = 1
    endif else doeac = 0

    ; ============================================
    ; Level 2 Data Derived Variables
    ; ============================================
    if level eq 'l2' then begin
      ; EDC options
      ; ---------------------------------------------
      if doedc then begin
        if total(tnames('ts?_l2_edc*_gei') ne '') ge 1 then options, 'ts?_l2_edc*_gei', labflag = 1, labels = ['EX!DGEI!N', 'EY!DGEI!N', 'EZ!DGEI!N'], colors = ['r', 'g', 'b']
        if total(tnames('ts?_l2_edc*_fac') ne '') ge 1 then options, 'ts?_l2_edc*_fac', labflag = 1, labels = ['EX!DFAC!N', 'EY!DFAC!N', 'EZ!DFAC!N'], colors = ['r', 'g', 'b']
        if total(tnames('ts?_l2_edc*_fvc') ne '') ge 1 then options, 'ts?_l2_edc*_fvc', labflag = 1, labels = ['EX!DFVC!N', 'EY!DFVC!N', 'EZ!DFVC!N'], colors = ['r', 'g', 'b']
        if total(tnames('ts?_l2_edc*_gsm') ne '') ge 1 then options, 'ts?_l2_edc*_gsm', labflag = 1, labels = ['EX!DGSM!N', 'EY!DGSM!N', 'EZ!DGSM!N'], colors = ['r', 'g', 'b']
        if total(tnames('ts?_l2_edc*_TSCS') ne '') ge 1 then options, 'ts?_l2_edc*_TSCS', labflag = 1, labels = ['EX!DTSCS!N', 'EY!DTSCS!N', 'EZ!DTSCS!N'], colors = ['r', 'g', 'b']
      end ; EDC

      ; VDC options
      ; ---------------------------------------------
      ; VDC options and derived variables.
      if dovdc and (total(spacecraft.contains('ts2')) ge 1) then begin
        get_data, 'ts2_l2_vdc_xminus', data = dxm, limits = lxm, dlimits = dlxm
        get_data, 'ts2_l2_vdc_xplus', data = dxp, limits = lxp, dlimits = dlxp
        get_data, 'ts2_l2_vdc_yminus', data = dym, limits = lym, dlimits = dlym
        get_data, 'ts2_l2_vdc_yplus', data = dyp, limits = lyp, dlimits = dlyp

        if isa(dxm, 'struct') and isa(dxp, 'struct') and isa(dym, 'struct') and isa(dyp, 'struct') then begin
          store_data, 'ts2_l2_vdc_xavg', data = {x: dxm.x, y: 0.5 * (dxm.y + dxp.y)}
          store_data, 'ts2_l2_vdc_yavg', data = {x: dym.x, y: 0.5 * (dym.y + dyp.y)}
          store_data, 'ts2_l2_vdc_xyavg', data = {x: dxm.x, y: 0.25 * (dxm.y + dxp.y + dym.y + dyp.y)}
        endif
      endif ; ts2
      if dovdc and (total(spacecraft.contains('ts1')) ge 1) then begin
        get_data, 'ts1_l2_vdc_xminus', data = dxm, limits = lxm, dlimits = dlxm
        get_data, 'ts1_l2_vdc_xplus', data = dxp, limits = lxp, dlimits = dlxp
        get_data, 'ts1_l2_vdc_yminus', data = dym, limits = lym, dlimits = dlym
        get_data, 'ts1_l2_vdc_yplus', data = dyp, limits = lyp, dlimits = dlyp

        if isa(dxm, 'struct') and isa(dxp, 'struct') and isa(dym, 'struct') and isa(dyp, 'struct') then begin
          store_data, 'ts1_l2_vdc_xavg', data = {x: dxm.x, y: 0.5 * (dxm.y + dxp.y)}
          store_data, 'ts1_l2_vdc_yavg', data = {x: dym.x, y: 0.5 * (dym.y + dyp.y)}
          store_data, 'ts1_l2_vdc_xyavg', data = {x: dxm.x, y: 0.25 * (dxm.y + dxp.y + dym.y + dyp.y)}
        endif
      endif ; over spacecraft 1
      if dovdc then begin ; general options for all VDC variables
        ; set VDC variable colors
        options, 'ts?_l2_vdc_*', colors = ['r']
      end

      ; EAC options and derived variables.
      ; ---------------------------------------------
      if doeac then begin
        if total(spacecraft.contains('ts1')) ge 1 then begin
          get_data, 'ts1_l2_eac', data = d, limits = l, dlimits = dl
          if isa(d, 'struct') then options, 'ts1_l2_eac', colors = ['r', 'g'], labflag = 1, labels = ['X', 'Y']
          get_data, 'ts1_l2_eac_x_spec', data = dx, limits = lx, dlimits = dlx
          get_Data, 'ts1_l2_eac_y_spec', data = dy, limits = ly, dlimits = dly
        end

        if total(spacecraft.contains('ts2')) ge 1 then begin
          get_data, 'ts2_l2_eac', data = d, limits = l, dlimits = dl
          if isa(d, 'struct') then options, 'ts2_l2_eac', colors = ['r', 'g'], labflag = 1, labels = ['X', 'Y']
          get_data, 'ts2_l2_eac_x_spec', data = dx, limits = lx, dlimits = dlx
          if isa(dx, 'struct') then options, 'ts2_l2_eac_x_spec', spec = 1, zlog = 1, zrange = [1.0e-12, 1.0e-9]
          get_Data, 'ts2_l2_eac_y_spec', data = dy, limits = ly, dlimits = dly
          if isa(dy, 'struct') then options, 'ts2_l2_eac_y_spec', spec = 1, zlog = 1, zrange = [1.0e-12, 1.0e-9]
        end
      end ; EAC

      ; HSK options and derived variables.
      ; ---------------------------------------------
      ; conversion formula, BIAS DAC setting to IBIAS in uA:  IBIAS (uA/sensor) = -22.0 uA/sensor + (10.74e-3 (uA/sensor)/(DAC count))*efi_bias?_dig.
      ibias_0 = -22.0 ; uA/sensor.
      dibias_ddac = 10.74e-3 ; (uA/sensor)/(DAC count)
      if dohsk and (total(spacecraft.contains('ts2')) ge 1) then begin
        get_data, 'ts2_l2_efi_bias1_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts2_l2_efi_bias1_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts2_l2_efi_bias2_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts2_l2_efi_bias2_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts2_l2_efi_bias3_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts2_l2_efi_bias3_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts2_l2_efi_bias4_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts2_l2_efi_bias4_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}
      endif ; ts2 HSK
      if dohsk and (total(spacecraft.contains('ts1')) ge 1) then begin
        get_data, 'ts1_l2_efi_bias1_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts1_l2_efi_bias1_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts1_l2_efi_bias2_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts1_l2_efi_bias2_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts1_l2_efi_bias3_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts1_l2_efi_bias3_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}

        get_data, 'ts1_l2_efi_bias4_dig', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then store_data, 'ts1_l2_efi_bias4_uA', data = {x: d.x, y: (ibias_0 + dibias_ddac * d.y)}
      endif ; ts1 HSK
      if dohsk then begin
        ; set HSK bias variable colors
        options, 'ts?_l2_efi_bias?_*', colors = ['r']
      end

      ; EHF options and derived variables.
      ; ---------------------------------------------
      if doehf and (total(spacecraft.contains('ts2')) ge 1) then begin
        ; get_data, 'ts2_l2_hf_spec', data = d, limits = l, dlimits = dl

        ; options, 'ts2_l2_hf_spec', 'spec', 1
        ; options, 'ts2_l2_hf_spec', 'ylog', 0
        ; options, 'ts2_l2_hf_spec', 'yrange', [1., 1.0e7]
        ; options, 'ts2_l2_hf_spec', 'zlog', 1
        ; options, 'ts2_l2_hf_spec', 'zrange', [1.0e-10, 1.0e-4]

        get_data, 'ts2_l2_hf_spec', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then begin
          nbins = 4097l
          ff_bin = findgen(nbins)
          hf_spec_moment = moment(d.y, dimension = 1)
          spec_sig = hf_spec_moment[*, 0l] / sqrt(hf_spec_moment[*, 1l])
          spec_sig_lim = 2.0
          idx = where(spec_sig gt spec_sig_lim, icnt)
          print, icnt

          hf_spec_mean = hf_spec_moment[*, 0l]
          hf_spec_mean_filt = hf_spec_mean

          if icnt gt 0l then hf_spec_mean_filt[idx] = !values.f_nan

          d_filt = d
          d_filt.y[*, idx] = !values.f_nan
          d_filt.v = 10.0e3 * findgen(4097l) / (4096.0) ; frequency bins, kHz.

          store_data, 'ts2_efi_hf_spec_filt_kHz', data = d_filt
          options, 'ts2_efi_hf_spec_filt_kHz', 'spec', 1
          options, 'ts2_efi_hf_spec_filt_kHz', 'zrange', [1.0e-8, 1.0e-6]
          options, 'ts2_efi_hf_spec_filt_kHz', 'zlog', 1
          options, 'ts2_efi_hf_spec_filt_kHz', 'yrange', [10., 2000.]
          options, 'ts2_efi_hf_spec_filt_kHz', 'x_no_interp', 1
          options, 'ts2_efi_hf_spec_filt_kHz', 'y_no_interp', 1

          tt1 = d.x[0l]
          tt2 = d.x[-1l]
          st1 = time_string(tt1)
          st2 = time_string(tt2)
        endif
      endif ; ts2 EHF

      if doehf and (total(spacecraft.contains('ts1')) ge 1) then begin
        ; get_data, 'ts1_l2_hf_spec', data = d, limits = l, dlimits = dl

        ; options, 'ts1_l2_hf_spec', 'spec', 1
        ; options, 'ts1_l2_hf_spec', 'ylog', 0
        ; options, 'ts1_l2_hf_spec', 'yrange', [1., 1.0e7]
        ; options, 'ts1_l2_hf_spec', 'zlog', 1
        ; options, 'ts1_l2_hf_spec', 'zrange', [1.0e-10, 1.0e-4]

        get_data, 'ts1_l2_hf_spec', data = d, limits = l, dlimits = dl
        if isa(d, 'struct') then begin
          nbins = 4097l
          ff_bin = findgen(nbins)
          hf_spec_moment = moment(d.y, dimension = 1)
          spec_sig = hf_spec_moment[*, 0l] / sqrt(hf_spec_moment[*, 1l])
          spec_sig_lim = 2.0
          idx = where(spec_sig gt spec_sig_lim, icnt)
          print, icnt

          hf_spec_mean = hf_spec_moment[*, 0l]
          hf_spec_mean_filt = hf_spec_mean

          if icnt gt 0l then hf_spec_mean_filt[idx] = !values.f_nan

          d_filt = d
          d_filt.y[*, idx] = !values.f_nan
          d_filt.v = 10.0e3 * findgen(4097l) / (4096.0) ; frequency bins, kHz.

          store_data, 'ts1_efi_hf_spec_filt_kHz', data = d_filt
          options, 'ts1_efi_hf_spec_filt_kHz', 'spec', 1
          options, 'ts1_efi_hf_spec_filt_kHz', 'zrange', [1.0e-8, 1.0e-6]
          options, 'ts1_efi_hf_spec_filt_kHz', 'zlog', 1
          options, 'ts1_efi_hf_spec_filt_kHz', 'yrange', [10., 2000.]
          options, 'ts1_efi_hf_spec_filt_kHz', 'x_no_interp', 1
          options, 'ts1_efi_hf_spec_filt_kHz', 'y_no_interp', 1
        endif
      endif ; ts1 EHF
    endif ; level eq 'l2'

    ; ============================================
    ; Level 1b Data Derived Variables
    ; ============================================
    if level eq 'l1b' then begin
      options, 'ts?_l1b_edc*_roi', labflag = 1, labels = ['EX', 'EY', 'EZ'], colors = ['r', 'g', 'b']
      options, 'ts?_l1b_ehf', spec = 1, ylog = 1, zlog = 1

      if (total(spacecraft.contains('ts1')) ge 1) and doeac then begin
        ; eac
        get_data, 'ts1_l1b_eac', data = dat, limit = lim, dlimit = dlim
        ch1 = reform(dat.y[*, 0, *]) ; channel 1
        ch2 = reform(dat.y[*, 1, *]) ; channel 2
        store_Data, 'ts1_l1b_eac_ch1', data = {x: dat.x, y: ch1, v: dat.v}, limit = {spec: 1}, dlimit = dlim
        store_Data, 'ts1_l1b_eac_ch2', data = {x: dat.x, y: ch2, v: dat.v}, limit = {spec: 1}, dlimit = dlim
      endif ; ts1

      if (total(spacecraft.contains('ts2')) ge 1) and doeac then begin
        ; eac
        get_data, 'ts2_l1b_eac', data = dat, limit = lim, dlimit = dlim
        ch1 = reform(dat.y[*, 0, *]) ; channel 1
        ch2 = reform(dat.y[*, 1, *]) ; channel 2
        store_Data, 'ts2_l1b_eac_ch1', data = {x: dat.x, y: ch1, v: dat.v}, limit = {spec: 1, zlog: 1}, dlimit = dlim
        store_Data, 'ts2_l1b_eac_ch2', data = {x: dat.x, y: ch2, v: dat.v}, limit = {spec: 1}, dlimit = dlim
      endif ; ts2

      options, 'ts?_l1b_eac_ch*', spec = 1
    endif ; level eq 'l1b'
  endif ; if filenames are given in string format
end
