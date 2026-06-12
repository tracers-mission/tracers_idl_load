;+
; :Description:
;   download L2 MSC (magnetic search coil) data from TRACERS website
;
; :Keywords:
;   data_filenames: in, optional, Array<String>
;     string array containing path and file names where MSC data is saved on local machine
;   downloadonly: in, optional, any
;     if set, will only download data - not create tplot variables
;   level: bidirectional, optional, str
;     level of data to load (defaults to 'l2'; only 'l2' currently supported)
;   local_path: in, optional, str
;     Directory path on your local device where downloaded files will be saved
;   remote_path: in, optional, str
;     Directory path for MSC files (default 'https://tracers-portal.physics.uiowa.edu')
;   revision: bidirectional, optional, any
;     revision version of data to download, default to latest
;   spacecraft: in, optional, str | Array<String>
;     ['ts1','ts2','both']
;     spacecraft to load (defaults to 'ts2'); 'both' or ['ts1','ts2'] loads both spacecraft
;   trange: in, optional, str | or | Double | arr
;     load data for all files within a given range (one day granularity,
;     supercedes file list, if not set then 'timerange' will be called)
;   url_password: in, optional, str
;     password (case-sensitive) to get into the TRACERS user portal
;   url_username: in, optional, str
;     username (case-sensitive) to get into the TRACERS user portal
;   version: in, optional, str
;     software version number to put in file (defaults to most recent)
;
; :Notes:
;   Private (teams) path:
;     /flight/MSC/[sc]/l2/YYYY/MM/[sc]_l2_msc_bac_YYYYMMDD_v***.cdf
;   Public path (used when credentials are not set):
;     /L2/[SC]/YYYY/MM/DD/[sc]_l2_msc_bac_YYYYMMDD_v***.cdf
;
; :Requirements:
;   - get_highest_version.pro from ACE load routines
;
;-
pro tracers_msc_load, remote_path = remote_path, local_path = local_path, $
  downloadonly = downloadonly, trange = trange, $
  level = level, spacecraft = spacecraft, version = version, revision = revision, $
  url_username = url_username, url_password = url_password, $
  data_filenames = data_filenames
  compile_opt idl2

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
  if undefined(level) then level = 'l2' ; only l2 currently supported
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
      print, 'Fetching File for Date: ', dates[i]
      print, '...'

      yyyy = strmid(dates[i], 0, 4)
      mm = strmid(dates[i], 4, 2)
      dd = strmid(dates[i], 6, 2)

      fn_basename = sc + '_l2_msc_bac_' + dates[i] + '_v' + version + '.cdf'

      if has_credentials then begin
        msc_path = '/flight/MSC/' + sc + '/l2/' + yyyy + '/' + mm + '/'
        fn_i = msc_path + fn_basename
        dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
          url_username = url_username, url_password = url_password)
      endif else begin
        pub_path = '/L2/' + strupcase(sc) + '/' + yyyy + '/' + mm + '/' + dd + '/'
        pub_fn = pub_path + fn_basename
        dnld_paths = spd_download(remote_path = public_base, remote_file = pub_fn, local_path = local_path)
        if dnld_paths[0] eq '' then begin
          print, 'WARNING: Public L2 MSC file not available: ' + fn_basename
          print, '  Public data may not yet be released for this date.'
          print, '  To access teams data, set credentials via tracers_init (url_username and url_password keywords).'
        endif
      endelse

      dnld_paths = dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]
      sc_filenames = [sc_filenames, dnld_paths]

      if tplot then tracers_msc_tplot, dnld_paths, spacecraft = sc, level = level
    endfor ; loop over dates

    data_filenames = [data_filenames, sc_filenames]
  endfor ; spacecraft loop
end
