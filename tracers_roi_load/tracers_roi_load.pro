;+
; :Description:
;   FUNCTION:
;     TRACERS_ROI_PARSE
;   PURPOSE:
;     Helper function. Reads a TRACERS ROI CSV file, skips comment lines,
;     and returns all intervals that overlap a given time range as string arrays.
;     Not intended to be called directly - use tracers_roi_load instead.
;
; :Returns: any
;
; :Arguments:
;   filename: in, required, str
;     Full local path to a downloaded ROI CSV file
;   trange: in, required, Double | arr
;     Two-element [tstart, tend] array defining the time window (Unix seconds)
;
; :Notes:
;   Expects CSV columns: Start_Epoch, End_Epoch, Orbit_Num, ROI_Num, Event_Tag
;   Epoch format in file: '2025-11-08T06:15:27' (ISO 8601, T separator)
;   Lines beginning with '#' are skipped (file header comments)
;
;-
function tracers_roi_parse, filename, trange
  compile_opt idl2

  finfo = file_info(filename)
  if ~finfo.exists then begin
    dprint, 'ROI file not found: ' + filename
    return, []
  endif

  ; Read all lines from the file
  openr, lun, filename, /get_lun
  line = ''
  all_lines = list()
  while ~eof(lun) do begin
    readf, lun, line
    all_lines.add, line
  endwhile
  free_lun, lun

  ; Filter out comment lines (# prefix) and blank lines
  data_list = list()
  for i = 0, all_lines.count() - 1 do begin
    l = strtrim(all_lines[i], 2)
    if l eq '' then continue
    if strmid(l, 0, 1) eq '#' then continue
    data_list.add, l
  endfor

  ; Need at least a header row and one data row
  if data_list.count() lt 2 then begin
    dprint, 'No data rows found in: ' + filename
    return, []
  endif

  ; data_list[0] is the column header; data rows start at index 1
  all_data = data_list.toArray()
  nrows = n_elements(all_data) - 1

  tstart_list = list()
  tend_list = list()

  for i = 0, nrows - 1 do begin
    cols = strsplit(all_data[i + 1], ',', /extract)
    if n_elements(cols) lt 2 then continue

    ; Convert ISO 8601 'YYYY-MM-DDTHH:MM:SS' to SPEDAS format 'YYYY-MM-DD/HH:MM:SS'
    t0_str = strjoin(strsplit(strtrim(cols[0], 2), 'T', /extract), '/')
    t1_str = strjoin(strsplit(strtrim(cols[1], 2), 'T', /extract), '/')
    tstart_d = time_double(t0_str)
    tend_d = time_double(t1_str)

    ; Include if any part of the ROI overlaps trange (roi starts before window ends AND ends after window starts)
    if tstart_d lt trange[1] and tend_d gt trange[0] then begin
      tstart_list.add, time_string(tstart_d)
      tend_list.add, time_string(tend_d)
    endif
  endfor

  if tstart_list.count() eq 0 then return, []
  return, {tstart: tstart_list.toArray(), tend: tend_list.toArray()}
end

;+
; :Description:
;   Function: TRACERS_ROI_LOAD
;   Purpose: Download TRACERS Region of Interest (ROI) CSV files from the
;            public ancillary portal and return all ROI intervals that overlap
;            a given time period. Any ROI with even partial overlap is returned
;            in full (i.e. original start and end times, not clipped to trange).
;
; :Returns: Structure
;   Structure with one sub-struct per spacecraft. Each sub-struct contains
;   parallel string arrays of start and end times. Access via:
;     roi_out.ts1.tstart    - string array of TS1 ROI start times
;     roi_out.ts1.tend      - string array of TS1 ROI end times
;     roi_out.ts2.tstart    - string array of TS2 ROI start times
;     roi_out.ts2.tend      - string array of TS2 ROI end times
;     roi_out.tandem.tstart - string array of tandem ROI start times
;     roi_out.tandem.tend   - string array of tandem ROI end times
;   Times are stored as time_string() format (e.g. '2025-11-08/06:15:27').
;   Spacecraft not requested are set to {tstart: [''], tend: ['']} placeholders.
;   Use n_elements(roi_out.ts1.tstart) and check roi_out.ts1.tstart[0] ne ''
;   to determine whether any ROIs were found for a given spacecraft.
;   Returns !null on download-only or invalid-spacecraft calls.
;
; :Keywords:
;   downloadonly: in, optional, Boolean
;     If set, downloads CSV file(s) but does not parse; returns !null.
;   local_path: in, optional, str
;     Local directory to save downloaded CSV files.
;     Defaults to '/Volumes/wvushaverhd/TRACERS_data'
;   remote_path: in, optional, str
;     Base URL override. Defaults to 'https://tracers-portal.physics.uiowa.edu'
;   spacecraft: in, optional, str | or | arr
;     Which spacecraft ROIs to retrieve. Can be a scalar string or an array:
;       'all'                       - TS1, TS2, and tandem ROIs (default)
;       'ts1'                       - TS1 ROIs only
;       'ts2'                       - TS2 ROIs only
;       'both'                      - TS1 and TS2 ROIs (no tandem)
;       'tandem'                    - intervals when both spacecraft are taking data simultaneously
;       ['ts1', 'ts2', 'tandem']    - any combination as a string array
;   trange: in, optional, str | or | Double | arr
;     Two-element time range [t0, t1]. If not set, uses SPEDAS timerange().
;   verbose: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;
; :Examples:
;   timespan, '2025-11-08', 3
;   rois = tracers_roi_load()
;   print, rois.ts1.tstart              ; all TS1 start times in the window
;   print, rois.ts2.tend                ; all TS2 end times in the window
;   print, rois.tandem.tstart           ; all tandem start times in the window
;
;   rois = tracers_roi_load(spacecraft='ts1', trange=['2025-11-08', '2025-11-12'])
;   n = n_elements(rois.ts1.tstart)
;   for i = 0, n - 1 do print, rois.ts1.tstart[i], ' -- ', rois.ts1.tend[i]
;
;   rois = tracers_roi_load(spacecraft='tandem')
;   print, rois.tandem.tstart
;
;   rois = tracers_roi_load(spacecraft=['ts1', 'ts2', 'tandem'])
;
; :Created by:
;   Sky Shaver    Apr 2026
;
; :Dependencies:
;   tracers_roi_parse - helper function defined above in this file
;
; :Spedas dependencies:
;   spd_download  - downloads ROI CSV files (no authentication required)
;   timerange     - gets current time window when trange keyword not provided
;   time_double   - converts string timestamps to double for overlap comparison
;   time_string   - stores ROI times in output struct and formats printed output
;   undefined     - checks whether optional keywords were supplied
;   dprint        - debug/warning printing
;
;-
function tracers_roi_load, spacecraft = spacecraft, trange = trange, $
  local_path = local_path, remote_path = remote_path, $
  downloadonly = downloadonly, verbose = verbose
  compile_opt idl2

  if undefined(spacecraft) then spacecraft = ['all'] else spacecraft = strlowcase(spacecraft)
  if ~isa(spacecraft, /array) then spacecraft = [spacecraft] ; normalize scalar to array
  if undefined(local_path) then local_path = '/Volumes/wvushaverhd/TRACERS_data'
  if undefined(remote_path) then remote_path = 'https://tracers-portal.physics.uiowa.edu'
  if undefined(verbose) then verbose = 0

  if undefined(trange) then trange = timerange() else trange = time_double(trange)

  ; Remote file paths on the public ancillary portal (no authentication needed)
  ts1_remote = '/ancillary/TS1/events/roi_intervals/ts1_roi-list.csv'
  ts2_remote = '/ancillary/TS2/events/roi_intervals/ts2_roi-list.csv'
  tandem_remote = '/ancillary/events/tandem_rois.csv'

  ; max(array eq 'value') returns 1 if any element matches, 0 otherwise
  do_ts1 = max(spacecraft eq 'ts1') or max(spacecraft eq 'both') or max(spacecraft eq 'all')
  do_ts2 = max(spacecraft eq 'ts2') or max(spacecraft eq 'both') or max(spacecraft eq 'all')
  do_tandem = max(spacecraft eq 'tandem') or max(spacecraft eq 'all')

  if ~do_ts1 and ~do_ts2 and ~do_tandem then begin
    dprint, 'Invalid spacecraft keyword [''' + strjoin(spacecraft, ''', ''') + ''']. Use ''all'', ''ts1'', ''ts2'', ''both'', ''tandem'', or an array combination.'
    return, !null
  endif

  ; Download requested files (public portal - no username/password needed)
  ts1_file = ''
  ts2_file = ''
  tandem_file = ''

  if do_ts1 then begin
    dnld = spd_download(remote_path = remote_path, remote_file = ts1_remote, local_path = local_path)
    if dnld[0] ne '' then ts1_file = dnld[0] $
    else dprint, 'Could not download TS1 ROI file from ' + remote_path + ts1_remote
  endif

  if do_ts2 then begin
    dnld = spd_download(remote_path = remote_path, remote_file = ts2_remote, local_path = local_path)
    if dnld[0] ne '' then ts2_file = dnld[0] $
    else dprint, 'Could not download TS2 ROI file from ' + remote_path + ts2_remote
  endif

  if do_tandem then begin
    dnld = spd_download(remote_path = remote_path, remote_file = tandem_remote, local_path = local_path)
    if dnld[0] ne '' then tandem_file = dnld[0] $
    else dprint, 'Could not download tandem ROI file from ' + remote_path + tandem_remote
  endif

  if keyword_set(downloadonly) then return, !null

  ; Parse requested files - each returns {tstart: str_arr, tend: str_arr} or [] if no matches
  ; Fields not requested stay as empty placeholders
  empty = {tstart: [''], tend: ['']}
  ts1_result = empty
  ts2_result = empty
  tandem_result = empty

  if do_ts1 and ts1_file ne '' then begin
    tmp = tracers_roi_parse(ts1_file, trange)
    if n_elements(tmp) gt 0 then ts1_result = tmp
  endif

  if do_ts2 and ts2_file ne '' then begin
    tmp = tracers_roi_parse(ts2_file, trange)
    if n_elements(tmp) gt 0 then ts2_result = tmp
  endif

  if do_tandem and tandem_file ne '' then begin
    tmp = tracers_roi_parse(tandem_file, trange)
    if n_elements(tmp) gt 0 then tandem_result = tmp
  endif

  ; Build output struct - access as roi_out.ts1.tstart, roi_out.ts2.tend, etc.
  roi_out = {ts1: ts1_result, ts2: ts2_result, tandem: tandem_result}

  ; Count matches per spacecraft (0 if placeholder)
  n1 = ts1_result.tstart[0] ne '' ? n_elements(ts1_result.tstart) : 0
  n2 = ts2_result.tstart[0] ne '' ? n_elements(ts2_result.tstart) : 0
  nt = tandem_result.tstart[0] ne '' ? n_elements(tandem_result.tstart) : 0

  if n1 + n2 + nt eq 0 then $
    dprint, 'No ROI intervals found within the requested time range.'

  if verbose then begin
    ; Print summary
    print, strtrim(n1 + n2 + nt, 2) + ' ROI interval(s) found:'
    for i = 0, n1 - 1 do print, '  [ts1]    ' + ts1_result.tstart[i] + '  -->  ' + ts1_result.tend[i]
    for i = 0, n2 - 1 do print, '  [ts2]    ' + ts2_result.tstart[i] + '  -->  ' + ts2_result.tend[i]
    for i = 0, nt - 1 do print, '  [tandem] ' + tandem_result.tstart[i] + '  -->  ' + tandem_result.tend[i]
  endif

  return, roi_out
end
