; This procedure converts height difference to a basal melt rate
;	;Correction CC SEP. 2018, adding scale_skip_offset and skip_offset=skip_offset variables 
pro diff_to_meltrate,id1,id2,shapefile_loc,scale_rg,scale_line,min_meltrate=min_meltrate,max_meltrate=max_meltrate,n_levels=n_levels,filter=filter,sz_filter=sz_filter,antarctica=antarctica,verbose=verbose,testing=testing,shape_is_grounded=shape_is_grounded,shapefile_meter=shapefile_meter,apriori=apriori,geotiff=geotiff,post_north=post_north,post_east=post_east,skip_offset=skip_offset,scale_skip_offset=scale_skip_offset
; end correction

; Five results:
; a) no offset
; b) with computed offset, without shapefile
; c) with apriori offset, without shapefile
; d) with computed offset, with shapefile
; e) with apriori offset, with shapefile

if ~exist(n_levels) then n_levels = 200
if ~keyword_set(shape_is_grounded) then shape_is_grounded = 0
if ~keyword_set(shapefile_meter) then shapefile_meter = 0
if ~keyword_set(antarctica) then antarctica = 0
if ~keyword_set(apriori) then apriori = 0
if keyword_set(geotiff) and (~exist(post_north) or ~exist(post_east)) then begin
    print,"If /geotiff is set, please provide post_north and post_east."
    return
endif

;    ;Correction ER Oct. 2017
beg = systime(/sec)
    is=shp2idl(shapefile_loc)
    slave = load_image(id2 + ".dat", parfile=id2 + ".DEM_gc_par", /bin)
    sz = size(slave)
    width = sz[1] / scale_rg
    length = sz[2] / scale_line
    mask_in=intarr(width,length)
    paramfile=id1 + ".DEM_gc_par"
    north = long(read_keyword(paramfile, 'corner_north'))
    east = long(read_keyword(paramfile, 'corner_east'))
    post = long(read_keyword(paramfile, 'post_east'))
    post_north = - scale_line*post
    post_east = scale_rg*post
    x1 = (findgen(width) * post_east + east)#(fltarr(length)+1)
    y1 = (fltarr(width)+1)#(findgen(length) * post_north + north)
    for ii=0,n_elements(is.name)-1 do begin
    N_VERTICES_min = (ii eq 0)? 0: total(is.N_VERTICES[0:ii-1])
    x0 = reFORm(is.vertices[0,N_VERTICES_min:N_VERTICES_min+is.N_VERTICES[ii]-1])
    y0 = reFORm(is.vertices[1,N_VERTICES_min:N_VERTICES_min+is.N_VERTICES[ii]-1])
    x=[0.] & y=[0.]
    nn = (ii eq 0)? 0 : total(is.N_parts[0:ii-1])
    for j=1L,is.n_parts[ii] do begin index_start = is.parts[nn+j-1] & index_end   = (j eq is.N_parts[ii])? is.N_VERTICES[ii]-1 : is.parts[nn+j]-1 & $
        xx = x0[index_start:index_end] & yy = y0[index_start:index_end] & $
        obj=obj_new("IDLanROI",xx,yy) & mask_in += obj->containspoints(x1,y1) & obj_destroy,obj
    endfor
    endfor
    mask_in=mask_in<1
    mask_out=~mask_in
    w_in = where(mask_in eq 1)
    w_out = where(mask_out eq 1)
en = systime(/sec)
    ;end correction

window,0,xs=width*2,ys=length & !order=1 & tvscl,congrid(slave,width,length) & tvscl,mask_in,width,0
;end correction
;
; Correction by CC Sep. 2019 comment goto, jump1
; goto,jump1
; Getting the shape of the ice shelf
if shapefile_loc eq !null then skip_shapefile = 1 else skip_shapefile = 0
if ~skip_shapefile then begin
    get_shapes,shapefile_loc,px_d,py_d,meters=shapefile_meter,antarctica=antarctica,/first
    shp2mask,px_d,py_d,id1,id2,id1 + ".DEM_gc_par",mask_in,mask_out,w_in,w_out,scale_rg,scale_line
    ;get_shapefile,shapefile_loc,shapefile_var,px,py,name=shapefile_name,meters=shapefile_meter
    ;gl2mask,px,py,id1,id2,id1 + ".DEM_gc_par",mask_in,mask_out,w_in,w_out,scale_rg,scale_line
endif
; jump1:
; end Correction
;
; Get parameters
ice_density = 0.9167 ; g . cm(-3)
water_density = 1.028
alpha = (water_density) / (water_density - ice_density)
if ~exist(testing) then testing = 0

;Correction ER Oct. 2017
sz = size(slave)
width = sz[1] / scale_skip_offset
lines = sz[2] / scale_skip_offset
;end correction

;get_width_lines,id1,id2,width,lines

; Get elevation
master = load_image(id1 + ".dat", parfile=id1 + ".DEM_gc_par", /bin)
master_c = congrid(master, width, lines, /interp)
w = where(master_c eq -9999)
; We change the elevation from wgs84 to mean sea level
dir = '/u/pennell-z0/eric/acharola/'
if antarctica then begin
    nc = 'BedMachineAntarctica-2017-03-15.nc'
    gcpar = 'antarctica.DEM_gc_par'
endif else begin 
    nc = 'BedMachineGreenland-2017-07-05.nc' 
    gcpar = 'greenland.DEM_gc_par'
endelse
    
if keyword_set(verbose) then begin
    print,dir + nc
    print,nc
endif
file_delete,nc,/allow_nonexistent
file_delete,gcpar,/allow_nonexistent
file_link, dir + nc, nc
file_link, dir + gcpar, gcpar
    
if keyword_set(verbose) then begin
    if antarctica then print,"Antarctica!" else print,"Greenland!"
endif
    
geoloc = load_geo_param(gc=id1 + ".DEM_gc_par")
geoim = load_geo_param(gc=gcpar)
geoid = geocode_im(nc, geoloc=geoloc, geoim=geoim, nc='geoid', /verbose)

geoid_c = congrid(geoid, width, lines, /interp)

master_c = master_c - geoid_c

write_file,geoid_c,id1 + "-" + id2 + ".geoid",/verbose

; Get speed, and divergence
speed = read_offset(id1 + "-" + id2 + ".off_apriori.off")
;speed = read_offset(id1 + "-" + id2 + ".offmap.off") 
speed_small = {vra: (speed.vra[0:width-1,0:lines-1]), vaz: (speed.vaz[0:width-1,0:lines-1])}
;speed_small = {vra: congrid(speed.vra, width, lines, /interp), vaz: congrid(speed.vaz, width, lines, /interp)}
if keyword_set(testing) then begin
    for i=1,30 do begin
        divergence_arn = div_arn(speed_small.vra, speed_small.vaz, nn=i, rg_sp=scale_rg)
        write_file,divergence_arn,id1 + "-" + id2 + ".divergence_arnaud"+string(i, format="(I02)"),/verbose
        plot_contour,id1 + "-" + id2 + ".divergence_arnaud"+string(i, format="(I02)"),paramfile=id1 + "-" + id2 + ".divergence_arnaud"+string(i, format="(I02)") + ".par", $
            save_img=id1 + "-" + id2 + ".divergence_arnaud"+string(i, format="(I02)"), $
            title="Divergence between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
            cbtitle="Divergence of speed", ct_num=70, n_levels=n_levels, /inverse, /force_scale, /force_sym, $
            min_trunc=-0.1, max_trunc=0.1
    endfor
endif
;divergence = div(speed_small.vra, speed_small.vaz) / scale_rg
divergence = div_arn(speed_small.vra, speed_small.vaz, nn=10, rg_sp=scale_rg*post)
; Make sure that we have meters per year
get_n_days,id1,id2,n_days
divergence *= 365.25 / n_days
divergence_height = divergence * master_c
w_master = where(master_c le -9998)
divergence_height[w_master] = 0

write_file,divergence,id1 + "-" + id2 + ".divergence",/verbose
plot_contour,id1 + "-" + id2 + ".divergence",paramfile=id1 + "-" + id2 + ".divergence.par", $
    save_img=id1 + "-" + id2 + ".divergence", $
    title="Divergence between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
    cbtitle="Divergence of speed", ct_num=70, n_levels=n_levels, /inverse

write_file,divergence_height,id1 + "-" + id2 + ".divergence_height",/verbose
plot_contour,id1 + "-" + id2 + ".divergence_height",paramfile=id1 + "-" + id2 + ".divergence.par", $
    save_img=id1 + "-" + id2 + ".divergence_height", $
    title="Divergence times height between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
    cbtitle="Divergence of speed times height", ct_num=70, n_levels=n_levels, /inverse, /force_sym, $
    min_trunc=min_meltrate, max_trunc=max_meltrate

if keyword_set(testing) then goto, fin

; Compute basalmelt
; Correction CC Sep.26 2018 load binary file ,/bin 
diff_a = load_image(id1 + "-" + id2 + ".dhdt_cleaned", parfile=id1 + "-" + id2 + ".offmap.par",/bin)
diff_b = load_image(id1 + "-" + id2 + ".dhdt_cleaned_lagrange", parfile=id1 + "-" + id2 + ".offmap.par",/bin)
;
if apriori then diff_c = load_image(id1 + "-" + id2 + ".dhdt_cleaned_apriori", parfile=id1 + "-" + id2 + ".offmap.par",/bin)
if ~skip_shapefile then begin
    diff_d = load_image(id1 + "-" + id2 + ".dhdt_cleaned_lagrange_shp", parfile=id1 + "-" + id2 + ".offmap.par",/bin)
    if apriori then diff_e = load_image(id1 + "-" + id2 + ".dhdt_cleaned_apriori_shp", parfile=id1 + "-" + id2 + ".offmap.par",/bin)
endif
;end Correction

basalmelt_a = fltarr(width, lines)
basalmelt_b = fltarr(width, lines)
; correction by CC Sep. 2018
if apriori then basalmelt_c = fltarr(width, lines)
if ~skip_shapefile then begin
    basalmelt_d = fltarr(width, lines)
    if apriori then basalmelt_e = fltarr(width, lines)
endif

; TODO: divergence computed with apriori or DEM data?
basalmelt_a = - (diff_a + divergence_height) * alpha
basalmelt_a[w_master] = 0
basalmelt_b = - (diff_b + divergence_height) * alpha
basalmelt_b[w_master] = 0
if apriori then begin
    basalmelt_c = - (diff_c + divergence_height) * alpha
    basalmelt_c[w_master] = 0
endif
if ~skip_shapefile then begin
    basalmelt_d = - (diff_d + divergence_height) * alpha
    basalmelt_d[w_master] = 0
    if apriori then begin
        basalmelt_e = - (diff_e + divergence_height) * alpha
        basalmelt_e[w_master] = 0
    endif
endif

if keyword_set(verbose) then begin
    print,"mean(diff):",mean(diff),mean(abs(diff))
    print,"mean(master_c * divergence):",mean(master_c * divergence),mean(abs(master_c * divergence))
    print,"Before:max:",max(basalmelt_a)
    print,"min:",min(basalmelt_a)
endif

; Filter, and clean the results
if ~skip_shapefile then begin
    if keyword_set(shape_is_grounded) then basalmelt_a[w_in] = 0 $
    else basalmelt_a[w_out] = 0
endif
basalmelt_a[w] = 0
basalmelt_b[w] = 0
if apriori then basalmelt_c[w] = 0
if ~skip_shapefile then begin
    basalmelt_d[w] = 0
    if apriori then basalmelt_e[w] = 0
endif

; Should I use the median_filter? I don't know if it is any better.
if exist(filter) then begin
    if (filter ne 0) then begin
        if ~exist(sz_filter) then sz_filter = 9
        median_filter,basalmelt_a,sz_filter,filter
        median_filter,basalmelt_b,sz_filter,filter
        if apriori then median_filter,basalmelt_c,sz_filter,filter
        if ~skip_shapefile then begin
            median_filter,basalmelt_d,sz_filter,filter
            if apriori then median_filter,basalmelt_e,sz_filter,filter
        endif
    endif else begin
        filter = 0
        sz_filter = 0
    endelse
endif

if min_meltrate eq !null then min_meltrate = -100 ;min(basalmelt_a)
if max_meltrate eq !null then max_meltrate = 100  ;max(basalmelt_a)

write_file,basalmelt_a,id1 + "-" + id2 + ".melt",/verbose
write_file,basalmelt_b,id1 + "-" + id2 + ".melt_lagrange",/verbose
if apriori then write_file,basalmelt_c,id1 + "-" + id2 + ".melt_apriori",/verbose
if ~skip_shapefile then begin
    write_file,basalmelt_d,id1 + "-" + id2 + ".melt_lagrange_shp",/verbose
    if apriori then write_file,basalmelt_e,id1 + "-" + id2 + ".melt_apriori_shp",/verbose
endif

; Save meltrate as image
names = [id1 + "-" + id2 + ".melt", $
;         id1 + "-" + id2 + ".melt_lagrange", $
         id1 + "-" + id2 + ".melt_apriori", $
;         id1 + "-" + id2 + ".melt_lagrange_shp", $
         id1 + "-" + id2 + ".melt_apriori_shp"]

foreach name,names do begin
    if stregex(name, 'shp', /bool) and skip_shapefile then continue
    if stregex(name, 'apriori', /bool) and ~apriori then continue
    if keyword_set(geotiff) then begin
        plot_contour,name, paramfile=id1 + "-" + id2 + ".offmap.par", $
            save_img=name, $
            title="Meltrate between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
            cbtitle="Meltrate (m.yr -1)", ct_num=70, n_levels=n_levels, $
            min_trunc=min_meltrate, max_trunc=max_meltrate, /inverse, $
            /geotiff, id1=id1, post_north=post_north, post_east=post_east
    endif else begin
        plot_contour,name, paramfile=id1 + "-" + id2 + ".offmap.par", $
            save_img=name, $
            title="Meltrate between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
            cbtitle="Meltrate (m.yr -1)", ct_num=70, n_levels=n_levels, $
            min_trunc=min_meltrate, max_trunc=max_meltrate, /inverse
    endelse
endforeach

;plot_contour,id1 + "-" + id2 + ".result.meltrate", paramfile=id1 + "-" + id2 + ".offmap.par", $
;    save_img=id1 + "-" + id2 + ".result.meltrate", $
;    title="Meltrate between " + id1 + " and " + id2, xtitle="East-West (m)", ytitle="South-North (m)", $
;    cbtitle="Meltrate (m.yr -1)", ct_num=70, n_levels=n_levels, $
;    min_trunc=min_meltrate, max_trunc=max_meltrate, /inverse

fin:

; Print the parameters that were used for this procedure
msg = "diff_to_meltrate,'" + id1 + "','" + id2 + "','" + shapefile_loc + "'," + string(scale_rg, format="(I0)") + "," + string(scale_line, format="(I0)")
msg += ",min_meltrate=" + string(min_meltrate, format="(I0)") + ",max_meltrate=" + string(max_meltrate, format="(I0)")
msg += ",n_levels=" + string(n_levels, format="(I0)")
if exist(filter) then msg += ",filter=" + string(filter, format="(I0)") + ",sz_filter=" + string(sz_filter, format="(I0)")
if keyword_set(antarctica) then msg += ",/antarctica"
if keyword_set(shape_is_grounded) then msg += ",/shape_is_grounded"
if keyword_set(shapefile_meter) then msg += ",/shapefile_meter"
if keyword_set(apriori) then msg += ",/apriori"
if keyword_set(geotiff) then msg += ",/geotiff,post_north=" + string(post_north, format="(I0)") + ",post_east=" + string(post_east, format="(I0)")
if keyword_set(testing) then msg += ",/testing"
write_file,msg,"diff_to_meltrate.par",/verbose,/content

end
