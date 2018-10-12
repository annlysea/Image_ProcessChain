; Script to create offset map from two tiff images.
; Creates a directory and works within it
; Then computes the difference between the master and slave images, thanks to the calculated offset

; Hint: launch this idl procedure from a screen (bash), that you can detach afterwards (Ctrl+a, then d). The long computation time sometimes causes the terminal to cut the connection. Resume with screen -r

; Changes directory. Use cd,'..' to go back

pro create_offmap, $
    tif1, tif2, $ ; tif1 should be prior to tif2 (ie. the date of tif1 should be before the date of tif2)
    id1, id2, $
    pos_x, pos_y, $
    x_size, y_size, $
    nproc, $ ; optional
    xoff, yoff, $ ; optional
    rgspac, line_spac, $ ; optional
    rgstep, line_step, $ ; optional
    filter=filter, $ ; optional
    sz_filter=sz_filter, $ ; optional
    ampcor_loc=ampcor_loc, $ ; optional
    tif_loc=tif_loc, $ ; optional
    prefix=prefix, $ ; optional
    shapefile_loc=shapefile_loc,$ ; optional
    min_meltrate=min_meltrate, $ ; optional
    max_meltrate=max_meltrate, $ ; optional
    min_dhdt=min_dhdt, $ ; optional
    max_dhdt=max_dhdt, $ ; optional
    comp=comp, $ ; optional
    apriori=apriori, $ ; optional
    antarctica=antarctica, $ ; optional
    shape_is_grounded=shape_is_grounded, $ ; optional
    shapefile_meter=shapefile_meter, $ ; optional
    skip_offset=skip_offset, $ ; optional
    geotiff=geotiff, $
    testing=testing ; optional

begin_time = systime(/sec)
begin_time_str = systime()

; Parameters:
; tif1-2 (str) : name of original tif images, tif1 should be prior to tif2 (ie. the date of tif1 should be before the date of tif2)
; id1-2 (str) : short name for those two images (ex: '20110412')
; pos_x, pos_y (num) : x and y coordinates for cropping, north-west corner in meters
; x_size, y_size (num) : numbers of pixels in each direction
; nproc (num) : number of chunks in the c_ampcor_lsat procedure (default: 14)
; xoff, yoff (num) : initial motion offset, in pixels, for the amplitude correlation (default: 0,0)
; rgspac, line_spac (num) : undersampling factor. (default is 25 for worldview)
; rgstep, line_step (num) : subimage size in pixels for search window for amplitude correlation (default: 16)
; filter : filter limit for the median_filter in the diff_to_meltrate procedure (default: 2)
; sz_filter : filter size for the median_filter in the diff_to_meltrate procedure (default: 9)
; ampcor_loc : folder where the ampcor binaries are located, if not in the current folder (default: '/home/arnaud/')
; tif_loc : folder where the tiff files are located, if not in the current folder (default: '../')
; prefix : string to prefix folder names, to make sure that everyone of them is different (default: '')
; shapefile_loc (str) : link to shapefile of grounding lines (default nothing, typical '/u/pennell-z0/eric/acharola/gl-iceshelf/Greenland_Iceshelf_Basins_2016_PS_v1.4.shp')
; min_meltrate (num) : lower limit for meltrate (in m.yr-1) (typical -100)
; max_meltrate (num) : upper limit for meltrate (in m.yr-1) (typical 100)
; min_dhdt (num) : lower limit for dhdt (in m.yr -1) (typical -10)
; max_dhdt (num) : upper limit for dhdt (in m.yr -1) (typical 10)
; comp (kw) : complex or not. Will copy a different ampcor binary (keyword, default 0)
; apriori (kw) : Will copy a different ampcor binary, to change dynamically the initial offset. (keyword, default 0)
; antarctica (kw) : write /ant to work in antarctica, leave empty for greenland. Will look for a different apriori speeds file (keyword, default 0)
; shape_is_grounded (kw) : set if the shapefile designates area that are grounded. Don't set if the shapefile designates area that is floating (ice shelf) (keyword, default 0)
; shapefile_meter (kw) : set if the shapefile contains already the coordinates in meters. Leave if the shapefile contains lat/lon, that need to be converted (keyword, default 0)
; skip_offset (kw) : set to skip the computation of the offset, and only have dhdt without lagrangian
; geotiff (kw) : set to write geotiffs for each png
; testing (kw) : allows to code something that doesn't work necessarily

if ~exist(tif1) or ~exist(tif1) then begin
    ; If these two variables don't exist, display a welcome message
    print,"---------- create_offmap.pro ----------"
    print,""
    print,"This script computes, from two DEMs, the difference (dh/dt) and the meltrate"
    print,""
    print,"Parameters:"
    print,"tif1-2 (str) : name of original tif images, tif1 should be prior to tif2 (ie. the date of tif1 should be before the date of tif2)"
    print,"id1-2 (str) : short name for those two images (ex: '20110412')"
    print,"pos_x, pos_y (num) : x and y coordinates for cropping, north-west corner in meters"
    print,"x_size, y_size (num) : numbers of pixels in each direction"
    print,""
    print,"Optional parameters:"
    print,"nproc (num) : number of chunks in the c_ampcor_lsat procedure (default: 14)"
    print,"xoff, yoff (num) : initial motion offset, in pixels, for the amplitude correlation (default: 0,0)"
    print,"rgspac, line_spac (num) : undersampling factor. (default is 25 for worldview)"
    print,"rgstep, line_step (num) : subimage size in pixels for search window for amplitude correlation (default: 16)"
    print,"filter : filter limit for the median_filter in the diff_to_meltrate procedure (default: 2)"
    print,"sz_filter : filter size for the median_filter in the diff_to_meltrate procedure (default: 9)"
    print,"ampcor_loc : folder where the ampcor binaries are located, if not in the current folder (default: '/home/arnaud/')"
    print,"tif_loc : folder where the tiff files are located, if not in the current folder (default: '../')"
    print,"prefix : string to prefix folder names, to make sure that everyone of them is different (default: '')"
    print,"shapefile_loc (str) : link to shapefile of grounding lines (default nothing, typical '/u/pennell-z0/eric/acharola/gl-iceshelf/Greenland_Iceshelf_Basins_2016_PS_v1.4.shp')"
    print,"min_meltrate (num) : lower limit for meltrate (in m.yr-1) (typical -100)"
    print,"max_meltrate (num) : upper limit for meltrate (in m.yr-1) (typical 100)"
    print,"min_dhdt (num) : lower limit for dhdt (in m.yr -1) (typical -10)"
    print,"max_dhdt (num) : upper limit for dhdt (in m.yr -1) (typical 10)"
    print,"comp (kw) : complex or not. Will copy a different ampcor binary (keyword, default 0)"
    print,"apriori (kw) : Will copy a different ampcor binary, to change dynamically the initial offset. (keyword, default 0)"
    print,"antarctica (kw) : write /ant to work in antarctica, leave empty for greenland. Will look for a different apriori speeds file (keyword, default 0)"
    print,"shape_is_grounded (kw) : set if the shapefile designates area that are grounded. Don't set if the shapefile designates area that is floating (ice shelf) (keyword, default 0)"
    print,"shapefile_meter (kw) : set if the shapefile contains already the coordinates in meters. Leave if the shapefile contains lat/lon, that need to be converted (keyword, default 0)"
    print,"skip_offset (kw) : set to skip the computation of the offset, and only have dhdt without lagrangian"
    print,"geotiff (kw) : set to write geotiffs for each png"
    return
endif
if ~exist(id1) or ~exist(id1) then begin
    print,"You must provide valid id1 and id2 variable."
    return
endif
if ~exist(pos_x) or ~exist(pos_y) then begin
    print,"You must provide valid pos_x and pos_y variable."
    return
endif
if ~exist(x_size) or ~exist(y_size) then begin
    print,"You must provide valid x_size and y_size variable."
    return
endif
if (~exist(nproc)) then nproc = 14
if (~exist(xoff)) then xoff = 0
if (~exist(yoff)) then yoff = 0
if (~exist(rgspac)) then rgspac = 25
if (~exist(line_spac)) then line_spac = rgspac
if (~exist(rgstep)) then rgstep = 64
if (~exist(line_step)) then line_step = rgstep
if (~exist(filter)) then filter = 0
if (~exist(sz_filter)) then sz_filter = 0
if (~exist(ampcor_loc)) then ampcor_loc = "/home/arnaud/"
if (~exist(tif_loc)) then tif_loc = "../"
if (~exist(prefix)) then prefix = ""
if (~exist(min_meltrate)) then min_meltrate = -100
;if (min_meltrate eq "null") then min_meltrate = -100
if (~exist(max_meltrate)) then max_meltrate = 100
;if (max_meltrate eq "null") then max_meltrate = 100
if (~exist(min_dhdt)) then min_dhdt = -10
if (~exist(max_dhdt)) then max_dhdt = 10
if (~exist(shapefile_loc) or shapefile_loc eq "null") then shapefile_loc = { }

if keyword_set(comp) then adapt = 1 else adapt = 0
if keyword_set(apriori) then a_priori = 1 else a_priori = 0
if ~keyword_set(antarctica) then antarctica = 0
if ~keyword_set(shape_is_grounded) then shape_is_grounded = 0
if ~keyword_set(shapefile_meter) then shapefile_meter = 0
if ~keyword_set(skip_offset) then skip_offset = 0
if ~keyword_set(geotiff) then geotiff = 0
if ~keyword_set(testing) then testing = 0

;Skip all that crap ..
goto,jump1

; I) Create a directory and cd to it, this will be the working directory. Link images, and scripts.
dirname = prefix + "offmap-" + id1 + "-" + id2 + "-"
for i=0,1000 do begin
	if (~file_test(dirname + string(i,format="(I4.4)"), /directory)) then begin
		dirname = dirname + string(i,format="(I4.4)")
		file_mkdir, dirname
		cd, dirname
		print,"Creating " + dirname + "/"
		break
	endif
endfor

cd, current = current_dir
dirpath = current_dir + "/" + dirname

; Create log file to remember with which parameter the procedure was launched
openw,1,'create_offmap.par'
printf,1,'***create_offmap procedure: paremeters***'
printf,1,''
printf,1,'tif1:   ' + tif1
printf,1,'tif2:   ' + tif2
printf,1,'id1:    ' + id1
printf,1,'id2:    ' + id2
printf,1,'pos_x:  ' + string(pos_x)
printf,1,'pos_y:  ' + string(pos_y)
printf,1,'x_size: ' + string(x_size)
printf,1,'y_size: ' + string(y_size)
printf,1,'nproc:  ' + string(nproc)
printf,1,'xoff:   ' + string(xoff)
printf,1,'yoff:   ' + string(yoff)
printf,1,'rgspac:   ' + string(rgspac)
printf,1,'line_spac:   ' + string(line_spac)
printf,1,'rgstep:   ' + string(rgstep)
printf,1,'line_step:   ' + string(line_step)
printf,1,'filter:   ' + string(filter)
printf,1,'sz_filter:   ' + string(sz_filter)
printf,1,'ampcor_loc: ' + ampcor_loc
printf,1,'tif_loc: ' + tif_loc
printf,1,'prefix: ' + prefix
if shapefile_loc eq !null then print_shapefile_loc = "null" else print_shapefile_loc = shapefile_loc
printf,1,'shapefile_loc: ' + string(print_shapefile_loc)
if min_meltrate eq !null then print_min_meltrate = "null" else print_min_meltrate = min_meltrate
printf,1,'min_meltrate: ' + string(print_min_meltrate)
if max_meltrate eq !null then print_max_meltrate = "null" else print_max_meltrate = max_meltrate
printf,1,'max_meltrate: ' + string(print_max_meltrate)
printf,1,'min_dhdt: ' + string(min_dhdt, format="(I0)")
printf,1,'max_dhdt: ' + string(max_dhdt, format="(I0)")
printf,1,'comp:   ' + string(adapt, format="(I0)")
printf,1,'apriori: ' + string(a_priori, format="(I0)")
printf,1,'antarctica: ' + string(antarctica, format="(I0)")
printf,1,'shape_is_grounded: ' + string(shape_is_grounded, format="(I0)")
printf,1,'shapefile_meter: ' + string(shapefile_meter, format="(I0)")
printf,1,'skip_offset: ' + string(skip_offset, format="(I0)")
printf,1,'testing: ' + string(testing, format="(I0)")
close,1
print,"Parameters saved in create_offmap.par"

if (adapt && a_priori) then begin
	print,"Error, you have to chose between /comp and /apriori"
        cd,'..'
        return
endif
if (adapt && ~a_priori) then file_copy, ampcor_loc + "ampcor_adapt", "ampcor" else $
if (~adapt && a_priori) then file_copy, ampcor_loc + "ampcor_apriori", "ampcor" else $
if (~adapt && ~a_priori) then file_copy, ampcor_loc + "ampcor_float", "ampcor"
file_link, tif_loc + tif1, id1 + ".tif"
print, "Creating " + id1 + ".tif link"
file_link, tif_loc + tif2, id2 + ".tif"
print, "Creating " + id2 + ".tif link"

; II) Crop images into .dat files.
ids = [id1, id2]
pxscl = dictionary()

foreach id, ids do begin
	; Creating DEM_gc_par
	print,"Getting parameters for id: " + id
	geotiff2gc_par_ps_arn, id + ".tif" 
	file_copy, "DEM_gc_par", id + ".DEM_gc_par"
	
        ; Getting the pixel scale
        tif_tmp = query_tiff(id + ".tif", geotiff = var)
        pxscl['rg_' + id] = var.modelpixelscaletag[0] ; this is the number of meters per pixels in the original tiff files
        pxscl['line_' + id] = var.modelpixelscaletag[1] ; both DEMs should be in the same resolution
        delvar,tif_tmp
        delvar,var

	; Modifying parameters
	content=strarr(file_lines(id+".DEM_gc_par"))
	openr,1,id+".DEM_gc_par"
	readf,1,content
	close,1
	
	content[5] = "width:        " + string(x_size,format='(F16.3)')
	content[6] = "nlines:       " + string(y_size,format='(F16.3)')
	content[7] = "corner_north:     " + string(pos_y,format='(F16.3)') + " m"
	content[8] = "corner_east:      " + string(pos_x,format='(F16.3)') + " m"

	openw,1,id+".DEM_gc_par"
	mysize=size(content, /dimensions)
	for i=0,mysize[0]-1 do printf,1,content[i]
	close,1
	delvar, content

	; Creating .dat image
	geoloc=load_geo_param(gc=id+'.DEM_gc_par')
	geoim=load_geo_param(gc="DEM_gc_par")
	a = geocode_im(id+".tif", /im, geoloc=geoloc, geoim=geoim)
        help,a
	
	openw,1,id+".dat",/swap_endian
	writeu,1,a
	close,1

        sz = size(a)
        width = sz[1]
        length = sz[2]

        ac = congrid(a, width / rgspac, length / line_spac, /interp)
        w = where(abs(ac) gt 1000)
        ac[w] = 0
        write_file,ac,id+".small.dat"

        plot_contour,id+".small.dat",paramfile=id+".small.dat.par",ct_num=15,n_levels=200,save_img=id+".small",title="Original data for " + id

endforeach

; Test if the number of meters per pixels are compatible in both images
if pxscl['rg_' + id1] ne pxscl['rg_' + id2] then begin
    print,"Both images should have the same dimensions: pxscl['rg_' + id1]=" + pxscl['rg_' + id1] + " and pxscl['rg_' + id2]=" + pxscl['rg_' + id2]
    return
endif
if pxscl['line_' + id1] ne pxscl['line_' + id2] then begin
    print,"Both images should have the same dimensions: pxscl['line_' + id1]=" + pxscl['line_' + id1] + " and pxscl['line_' + id2]=" + pxscl['line_' + id2]
    return
endif
if ~skip_offset then begin

    ; Change float to complex with gradient_lsat
    if (adapt || a_priori) then begin
    	prep_aerial,id1
    	prep_aerial,id2
    endif
    
    ; Prepare ampcor_apriori
    if a_priori then begin
        if antarctica then c_apriori_offset_ps_step_ant,id1,id2,rgspac,line_spac
        if ~antarctica then c_apriori_offset_ps_step_gre,id1,id2,rgspac,line_spac
    endif
    
;Skip offset generation 
goto,jump1

    ; III) Launch c_ampcor_lsat to obtain .bat file
    if (adapt || a_priori) then c_ampcor_lsat_arn,id1,id2,nproc,xoff,yoff,rgspac,line_spac,rgstep,line_step,/comp else c_ampcor_lsat_arn,id1,id2,nproc,xoff,yoff,rgspac,line_spac,rgstep,line_step
    
    ; IV) Launch .bat file
    command = "./bat_" + id1 + "-" + id2 + " > bat.log"
    print,command
    spawn, command

    ; V) Write parameters
    p = load_off_param()
    write_off_param,id1 + "-" + id2 + ".par",p

    ; VI) Reconstitution of the different parts
    r_off,id1,id2,resp='n'
    
    ; VII) Now we can read the offset
    get_width_lines,id1,id2,width,lines
    
    ; Save offset as image
    read_off = id1 + "-" + id2 + ".offmap.off"
    plot_contour,read_off, paramfile=id1 + "-" + id2 + ".offmap.par", $
        save_img=id1 + "-" + id2 + ".offmap", title="Offset for " + id1 + " and " + id2, /offset, $
        xtitle="Latitude (m)", ytitle="Longitude (m)", cbtitle="Translation (m)", $
        ct_num=15, n_levels=200
    
jump1:

pxscl = dictionary()
tif_tmp = query_tiff(id1 + ".tif", geotiff = var)
pxscl['rg_' + id1] = var.modelpixelscaletag[0] ; this is the number of meters per pixels in the original tiff files
pxscl['line_' + id1] = var.modelpixelscaletag[1] ; both DEMs should be in the same resolution

    if (adapt || a_priori) then begin
        read_off = id1 + "-" + id2 + ".off_apriori.off"
        plot_contour,read_off, paramfile=id1 + "-" + id2 + ".off_apriori.par", $
            save_img=id1 + "-" + id2 + ".off_apriori", title="Offset apriori for " + id1 + " and " + id2, /offset, $
            xtitle="Latitude (m)", ytitle="Longitude (m)", cbtitle="Translation (m)", $
            ct_num=15, n_levels=200
    endif

endif

;VIII) Separating grounded and floating ice and
;IX) Calculating the difference
if rgspac ne line_spac then begin
    print,"For this, rgspac and line_spac must have the same value" ; TODO: change this! It shoud work either way
    goto, skipbasalmelt
endif
if pxscl['rg_' +id1] ne pxscl['line_' + id1] then begin
    print,"For computing the meltrate, pxscl['rg_' + id1] and pxscl['line_' + id1] must have the same value" ; TODO: check if two different values aren't ok.
    goto, skipbasalmelt
endif

scale_rg = rgspac * pxscl['rg_' +id1]
scale_line = line_spac * pxscl['line_' +id1]

;Error fixed by ER on Oct. 2017
scale_rg = rgspac
scale_line = line_spac
;End error

if testing then begin
    print,"rgspac:",rgspac
    print,"line_spac:",line_spac
    print,"pxscl['rg_' + id1]:",pxscl['rg_' + id1]
    print,"pxscl['line_' + id1]:",pxscl['line_' + id1]
    print,"scale_rg:",scale_rg
    print,"scale_line:",scale_line
endif

compute_diff,id1,id2,shapefile_loc,scale_rg,scale_line,min_dhdt=min_dhdt,max_dhdt=max_dhdt,shape_is_grounded=shape_is_grounded,shapefile_meter=shapefile_meter,skip_offset=skip_offset,scale_skip_offset=rgspac,testing=testing,geotiff=geotiff,post_north=pos_y,post_east=pos_x,/verbose,apriori=a_priori

;X) Converting in basal melt rate
if ~skip_offset then diff_to_meltrate,id1,id2,shapefile_loc,scale_rg,scale_line,min_meltrate=min_meltrate,max_meltrate=max_meltrate,filter=filter,sz_filter=sz_filter,antarctica=antarctica,shape_is_grounded=shape_is_grounded,shapefile_meter=shapefile_meter,apriori=a_priori,geotiff=geotiff,post_north=pos_y,post_east=pos_x

skipbasalmelt:

end_time = systime(/sec)

; Write a file to prove the script has finished
msg = "The script has terminated, results and all other files are located in the folder " + dirname
msg += string(13B) + string(10B)
msg += "Time elapsed: " + string(end_time - begin_time) + " seconds, or " + string((end_time - begin_time) / 60.) + " minutes"
msg += string(13B) + string(10B)
msg += "Procedure launched on " + begin_time_str + ":"
msg += string(13B) + string(10B)
msg += string(13B) + string(10B)
msg += "create_offmap,'" + tif1 + "','" + tif2 + "','" + id1 + "','" + id2 + "'," + string(pos_x, format="(I0)") + "," + string(pos_y, format="(I0)") + "," + string(x_size, format="(I0)") + "," + string(y_size, format="(I0)") + "," + string(nproc, format="(I0)") + "," + string(xoff, format="(I0)") + "," + string(yoff, format="(I0)") + "," + string(rgspac, format="(I0)") + "," + string(line_spac, format="(I0)") + "," + string(rgstep, format="(I0)") + "," + string(line_step, format="(I0)")
msg += ",filter=" + string(filter, format="(I0)") + ",sz_filter=" + string(sz_filter, format="(I0)") + ",ampcor_loc='" + ampcor_loc + "',tif_loc='" + tif_loc + "',prefix='" + prefix + "',shapefile_loc='" + shapefile_loc + "'"
if exist(min_meltrate) then msg += ",min_meltrate=" + string(min_meltrate, format="(I0)")
if exist(max_meltrate) then msg += ",max_meltrate=" + string(max_meltrate, format="(I0)")
msg += ",min_dhdt=" + string(min_dhdt, format="(I0)") + ",max_dhdt=" + string(max_dhdt, format="(I0)")
if keyword_set(comp) then msg += ",/comp"
if keyword_set(apriori) then msg += ",/apriori"
if keyword_set(antarctica) then msg += ",/antarctica"
if keyword_set(shape_is_grounded) then msg += ",/shape_is_grounded"
if keyword_set(shapefile_meter) then msg += ",/shapefile_meter"
if keyword_set(skip_offset) then msg += ",/skip_offset"
if keyword_set(geotiff) then msg += ",/geotiff"
if keyword_set(testing) then msg += ",/testing"
write_file, msg, "script_done",/verbose,/content

clear_lun ; This is to make sure that all files are closed, there seems to be a bug in IDL
end
