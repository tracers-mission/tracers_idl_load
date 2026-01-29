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
- MAG, MSC, MAGIC, ACI
- Load in both spacecraft data (ts1 and ts2)
- Email Sky with what you want! <skylar.shaver@mail.wvu.edu>

## Contributors
A special thank you to contributors to this code: Dr. John Bonnell, Dr. Marit Oieroset, Dr. Jasper Halekas, Dr. Katy Goodrich, Dr. Sarah Henderson, and others!

## Basic Usage
```idl

; Update the tracers_init file to your benefit!
tracers_init

timespan, '2025-09-26', 1 ; one day of data

; EFI Load Routine
;-----------------------------------
tracers_efi_load, local_path = '/Users/SkyShaver/Data/TRACERS_data/' ; loads l2 data for the time span given to your specified local path
tracers_efi_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads l2 data for the time span given to your specified local path on external HDD
tracers_efi_load, url_username = 'tracers-username', url_password = 'tracers-password' ; use these keywords if you havent set the 'TRACERS_USER_PASS' environment variable

tracers_efi_load, spacecraft='ts1', level='l1b', datatype = ['edc','hsk'] ; load level-1B DC electric fields and housekeeping data from ts1


; ACE Load/tplot
;-----------------------------------
; compile
.compile tracers_ace_load
.compile tra_ace_load_l2_data
.compile tra_ace_make_info_str

tracers_ace_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; loads data for the time span given to your specified local path on external HDD and tplots

; Solar Wind Data Load
;-----------------------------------
tracers_sw_load, local_path = '/Volumes/wvushaverhd/TRACERS_data/' ; load solar wind data onto external HD

; Ephemeris/Orbit Data Load
;-----------------------------------
tracers_eph_load, datatype = ['pred', 'def'] ; loads predictive and defnitive data 