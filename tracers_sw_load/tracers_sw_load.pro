;+
; :Description:
;   Load solar wind data from the TRACERS website
;
; :Keywords:
;   data_filenames: in, optional, str
;     string array of where data filenames are stored
;   downloadonly: bidirectional, optional, Boolean
;     set keyword if no tplot is wanted
;   local_path: bidirectional, optional, str
;     where to save data onto local machine e.g. home directory or external hard drive)
;   remote_path: bidirectional, optional, str
;     TRACERS website
;   revision: bidirectional, optional, str
;     revision version of data to download, default to latest
;   trange: bidirectional, optional, double or str
;     array containing dates/times to search for data on website (e.g. from timespan)
;   url_password: bidirectional, optional, str
;     password for TRACERS website
;   url_username: bidirectional, optional, str
;     username to TRACERS website
;   version: bidirectional, optional, str
;     version of data to download, default to latest
;
; :Notes:
;   Written by SRS Jan 2026
;   Updates
;
;-
pro tracers_sw_load, remote_path = remote_path, local_path = local_path, $
  downloadonly = downloadonly, trange = trange, $
  url_username = url_username, url_password = url_password, $
  version = version, revision = revision, $
  data_filenames = data_filenames
  compile_opt idl2

  defsysv, '!tracers', exists = tracers_exists
  if ~tracers_exists then begin
    print, 'ERROR: TRACERS environment not initialized. Please run tracers_init to initialize the IDL environment for TRACERS work.'
    return
  endif
  if undefined(local_path) then local_path = !tracers.local_data_dir
  if undefined(remote_path) then remote_path = !tracers.remote_data_dir
  if keyword_set(downloadonly) then tplot = 0 else tplot = 1 ; if you want to only download the data, not tplot
  if undefined(version) then version = '**' ; default to latest
  if undefined(revision) then revision = '**' ; default to latest

  if undefined(url_username) or undefined(url_password) then begin
    check = getenv('TRACERS_USER_PASS')
    if check eq '' then begin
      print, 'Please input TRACERS url username and password as keywords'
      print, 'Returning...'
      print, ''
      return
    end else begin
      uspw = strsplit(check, ':', /extract)
      url_username = uspw[0]
      url_password = uspw[1]
    end
  end

  if undefined(trange) then trange = timerange() else trange = time_double(trange)

  days = ceil((trange[1] - trange[0]) / (24. * 3600))
  t0 = time_double(strmid(time_string(trange[0]), 0, 10))
  dates = time_string(t0 + indgen(days) * 24.d * 3600, format = 6) ; YYYYMMDDHHMMSS
  dates = strmid(dates, 0, 8) ; YYYYMMDD
  ndates = n_elements(dates)

  data_filenames = []

  for i = 0, ndates - 1 do begin
    print, '...'
    ; print, 'Reading File for Date: ', dates[i]
    print, 'Fetching File for Date: ', dates[i]
    print, '...'

    yyyy = strmid(dates[i], 0, 4)
    mm = strmid(dates[i], 4, 2)
    dd = strmid(dates[i], 6, 2)

    sw_path = '/flight/SOC/ancillary/solarwind/'
    fn_i = sw_path + 'swpc_sw_' + dates[i] + '_v' + version + '.cdf'
    dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
      url_username = url_username, url_password = url_password)

    ; if user specifies, then return filenames of where the data has been saved to back to the user
    data_filenames = [data_filenames, dnld_paths]
  endfor ; dates

  if tplot then begin
    tracers_sw_tplot, data_filenames
  end ; tplot solar wind data
end
