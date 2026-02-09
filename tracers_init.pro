; @'qualcolors'

; -
;+
; :Description:
;   Initialize IDL settings and environments for downloading and plotting TRACERS data
;   includes setting root directory where data will be saved
;
;   also sets username and password for TRACERS data website.
;
;-
pro tracers_init
  compile_opt idl2

  ; Set data diretory for TRACERS kernels and data - default place to store data
  setenv, 'ROOT_DATA_DIR=/Volumes/wvushaverhd/TRACERS_data' ; on external HDD
  print, 'TRACERS data directory set to: ' + getenv('ROOT_DATA_DIR')

  ; set username /password combo to access TRACERS portal
  setenv, 'TRACERS_USER_PASS=input-your-username:your-password-here'

  ; spd_graphics_config.pro ; set some default graphics settings for tplots?
end

; program
