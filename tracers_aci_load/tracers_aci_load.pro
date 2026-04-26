;+
; :Description:
;   download L2 ACI data from TRACERS website
;
; :Keywords:
;   data_filenames: in, optional, Array<String>
;     string array containing path and file names where ACE data is saved on local machine
;   downloadonly: in, optional, any
;     if set, will only load in data - not create tplot variables
;   level: bidirectional, optional, Array<String>
;     ['l1a','l2']
;     level of data to put into file (defaults to l2)
;   local_path: in, optional, str
;     Directory path on your local device where downloaded files will be saved
;   remote_path: in, optional, str
;     Directory path for EFI files (default 'https://tracers-portal.physics.uiowa.edu/teams')
;   revision: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;   spacecraft: in, optional, str | Array<String>
;     ['ts1','ts2','both']
;     spacecraft to load (defaults to 'ts2'); 'both' or ['ts1','ts2'] loads both spacecraft
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
;-
pro tracers_aci_load, remote_path = remote_path, local_path = local_path, $
  downloadonly = downloadonly, trange = trange, $
  level = level, spacecraft = spacecraft, version = version, revision = revision, $
  url_username = url_username, url_password = url_password, $
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
  if undefined(spacecraft) then spacecraft = ['ts2'] else begin
    spacecraft = strlowcase(spacecraft)
    if n_elements(spacecraft) eq 1 and spacecraft[0] eq 'both' then spacecraft = ['ts1', 'ts2'] $
    else spacecraft = [spacecraft]
  endelse
  if undefined(level) then level = ['l2'] else level = strlowcase(level)
  if ~isa(level, /array, /string) then level = [level] ; make sure its an array
  if undefined(version) then version = '**' ; default to latest
  if undefined(revision) then revision = '**' ; default to latest
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

  if undefined(trange) then trange = timerange() else trange = time_double(trange)

  days = ceil((trange[1] - trange[0]) / (24. * 3600))
  t0 = time_double(strmid(time_string(trange[0]), 0, 10))
  dates = time_string(t0 + indgen(days) * 24.d * 3600, format = 6) ; YYYYMMDDHHMMSS
  dates = strmid(dates, 0, 8) ; YYYYMMDD
  ndates = n_elements(dates)

  data_filenames = []

  for isc = 0, n_elements(spacecraft) - 1 do begin ; spacecraft loop
    sc = spacecraft[isc]
    sc_filenames = []

    for i = 0, ndates - 1 do begin
      print, '...'
      ; print, 'Reading File for Date: ', dates[i]
      print, 'Fetching File for Date: ', dates[i]
      print, '...'

      yyyy = strmid(dates[i], 0, 4)
      mm = strmid(dates[i], 4, 2)
      dd = strmid(dates[i], 6, 2)

      if (total(level.contains('l2')) ge 1) then begin ; level 2
        fn_basename = sc + '_l2_aci_ipd_' + dates[i] + '_v' + version + '.cdf'

        if has_credentials then begin
          aci_path = '/flight/ACI/' + sc + '/l2/aci/ipd/'
          fn_i = aci_path + fn_basename
          dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
            url_username = url_username, url_password = url_password)
        endif else begin
          pub_path = '/L2/' + strupcase(sc) + '/' + yyyy + '/' + mm + '/' + dd + '/'
          pub_fn = pub_path + fn_basename
          dnld_paths = spd_download(remote_path = public_base, remote_file = pub_fn, local_path = local_path)
          if dnld_paths[0] eq '' then begin
            print, 'WARNING: Public L2 ACI file not available: ' + fn_basename
            print, '  Public data may not yet be released for this date.'
            print, '  To access teams data, set credentials via tracers_init (url_username and url_password keywords).'
          endif
        endelse

        sc_filenames = [sc_filenames, dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]]

        if tplot then tracers_aci_tplot, dnld_paths, spacecraft = sc
      end ; level 2

      if (total(level.contains('l1b')) ge 1) then begin ; level 1b
        print, ''
        print, 'WARNING: L1B data is not intended for science use or publications.'
        print, 'Please use L2 data for science analysis. Continuing in 3 seconds...'
        print, ''
        wait, 3
        aci_path = '/flight/SOC/' + strupcase(sc) + '/L1B/ACI/' + yyyy + '/' + mm + '/' + dd + '/'
        fn_i = aci_path + sc + '_l1b_aci_ipd_x*_' + dates[i] + '_v' + version + '.cdf' ; ipd

        dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
          url_username = url_username, url_password = url_password)

        sc_filenames = [sc_filenames, dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]]
      end ; level 1b

      if (total(level.contains('l1a')) ge 1) then begin ; level 1a
        print, ''
        print, 'WARNING: L1A data is not intended for science use or publications.'
        print, 'Please use L2 data for science analysis. Continuing in 3 seconds...'
        print, ''
        wait, 3
        aci_path = '/flight/ACI/' + sc + '/l1a/aci/ipd/'
        fn_i = aci_path + sc + '_l1a_aci_ipd_' + dates[i] + '_v' + version + '.cdf'

        dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
          url_username = url_username, url_password = url_password)

        sc_filenames = [sc_filenames, dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]]
      end ; level 1a
    endfor ; loop over dates

    data_filenames = [data_filenames, sc_filenames]
  endfor ; spacecraft loop
end
