pro geotiff2gc_par_ps_arn,filename,ras=ras,add=add,lima=lima

; Modifications by Arnaud Charolais:
; Paremeters PS_secant_lat and PS_central_meridian were forced to be 70 and -45
; which we don't want

a=read_tiff(filename,geotiff=geo_tag)


DEM_projection='PS'
tags = tag_names(geo_tag)
w=where(tags eq 'PROJECTEDCSTYPEGEOKEY',cnt)
;if cnt eq 1 then begin
;    if geo_tag.PROJECTEDCSTYPEGEOKEY ne 3031 and geo_tag.PROJECTEDCSTYPEGEOKEY ne 32767 and geo_tag.PROJECTEDCSTYPEGEOKEY ne 3413 then goto,fin
;    if geo_tag.PROJECTEDCSTYPEGEOKEY eq 3031 or geo_tag.PROJECTEDCSTYPEGEOKEY eq 32767 then begin
;        PS_secant_lat = -71.
;        PS_central_meridian = 0.
;        ellipsoid_name='WGS 84'
;    endif
;    if geo_tag.PROJECTEDCSTYPEGEOKEY eq 3413 THEN BEGIN
;        PS_secant_lat = 70.
;        PS_central_meridian = -45.000
;        ellipsoid_name='WGS 84'
;    endif
;
;endif else begin
;
;    if geo_tag.PROJCOORDTRANSGEOKEY eq 15 then DEM_projection='PS'
;    if DEM_projection ne 'PS' then begin
;        print,' %% Works only for PS projection .. '
;        goto,fin
;    endif
;    if geo_tag.GEOGRAPHICTYPEGEOKEY eq 4326 then ellipsoid_name='WGS 84'
;    if ellipsoid_name ne 'WGS 84' then begin
;        print,' %% Works only for WGS 84 ellipsoid .. '
;        goto,fin
;    endif
;    PS_secant_lat = geo_tag.PROJNATORIGINLATGEOKEY
;    PS_central_meridian = geo_tag.PROJSTRAIGHTVERTPOLELONGGEOKEY 
;                                 ;PROJSTRAIGHTVERTPOLELONGGEOKEY
;endelse


tags = tag_names(geo_tag)
if n_elements(geo_tag.GEOGCITATIONGEOKEY) ne 0 then ellipsoid_name = geo_tag.GEOGCITATIONGEOKEY else ellipsoid_name = 'WGS 84'

w=where(tags eq 'PROJSTRAIGHTVERTPOLELONGGEOKEY',cnt)
if cnt eq 0 then  PS_central_meridian= 0 else PS_central_meridian = geo_tag.PROJSTRAIGHTVERTPOLELONGGEOKEY

w=where(tags eq 'PROJNATORIGINLATGEOKEY',cnt)
if cnt eq 0 then PS_secant_lat = -71 else PS_secant_lat = geo_tag.PROJNATORIGINLATGEOKEY
;if n_elements(geo_tag.PROJSTRAIGHTVERTPOLELONGGEOKEY) ne 0 then PS_central_meridian = geo_tag.PROJSTRAIGHTVERTPOLELONGGEOKEY else PS_central_meridian= 0
;if n_elements(geo_tag.PROJNATORIGINLATGEOKEY) ne 0 then PS_secant_lat = geo_tag.PROJNATORIGINLATGEOKEY else PS_secant_lat = -71

corner_east = geo_tag.MODELTIEPOINTTAG[3]
corner_north = geo_tag.MODELTIEPOINTTAG[4]
posting = geo_tag.MODELPIXELSCALETAG[0]

openw,1,'DEM_gc_par'
printf,1,'title: '+filename
printf,1,'DEM_projection:     '+DEM_projection
printf,1,'data_format:        REAL*4'
printf,1,'DEM_hgt_offset:          0.00000'
printf,1,'DEM_scale:               1.00000'
printf,1,'width:                 '+strcompress(n_elements(a[*,0]))
printf,1,'nlines:                '+strcompress(n_elements(a[0,*]))
printf,1,'corner_north:  '+string(corner_north+posting/2.,format='(F16.3)')+'   m'
printf,1,'corner_east:  '+string(corner_east+posting/2.,format='(F16.3)')+'   m'
printf,1,'post_north:   '+string(-posting,format='(F16.3)')+'   m'
printf,1,'post_east:    '+string(posting,format='(F16.3)')+'   m'
printf,1,'PS_secant_lat:        '+string(PS_secant_lat,format='(F16.6)')+'   decimal degrees'
printf,1,'PS_central_meridian:      '+string(PS_central_meridian,format='(F16.6)')+'   decimal degrees'
printf,1,''
printf,1,'ellipsoid_name: '+ellipsoid_name
printf,1,'ellipsoid_ra:        6378137.000   m'
printf,1,'ellipsoid_reciprocal_flattening:  298.2572236'
printf,1,''
printf,1,'datum_name: '+ellipsoid_name
printf,1,'datum_shift_dx:              0.000   m'
printf,1,'datum_shift_dy:              0.000   m'
printf,1,'datum_shift_dz:              0.000   m'
printf,1,'datum_scale_m:         0.00000e+00'
printf,1,'datum_rotation_alpha:  0.00000e+00   arc-sec'
printf,1,'datum_rotation_beta:   0.00000e+00   arc-sec'
printf,1,'datum_rotation_gamma:  0.00000e+00   arc-sec'
printf,1,'datum_country_list Global Definition, WGS84, World'

close,1

if keyword_set(ras) then begin
	print,'Create sun raster image form tiff ..'
	write_srf,filename+'.ras',a
endif

if keyword_set(add) then begin
	spawn,'ls *TIF',ll
	for i=0,n_elements(ll)-1 do begin
		if i eq 0 then begin
			a=float(read_tiff(ll[i]))
		endif else begin
			a=float(read_tiff(ll[i]))+a
		endelse
	endfor
	out = strmid(ll[0],0,strlen(ll[0])-8)
	
	openw,1,out+'.BigEndian.float',/swap_end
	writeu,1,a
	close,1
	spawn,'raspwr '+out+'.BigEndian.float '+strcompress(n_elements(a[*,0]),/r)+' - - - - 1 2'
endif

if keyword_set(lima) then begin
spawn,'scp DEM_gc_par jeremie@pennell.ess.uci.edu:/u/pen-r2/eric/temp/'

openw,1,'script_lima'
printf,1,'cd,"/u/pen-r2/eric/temp/"'
printf,1,'.r /u/pen-r2/eric/ST_RELEASE/UTILITIES/read_keyword.pro'
printf,1,'.r /u/pen-r2/eric/ST_RELEASE/UTILITIES/frebin.pro'
printf,1,'.r /u/pen-r2/eric/ST_RELEASE/GEOCODING/lima_map.pro'
printf,1,'lima_map'
close,1

spawn,'scp script_lima jeremie@pennell.ess.uci.edu:/u/pen-r2/eric/temp/'
spawn,'ssh -X jeremie@pennell.ess.uci.edu "/usr/local/RSI/idl_6.1/bin/idl < /u/pen-r2/eric/temp/script_lima"'
spawn,'scp jeremie@pennell.ess.uci.edu:/u/pen-r2/eric/temp/lima.geo .'
endif


fin:
end
