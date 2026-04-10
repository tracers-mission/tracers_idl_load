; @'qualcolors'

; -
;+
; :Description:
;   Initialize IDL settings and environments for downloading and plotting TRACERS data
;   includes setting root directory where data will be saved
;
;   also sets username and password for TRACERS data website if a team member.
;
; :Keywords:
;   local_data_dir: in, optional, str
;     Placeholder docs for argument, keyword, or property
;   no_download: bidirectional, optional, any
;     Placeholder docs for argument, keyword, or property
;   remote_data_dir: in, optional, str
;     Placeholder docs for argument, keyword, or property
;   url_password: in, optional, str
;     password (case-sensitive) to get into the TRACERS user portal
;   url_username: in, optional, str
;     username (case-sensitive) to get into the TRACERS user portal
;
; :Notes:
;   - You can directly set your username and password as environment variables on your machine
;     if you don't want to have them in the code, just make sure to set them as 'TRACERS_USER_PASS=username:password'
;     (with a colon between them) and then the code will pull from that.
;     Otherwise, you can just set them in the code here with the setenv line below.
;     set username /password combo to access TRACERS portal
;     setenv, 'TRACERS_USER_PASS=input-your-username:your-password-here'
;
;-
pro tracers_init, url_username = url_username, url_password = url_password, local_data_dir = local_data_dir, remote_data_dir = remote_data_dir, no_download = no_download
  compile_opt idl2

  ; You can directly set your username and password as environment variables on your machine
  ; if you don't want to have them in the code, just make sure to set them as 'TRACERS_USER_PASS=username:password'
  ; (with a colon between them) and then the code will pull from that.
  ; Otherwise, you can just set them in the code here with the setenv line below.
  ; set username /password combo to access TRACERS portal
  ; setenv, 'TRACERS_USER_PASS=input-your-username:your-password-here'

  ; Set data diretory for TRACERS kernels and data - default place to store data
  ; setenv, 'ROOT_DATA_DIR=/Volumes/wvushaverhd/TRACERS_data' ; on external HDD

  ; Check if !tracers already exists.
  defsysv, '!tracers', exists = exists

  ; If !fast does not exist, create !fast.
  if not keyword_set(exists) then begin
    defsysv, '!tracers', file_retrieve(/structure_format)
  endif

  !tracers = file_retrieve(/structure_format)

  !tracers.remote_data_dir = 'https://tracers-portal.physics.uiowa.edu/' ; default remote data directory
  !tracers.local_data_dir = root_data_dir() + 'tracers/'
  if keyword_set(local_data_dir) then !tracers.local_data_dir = local_data_dir
  if keyword_set(remote_data_dir) then !tracers.remote_data_dir = remote_data_dir
  if keyword_set(no_download) then !tracers.no_download = no_download

  if getenv('TRACERS_REMOTE_DATA_DIR') ne '' then $
    !tracers.remote_data_dir = getenv('TRACERS_REMOTE_DATA_DIR')
  if getenv('TRACERS_LOCAL_DATA_DIR') ne '' then $
    !tracers.local_data_dir = getenv('TRACERS_LOCAL_DATA_DIR')

  ; Define TRACERS portal URL and data paths
  ; ---------------------------------------------------
  if undefined(url_username) or undefined(url_password) then begin
    check = getenv('TRACERS_USER_PASS')
    if check eq '' then begin
      print, 'Please input TRACERS url username and password as keywords'
      print, 'If you would like to access the internal teams data.'
      print, 'Otherwise use public data and ignore this message.'
      print, ''
    end else begin
      uspw = strsplit(check, ':', /extract)
      url_username = uspw[0]
      url_password = uspw[1]
    end
  end

  if defined(url_username) and defined(url_password) then begin
    ; set username and password for TRACERS portal access
    setenv, 'TRACERS_USER_PASS=' + url_username + ':' + url_password
    print, 'TRACERS url username and password set'

    ; also change data directory to teams if you have credentials to access that
    !tracers.remote_data_dir = 'https://tracers-portal.physics.uiowa.edu/teams' ; default remote data directory
    if keyword_set(remote_data_dir) then !tracers.remote_data_dir = remote_data_dir
  end

  ; spd_graphics_config.pro ; set some default graphics settings for tplots?
end

; program
