;+
; :Description:
;   Procedure: TRACERS_EFI_LOAD
;   Purpose: Load TRACERS electric fields instrument data to local machine
;
; :Arguments:
;   files: in, optional, any
;     An array of filenames containing data, by default just the dates in 'YYYYMMDD' format
;       (not needed if timespan is set)
;
; :Keywords:
;   data_filenames: in, optional, Array<String>
;     string array containing path and file names where ACE data is saved on local machine
;   datatype: in, optional, str arr
;     ['eac', 'edc', 'edc-bor', 'edc-roi', 'ehf', 'hsk', 'vdc-bor', 'vdc-roi']
;     datatype handle for file (defaults to all datatypes)
;   downloadonly: in, optional, any
;     if set, will only load in data - not create tplot variables
;   instrument: in, optional, Array<String>
;     'efi'
;     instrument handle to put into file ('efi')
;   level: in, optional, str
;     ['l2','l1a', 'l1b']
;     level of data to put into file (defaults to l2)
;   local_path: in, optional, str
;     Directory path on your local device where downloaded files will be saved
;   no_server: in, optional, Boolean
;     if set, will not go looking for files remotely (not operational yet!!)
;   remote_path: in, optional, str
;     Directory path for EFI files (default 'https://tracers-portal.physics.uiowa.edu/teams')
;   revision: in, optional, str
;     data version number to put in file (defaults to most recent)
;   spacecraft: in, optional, Array<String>
;     ['ts1','ts2']
;     spacecraft handle to put in file (defaults to 'ts2')
;   trange: in, optional, str or double arr
;     load data for all files within a given range (one day granularity,
;     supercedes file list, if not set then 'timerange' will be called)
;   url_password: in, optional, str
;     password (case-sensitive) to get into the TRACERS user portal
;   url_username: in, optional, str
;     username (case-sensitive) to get into the TRACERS user portal
;   version: in, optional, str
;     software version number to put in file (defaults to most recent)
;
; :Note to friends!:
;   Change the undefined local path variable to whereever you want to place your TRACERS data!
;
; :Future plans:
;   - update datatypes to load in a given called datatype, currently loads all
;   - update tplot section to make tplot work
;     - input files keyword to specify if full filename is given or just dates
;
; :Examples:
;
;   timespan, '2025-09-26', 1 ; one day of data
;   tracers_efi_load, local_path='/Users/SkyShaver/Data/TRACERS_data/' ; loads l2 data for the time span given to your specified local path
;   tracers_efi_load, level ='l1a' ; loads level 1A data for the time span given
;   tracers_efi_load, level ='l1b' ; loads level 1B data for the time span given
;
; :Created by:
;   Sky Shaver    Nov 2025
;
;-
pro tracers_efi_load, files, remote_path = remote_path, local_path = local_path, $
  downloadonly = downloadonly, trange = trange, no_server = no_server, $
  level = level, spacecraft = spacecraft, instrument = instrument, version = version, revision = revision, $
  datatype = datatype, url_username = url_username, url_password = url_password, $
  data_filenames = data_filenames
  compile_opt idl2

  ; timespan, '2025-09-26', 2

  defsysv, '!tracers', exists = tracers_exists
  if ~tracers_exists then begin
    print, 'ERROR: TRACERS environment not initialized. Please run tracers_init to initialize the IDL environment for TRACERS work.'
    return
  endif
  if undefined(local_path) then local_path = !tracers.local_data_dir
  if undefined(remote_path) then remote_path = !tracers.remote_data_dir
  if undefined(spacecraft) then spacecraft = ['ts2'] else spacecraft = [strlowcase(spacecraft)] ; default to ts2
  if undefined(level) then level = 'l2' else level = strlowcase(level)
  if undefined(instrument) then instrument = 'EFI' else instrument = strupcase(instrument)
  if undefined(version) then version = '**' ; default to latest
  if undefined(revision) then revision = '**' ; default to latest
  if undefined(datatype) then datatype = 'all'
  if keyword_set(downloadonly) then tplot = 0 else tplot = 1 ; if you want to only download the data, not tplot

  has_credentials = 0
  if undefined(url_username) or undefined(url_password) then begin
    check = getenv('TRACERS_USER_PASS')
    if check ne '' then begin
      uspw = strsplit(check, ':', /extract)
      url_username = uspw[0]
      url_password = uspw[1]
      has_credentials = 1
    endif
  endif else has_credentials = 1
  public_base = 'https://tracers-portal.physics.uiowa.edu'

  nfiles = n_elements(files) ; getting the dates

  if nfiles eq 0 then begin
    trange = timerange()
    days = ceil((trange[1] - trange[0]) / (24. * 3600))
    t0 = time_double(strmid(time_string(trange[0]), 0, 10))
    dates = time_string(t0 + indgen(days) * 24.d * 3600, format = 6) ; YYYYMMDDHHMMSS
    files = strmid(dates, 0, 8) ; YYYYMMDD
    nfiles = n_elements(files)
  endif else begin ; if user inputs filenames
    files = file_basename(files) ; just the base filename
    ; need to find the dates within the filenames
    ; for now, assume user inputs dates in 'YYYYMMDD' format
  end

  ; ; definining constants
  ; ; spacecraft names
  ; sc_names = 'ts1 ts2'
  ; datatype names
  d_names_l2 = ['edc-roi', 'edc', 'ehf', 'vdc', 'hsk', 'eac']
  d_names_l1a = ['eac', 'edc-bor', 'edc-roi', 'ehf', 'vdc-bor', 'vdc-roi']
  d_names_l1b = ['eac', 'edc-bor', 'edc-roi', 'ehf', 'hsk', 'vdc-bor', 'vdc-roi']

  data_filenames = []

  for i = 0, nfiles - 1 do begin
    print, '...'
    ; print, 'Reading File for Date: ', files[i]
    print, 'Fetching File for Date: ', files[i]
    print, '...'

    yyyy = strmid(files[i], 0, 4)
    mm = strmid(files[i], 4, 2)
    dd = strmid(files[i], 6, 2)

    if (datatype eq 'all') and (level eq 'l2') then d_names = d_names_l2
    if (datatype eq 'all') and (level eq 'l1b') then d_names = d_names_l1b
    if (datatype eq 'all') and (level eq 'l1a') then d_names = d_names_l1a

    if n_elements(d_names) eq 1 then d_names = [d_names] ; make sure its an array

    indx = where(strmatch(d_names, 'edc'), nedc)
    if (nedc gt 0) then doedc = 1 else doedc = 0
    indx = where(strmatch(d_names, 'edc-roi'), nedcroi)
    if (nedcroi gt 0) then doedcroi = 1 else doedcroi = 0
    indx = where(strmatch(d_names, 'edc-bor'), nedcbor)
    if (nedcbor gt 0) then doedcbor = 1 else doedcbor = 0
    indx = where(strmatch(d_names, 'ehf'), nehf)
    if (nehf gt 0) then doehf = 1 else doehf = 0
    indx = where(strmatch(d_names, 'vdc-roi'), nvdcroi)
    if (nvdcroi gt 0) then dovdcroi = 1 else dovdcroi = 0
    indx = where(strmatch(d_names, 'vdc-bor'), nvdcbor)
    if (nvdcbor gt 0) then dovdcbor = 1 else dovdcbor = 0
    indx = where(strmatch(d_names, 'vdc'), nvdc)
    if (nvdc gt 0) then dovdc = 1 else dovdc = 0
    indx = where(strmatch(d_names, 'hsk'), nhsk)
    if (nhsk gt 0) then dohsk = 1 else dohsk = 0
    indx = where(strmatch(d_names, 'eac'), neac)
    if (neac gt 0) then doeac = 1 else doeac = 0

    ; ----------------------------
    ; Level 2 data files
    ; ----------------------------
    if level eq 'l2' then begin ; level 2 data
      ; build filenames with lowercase instrument token (correct for both teams and public portal)
      instr_lower = strlowcase(instrument)
      fn_basenames = []
      if doedc    then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_edc_'     + mm + dd + yyyy + '_v' + version + '.cdf'] ; edc uses MMDDYYYY
      if doedcroi then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_edc-roi_' + files[i]      + '_v' + version + '.cdf']
      if doehf    then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_ehf_'     + files[i]      + '_v' + version + '.cdf']
      if dovdc    then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_vdc_'     + files[i]      + '_v' + version + '.cdf']
      if dohsk    then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_hsk_'     + files[i]      + '_v' + version + '.cdf']
      if doeac    then fn_basenames = [fn_basenames, spacecraft + '_l2_' + instr_lower + '_eac_'     + files[i]      + '_v' + version + '.cdf']

      if has_credentials then begin
        ; teams portal: uppercase instrument in folder path, lowercase in filename
        teams_path = '/flight/' + instrument + '/' + level + '/' + spacecraft + '/' + yyyy + '/' + mm + '/' + dd + '/'
        fn_arr = teams_path + fn_basenames
        dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_arr, local_path = local_path, $
          url_username = url_username, url_password = url_password)
      endif else begin
        ; public portal: /L2/{SC}/{YYYY}/{MM}/{DD}/
        pub_path = '/L2/' + strupcase(spacecraft) + '/' + yyyy + '/' + mm + '/' + dd + '/'
        pub_fn_arr = pub_path + fn_basenames
        dnld_paths = spd_download(remote_path = public_base, remote_file = pub_fn_arr, local_path = local_path)
        for j = 0, n_elements(pub_fn_arr) - 1 do begin
          if dnld_paths[j] eq '' then begin
            print, 'WARNING: Public L2 EFI file not available: ' + file_basename(pub_fn_arr[j])
            print, '  Public data may not yet be released for this date.'
            print, '  To access teams data, set credentials via tracers_init (url_username and url_password keywords).'
          endif
        endfor
      endelse
    end ; loading level 2 data

    ; ----------------------------
    ; Level 1B data files
    ; ----------------------------
    if level eq 'l1b' then begin ; loading level 1b data
      print, ''
      print, 'WARNING: L1B data is not intended for science use or publications.'
      print, 'Please use L2 data for science analysis. Continuing in 3 seconds...'
      print, ''
      wait, 3
      instrument_path = '/flight/SOC/' + strupcase(spacecraft) + '/' + strupcase(level) + '/' + instrument + '/' + yyyy + '/' + mm + '/' + dd + '/'

      fn_arr = []

      if doeac then eac_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_eac_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; eac
      if doeac then fn_arr = [fn_arr, eac_fn]
      if doedc then edc_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_edc_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; edc
      if doedc then fn_arr = [fn_arr, edc_fn]
      if doedcbor then edcbor_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_edc-bor_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; edc-bor
      if doedcbor then fn_arr = [fn_arr, edcbor_fn]
      if doedcroi then edcroi_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_edc-roi_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; edc-roi
      if doedcroi then fn_arr = [fn_arr, edcroi_fn]
      if doehf then ehf_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_ehf_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; ehf
      if doehf then fn_arr = [fn_arr, ehf_fn]
      if dohsk then hsk_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_hsk_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; hsk
      if dohsk then fn_arr = [fn_arr, hsk_fn]
      if dovdcbor then vdcbor_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_vdc-bor_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; vdc-bor
      if dovdcbor then fn_arr = [fn_arr, vdcbor_fn]
      if dovdcroi then vdcroi_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_vdc-roi_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; vdc-roi
      if dovdcroi then fn_arr = [fn_arr, vdcroi_fn]
      if dovdc then vdc_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_vdc_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; vdc
      if dovdc then fn_arr = [fn_arr, vdc_fn]

      ; [eac_fn, edcbor_fn, edcroi_fn, ehf_fn, hsk_fn, vdcbor_fn, vdcroi_fn]
      dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_arr, local_path = local_path, $
        url_username = url_username, url_password = url_password)
    end ; loading level 1b data

    ; ---------------------------
    ; Level 1A data files
    ; ---------------------------
    if level eq 'l1a' then begin ; fetch level 1a data
      print, ''
      print, 'WARNING: L1A data is not intended for science use or publications.'
      print, 'Please use L2 data for science analysis. Continuing in 3 seconds...'
      print, ''
      wait, 3

      instrument_path = '/flight/SOC/' + strupcase(spacecraft) + '/' + strupcase(level) + '/' + instrument + '/' + yyyy + '/' + mm + '/' + dd + '/'
      fn_arr = []

      if doeac then eac_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_eac_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; eac
      if doeac then fn_arr = [fn_arr, eac_fn]
      if doedcbor then edcbor_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_edc-bor_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; edc-bor
      if doedcbor then fn_arr = [fn_arr, edcbor_fn]
      if doedcroi then edcroi_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_edc-roi_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; edc-roi
      if doedcroi then fn_arr = [fn_arr, edcroi_fn]
      if doehf then ehf_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_ehf_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; ehf
      if doehf then fn_arr = [fn_arr, ehf_fn]
      if dohsk then hsk_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_hsk_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; hsk
      if dohsk then fn_arr = [fn_arr, hsk_fn]
      if dovdcbor then vdcbor_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_vdc-bor_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; vdc-bor
      if dovdcbor then fn_arr = [fn_arr, vdcbor_fn]
      if dovdcroi then vdcroi_fn = instrument_path + spacecraft + '_' + level + '_' + instrument + '_vdc-roi_' + 'x**_' + files[i] + '_v' + version + '.cdf' ; vdc-roi
      if dovdcroi then fn_arr = [fn_arr, vdcroi_fn]

      ; [eac_fn, edcbor_fn, edcroi_fn, ehf_fn, hsk_fn, vdcbor_fn, vdcroi_fn]
      dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_arr, local_path = local_path, $
        url_username = url_username, url_password = url_password)
    end ; fetch level 1a data

    ; if user specifies, then return filenames of where the data has been saved to back to the user
    data_filenames = [data_filenames, dnld_paths]

    ; THIS TPLOT SECTION IS STILL BEING WORKED ON! This will load the files into tplot variables,
    ; but the times are off!
    ;

    if tplot then begin
      tracers_efi_tplot, data_filenames, spacecraft = spacecraft, level = level

      ; ; check time range
      ; if keyword_set(trange) then begin
      ; tr = timerange()
      ; tplot_names, names = tvars
      ; if n_elements(tvars) eq 0 then tvars = [''] ; if no tplot variables, make it an array with one empty string to avoid errors
      ; itmp = where(tvars.contains(strlowcase(instrument)), ncounts, /null)
      ; if n_elements(tr) eq 2 and (tvars[0] gt '') and (ncounts gt 0) then begin
      ; time_clip, tnames(tvars[itmp]), trange[0], trange[1], /replace
      ; end
      ; end ; clip time to desired range
    endif ; tplot
  endfor ; over dates/files
end

; program
