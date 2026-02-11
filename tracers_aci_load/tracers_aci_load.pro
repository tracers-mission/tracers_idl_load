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
;   spacecraft: in, optional, Array<String>
;     ['ts1','ts2'] spacecraft handle to put in file (defaults to 'ts2')
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

  if undefined(local_path) then local_path = '/Volumes/wvushaverhd/TRACERS_data' ; where to save your downloaded data
  if undefined(remote_path) then remote_path = 'https://tracers-portal.physics.uiowa.edu/teams'
  if undefined(spacecraft) then spacecraft = ['ts2'] else spacecraft = [strlowcase(spacecraft)] ; default to ts2
  if undefined(level) then level = ['l2'] else level = strlowcase(level)
  if ~isa(level, /array, /string) then level = [level] ; make sure its an array
  if undefined(version) then version = '**' ; default to latest
  if undefined(revision) then revision = '**' ; default to latest
  if keyword_set(downloadonly) then tplot = 0 else tplot = 1 ; if you want to only download the data, not tplot

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

    if (total(level.contains('l2')) ge 1) then begin ; level 2
      aci_path = '/flight/ACI/' + strlowcase(spacecraft) + '/l2/aci/ipd/' ;+ yyyy + '/' + mm + '/'
      fn_i = ace_path + strlowcase(spacecraft) + '_l2_aci_ipd_' + dates[i] + '_v' + version + '.cdf'

      dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
        url_username = url_username, url_password = url_password)

      ; if user specifies, then return filenames of where the data has been saved to back to the user
      data_filenames = [data_filenames, dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]]
    end ; level 2

    if (total(level.contains('l1a')) ge 1) then begin ; level 1a
      aci_path = '/flight/ACI/' + strlowcase(spacecraft) + '/l1a/aci/ipd/' ;+ yyyy + '/' + mm + '/'
      fn_i = ace_path + strlowcase(spacecraft) + '_l1a_aci_ipd_' + dates[i] + '_v' + version + '.cdf'

      dnld_paths = spd_download(remote_path = remote_path, remote_file = fn_i, local_path = local_path, $
        url_username = url_username, url_password = url_password)

      ; if user specifies, then return filenames of where the data has been saved to back to the user
      data_filenames = [data_filenames, dnld_paths[uniq(dnld_paths[sort(dnld_paths)])]]
    end ; level 3
  endfor ; dates

  if tplot and (total(level.contains('l2')) ge 1) then begin
    dirname = file_dirname(data_filenames, /mark_directory)
    dirname = dirname[0].remove(-8)
    dtmp = strmid(dates, 2)
  end ; tplot
end
