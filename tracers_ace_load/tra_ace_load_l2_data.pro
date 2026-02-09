;+
;PROCEDURE: 
;	TRA_ACE_LOAD_L2_DATA
;PURPOSE: 
;	Routine to load ACE Level 2 data and produce common blocks and Tplot variables
;	This routine is still preliminary and will include a lot more bells and whistles
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	TRA_ACE_LOAD_L2_DATA, /TPLOT, PATH = PATH, VERSION = VERSION, TRANGE = TRANGE
;INPUTS:
;
;KEYWORDS:
;	FILES: An array of filenames containing ACE Level 2 data (by default just YYMMDD part of file name)
;	PATH: Directory path for ACE level 2 files 
;	FLAT: Kluge if files are not in YYYY/MM subdirectories
;	VERSION: Version number to put in file (defaults to most recent if not set)
;	TPLOT: Produce Tplot variables
;	TRANGE: Load data for all files within given range (one day granularity, 
;	        supercedes file list, if not set then 'timerange' will be called)
;	SV: Spacecraft id
;
;	This routine does not presently utilize file_retrieve capability. At some point hopefully it will. 
;-
pro tra_ace_load_l2_data, files = files, trange = trange, path = path, version = version, sv = sv, flat = flat, tplot = tplot,tail = tail, chare = chare

compile_opt idl2

cdf_leap_second_init

common tra_ace_data, ace_info, ace_data

if not keyword_set(sv) then sv = 'ts2'
if not keyword_set(path) then path = '/project/tracers/ace/data/'+strupcase(sv)+'/L2/'
if not keyword_set(version) then version = '*.*.*'
if not keyword_set(tail) then tail = ''

if not keyword_set(files) then begin
	trange = timerange(trange)
	days = ceil((trange[1]-trange[0])/(24.*3600))
	t0 = time_double(strmid(time_string(trange[0]),0,10))
	dates = time_string(t0 + indgen(days)*24.d*3600, format = 6)
	files = strmid(dates, 0, 8)
	nfiles = n_elements(files)
endif else begin
	nfiles = n_elements(files)
endelse

tra_ace_make_info_str,ace_info

ace_info = replicate(ace_info,nfiles)

ace_str = {epoch: long64(0), $
time_unix: 0.d, $
def: fltarr(49,21), $
counts: fltarr(49,21), $
bgcounts: fltarr(49,21), $
spin_phase: 0., $
info_index: 0}

ace_data = 0

for i = 0,nfiles-1 do begin

	print,'Reading File for Date: ',files[i]

	yyyy = strmid(files[i],0,4)
	mm = strmid(files[i],4,2)

	if keyword_set(flat) then acel2files = path+'/'+sv+'_l2_ace_def_'+files[i]+'_v'+version+tail+'.cdf' else acel2files = path+yyyy+'/'+mm+'/'+sv+'_l2_ace_def_'+files[i]+'_v'+version+tail+'.cdf'

	matchfiles = file_search(acel2files)

	if matchfiles[0] ne '' then begin
		vstr = stregex(matchfiles,'(v)(.+\..+\..+)(\.cdf)',/extract,/subexpr)
		highv = get_highest_version(vstr[2,*],3)
		acel2file = matchfiles[highv]

		print,acel2file

		id = cdf_open(acel2file,/readonly)
		cdf_control,id,get_var_info = info,variable = 'Epoch'

		nrec = info.maxrec

		if i eq 0 or n_elements(ace_data) lt 2 then begin
			offset = 0L
			ace_data = replicate(ace_str,nrec) 
		endif else begin
			offset = n_elements(ace_data)
			ace_data = [ace_data,replicate(ace_str,nrec)]
		endelse

		cdf_varget,id,'Epoch',output,rec_count = nrec,/zvariable
		ace_data[offset:offset+nrec-1].epoch = reform(output)

		ace_data[offset:offset+nrec-1].time_unix = time_double(reform(output),/tt2000)

		cdf_varget,id,sv+'_l2_ace_def',output,rec_count = nrec,/zvariable
		ace_data[offset:offset+nrec-1].def = output

		cdf_varget,id,sv+'_l2_ace_counts',output,rec_count = nrec,/zvariable
		ace_data[offset:offset+nrec-1].counts = output

		cdf_varget,id,sv+'_l2_ace_background_counts',output,rec_count = nrec,/zvariable
		ace_data[offset:offset+nrec-1].bgcounts = output

		ace_data[offset:offset+nrec-1].info_index = i

		cdf_varget,id,sv+'_l2_ace_energy',output,/zvariable
		ace_info[i].energy_ave = reform(output)

		cdf_varget,id,sv+'_l2_ace_energy_anode_factor',output,/zvariable
		ace_info[i].energy_detailed = ace_info[i].energy_ave#output

		cdf_varget,id,sv+'_l2_ace_TSCS_anode_angle',output,/zvariable
		ace_info[i].anode_angle = reform(output)
	
		cdf_varget,id,sv+'_l2_ace_cal_matrix',output,/zvariable
		ace_info[i].cal_matrix = output

		cdf_close,id
	endif
endfor

nace = n_elements(ace_data)
if keyword_set(tplot) and nace gt 1 then begin

	espec = transpose(total(ace_data.def,2))/21.
	energies = transpose(ace_info[ace_data.info_index].energy_ave)
	aspec = transpose(total(ace_data.def,1))/49.
	angles = transpose(ace_info[ace_data.info_index].anode_angle)
	
	store_data,sv+'_ace_en_eflux',data = {x:ace_data.time_unix,v:energies,y:espec,ylog:1,zlog:1,ytitle:'Energy [eV]',ztitle:'Diff. En. Flux',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}

	store_data,sv+'_ace_an_eflux',data = {x:ace_data.time_unix,v:angles,y:aspec,zlog:1,ytitle:'Anode Angle',ztitle:'Diff. En. Flux',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}

	especc = transpose(total(ace_data.counts,2))/21.
	aspecc = transpose(total(ace_data.counts,1))/49.

	store_data,sv+'_ace_en_counts',data = {x:ace_data.time_unix,v:energies,y:especc,ylog:1,zlog:1,ytitle:'Energy [eV]',ztitle:'Average!cCounts',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}

	store_data,sv+'_ace_an_counts',data = {x:ace_data.time_unix,v:angles,y:aspecc,zlog:1,ytitle:'Anode Angle',ztitle:'Average!cCounts',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}

	especcb = transpose(total(ace_data.bgcounts,2))/21.
	aspeccb = transpose(total(ace_data.bgcounts,1))/49.

	store_data,sv+'_ace_en_bg_counts',data = {x:ace_data.time_unix,v:energies,y:especcb,ylog:1,zlog:1,ytitle:'Energy [eV]',ztitle:'Average!cBackground!cCounts',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}

	store_data,sv+'_ace_an_bg_counts',data = {x:ace_data.time_unix,v:angles,y:aspeccb,zlog:1,ytitle:'Anode Angle',ztitle:'Average!cBackground!cCounts',spec:1,ystyle:1,no_interp:1}, dlimits = {datagap:60}


endif

if keyword_set(chare) and nace gt 1 then begin
	energys = ace_info[ace_data.info_index].energy_detailed
	denergys = fltarr(49,21,nace)
	angles = ace_info[ace_data.info_index].anode_angle
	allangs = fltarr(49,21,nace)
	for i = 0,48 do allangs[i,*,*] = angles

	for i = 0,20 do begin
		denergys[1:47,i,*] = abs((energys[2:48,i]-energys[0:46,i])/2.) # replicate(1,nace)
		denergys[0,i,*] = denergys[1,i]*energys[0,i]/energys[1,i] # replicate(1,nace)
		denergys[48,i,*] = denergys[47,i]*energys[48,i]/energys[47,i] # replicate(1,nace)
	endfor


	efluxes = fltarr(nace,21)
	charens = fltarr(nace,21)
	charangs = fltarr(nace,49)

	efluxes = transpose(total(denergys * ace_data.def,1))
	charens = transpose(total(energys * (ace_data.def > 0),1)) / (transpose(total((ace_data.def > 0),1)))

	charangs = 180/!pi*acos ( transpose(total(cos(allangs*!pi/180)*(ace_data.def > 0),2)) / (transpose(total((ace_data.def > 0),2))) )

	if keyword_set(tplot) then begin

		store_data,sv+'_ace_an_eflux_total',data = {x:ace_data.time_unix,v:transpose(angles),y:efluxes,zlog:1,ztitle:'Total En. Flux',ystyle:1,spec:1,no_interp:1,ytitle:'Anode Angle'}, dlimits = {datagap:60}

		store_data,sv+'_ace_an_char_en',data = {x:ace_data.time_unix,v:transpose(angles),y:charens,zlog:1,ztitle:'Characteristic!cEnergy [eV]',ystyle:1,spec:1,no_interp:1,ytitle:'Anode Angle'}, dlimits = {datagap:60}

		store_data,sv+'_ace_en_char_ang',data = {x:ace_data.time_unix,v:transpose(ace_info[ace_data.info_index].energy_ave),y:charangs,ztitle:'Characteristic!cAngle',ystyle:1,ylog:1,spec:1,no_interp:1,ytitle:'Energy [eV]'}, dlimits = {datagap:60}
		

	endif


endif

end
