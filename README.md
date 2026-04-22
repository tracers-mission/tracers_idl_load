# TRACERS IDL Load Routines

IDL load routines for the TRACERS mission, designed to follow SPEDAS
conventions for data download and loading. These routines are regularly updated, so check back often!

## Features
- Automatic data download
- Configurable local data directories
- Support for multiple data products and levels
- SPEDAS-compatible naming

## Requirements
- IDL 
- SPEDAS routines (e.g. `tplot`) from [SPEDAS wiki here](https://spedas.org/wiki/index.php?title=Downloads_and_Installation)
- (optional) IDL-colorbars routines (e.g. `loadcv`) from planetarymike [github repo here](https://github.com/planetarymike/IDL-Colorbars)

## Notes
- You will need to update the tracers_init.pro before running any of this code!!
- Can only load in one spacecraft at a time (TS1 or TS2)

## Future Capabilities?
- MAG, MSC, MAGIC
- Email Sky with what you want! <skylar.shaver@mail.wvu.edu>

## Contributors
A special thank you to contributors to this code: Dr. John Bonnell, Dr. Marit Oieroset, Dr. Jasper Halekas, Dr. Katy Goodrich, Dr. Sarah Henderson, and others!

## Basic Usage
```idl

; Initialize the IDL Session for TRACERS
;----------------------------------------------

; Update the tracers_init file to your benefit! (do this only once, or if you'd like to reset the session)
tracers_init
tracers_init, url_username='team-username', url_password='team-password'
tracers_init, local_data_dir='path/to/my/external/harddrive/', remote_data_dir='https://tracers-portal.physics.uiowa.edu/'

; Set time span you'd like to get data for
timespan, '2025-09-26', 1 ; one day of data

; Load time spans where TS1, TS2, and tandem measurements fall 
; within the region of interest (ROI)
;-----------------------------------
rois = tracers_roi_load() ; returns structure
print, rois.ts1.tstart ; all TS1 start times in the window
print, rois.ts1.tstart[0] + '  -->  ' + rois.ts1.tend[0] ; one ROI timespan
print, rois.ts2.tend ; all TS2 end times in the window
print, rois.tandem.tstart ; all tandem start times in the window

; EFI Load Routine
;-----------------------------------
tracers_efi_load, local_path = '/Users/SkyShaver/Data/TRACERS_data/' ; loads l2 data for the time span given to your specified local path
tracers_efi_load, local_path = '/Volumes/MyExternalHardDrive/TRACERS_data/' ; loads l2 data for the time span given to your specified local path on external HDD
tracers_efi_load, url_username = 'tracers-username', url_password = 'tracers-password' ; use these keywords if you havent set the 'TRACERS_USER_PASS' environment variable with tracers_init.pro

tracers_efi_load, spacecraft='ts1', level='l1b', datatype = ['edc','hsk'] ; load level-1B DC electric fields and housekeeping data from ts1


; ACE Load/tplot
;-----------------------------------
; compile
.compile tracers_ace_load
.compile tra_ace_load_l2_data
.compile tra_ace_make_info_str

tracers_ace_load ; loads data for the time span given to your specified local path on external HDD and tplots

; ACI Load/tplot
;-----------------------------------
tracers_aci_load ; loads data for the time span given to your specified local path on external HDD and tplots
; tplot data from a given path
tracers_aci_tplot, ['/Volumes/MyExternalHardDrive/TRACERS_data/flight/ACI/ts2/l2/aci/ipd/ts2_l2_aci_ipd_20250926_v1.0.0.cdf']


; Solar Wind Data Load
;-----------------------------------
tracers_sw_load, local_path = '/Volumes/MyExternalHardDrive/TRACERS_data/' ; load solar wind data onto external HD

; Ephemeris/Orbit Data Load
;-----------------------------------
tracers_eph_load, datatype = ['pred', 'def'] ; loads predictive and defnitive data 
