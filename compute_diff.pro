; Procedure for computing the difference between two DEMs
; We do the computation twice, with the computed offset, and the already given apriori offset
; Actually five thing are computed (or three if there is no shapefile):
;  - without offset (a)
;  - with computed offset, without shapefile (b)
;  - with apriori offset, without shapefile (c)
;  - with computed offset, with shapefile (d)
;  - with apriori offset, with shapefile (e)

pro compute_diff,id1,id2,shapefile_loc,scale_rg,scale_line,min_dhdt=min_dhdt,max_dhdt=max_dhdt,sclx=sclx,scly=scly,n_levels=n_levels,shape_is_grounded=shape_is_grounded,shapefile_meter=shapefile_meter,antarctica=antarctica,testing=testing,skip_offset=skip_offset,scale_skip_offset=scale_skip_offset,geotiff=geotiff,post_north=post_north,post_east=post_east,verbose=verbose,apriori=apriori
; id1, id2: ids for images
; shapefile_loc: (optional) path to shapefile
; min/max: limits to put in the cleaned and png versions
; scl: scale factor in decimal for offset ex: 0.1 is 10%
; n_levels: number of colors in the colorbar in the png version
; shape_is_grounded (kw): shapefile is representing grounded ice, or floating ice shelf
;     w_in represents what's in the shape, w_out what's not
;     if shape_is_grounded, w_in is what is grounded
;     if not, w_in represents what's out
; shapefile_meter (kw): set to keep meters, leave empty to convert lat/lon to meters
; antarctica (kw): set if working on the southern hemisphere
; antarctica (kw): set if working on the southern hemisphere
; skip_offset (kw): skip the offset computation, and only compute the dhdt
; geotiff (kw): writes the data into a geotiff also
; apriori (kw): if we can use apriori files

if ~exist(min_dhdt) then min_dhdt = -10
if ~exist(max_dhdt) then max_dhdt = 10
if ~exist(n_levels) then n_levels = 200
if ~keyword_set(shape_is_grounded) then shape_is_grounded = 0
if ~keyword_set(shapefile_meter) then shapefile_meter = 0
if ~keyword_set(antarctica) then antarctica = 0
if ~keyword_set(skip_offset) then skip_offset = 0
if skip_offset and ~exist(scale_skip_offset) then print,"Error: If /skip_offset is set, scale_skip_offset is required to scale the image to a smaller size."
if ~keyword_set(apriori) then apriori = 0
if keyword_set(geotiff) and (~exist(post_north) or ~exist(post_east)) then begin
    print,"If /geotiff is set, please provide post_north and post_east."
    return
endif

; Getting the shape of the ice shelf
if shapefile_loc eq !null then skip_shapefile = 1 else skip_shapefile = 0
if ~skip_shapefile and ~skip_offset then begin

    ;Correction ER Oct. 2017
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

;window,0,xs=width*2,ys=length & !order=1 & tvscl,congrid(slave,width,length) & tvscl,mask_in,width,0

goto,jump1
    get_shapes,shapefile_loc,px_d,py_d,meters=shapefile_meter,antarctica=antarctica,/first
    beg = systime(/sec)
    shp2mask,px_d,py_d,id1,id2,id1 + ".DEM_gc_par",mask_in,mask_out,w_in,w_out,scale_rg,scale_line
    en = systime(/sec)
    if keyword_set(testing) and 0 then begin
        print,"shp2mask took ", en - beg, " seconds"
        get_width_lines,id1,id2,wid,len
        arr = fltarr(wid,len)
        arr[w_in] = 1
        winarn,arr
    endif
jump1:

endif

if ~skip_offset then begin
    if ~apriori then offset = read_offset(id1 + "-" + id2 + ".offmap.off")
    if apriori then offset_apriori = read_offset(id1 + "-" + id2 + ".off_apriori.off")
    if apriori then offset = offset_apriori
endif

slave = load_image(id2 + ".dat", parfile=id2 + ".DEM_gc_par", /bin)
master = load_image(id1 + ".dat", parfile=id1 + ".DEM_gc_par", /bin)

;Correction ER Oct. 2017
sz = size(slave)
width = sz[1] / scale_skip_offset
lines = sz[2] / scale_skip_offset
;end correction 

;Correction CC Sep. 2018
openw,lun,id1 + '-' + id2 + '.offmap.par',/get_lun
printf,lun,"width: " + string(width, format="(I0)")
printf,lun,"nlines: " + string(lines, format="(I0)")
free_lun,lun
;end correction

;if ~skip_offset then begin
;    get_width_lines,id1,id2,width,lines
;endif else begin
;    sz = size(slave)    
;    width = sz[1] / scale_skip_offset
;    lines = sz[2] / scale_skip_offset
;    openw,lun,id1 + '-' + id2 + '.offmap.par',/get_lun
;    printf,lun,"width:" + string(width, format="(I0)")
;    printf,lun,"nlines:" + string(lines, format="(I0)")
;    free_lun,lun
;endelse

print,'Size slave and master :',width,lines

slave_c = congrid(slave, width, lines, /interp)
master_c = congrid(master, width, lines, /interp)

; We delete missing values from master and slave, because they are -9999
; New technique, trying with abs() gt 1000
w_limit = 1000
w_slave = where((abs(slave_c) gt w_limit) or (abs(master_c) gt w_limit)) ;w_slave = where(slave_c eq -9999)
w_master = where((abs(master_c) gt w_limit) or (abs(slave_c) gt w_limit)) ;w_master = where(master_c eq -9999)

; Delete offset between the two images (called adjustment)
if ~apriori then get_adjustment,master_c - slave_c,id1 + '-' + id2 + ".offmap.off",adj,/wherediff
if apriori then get_adjustment,master_c - slave_c,id1 + '-' + id2 + ".off_apriori.off",adj,/wherediff
if keyword_set(verbose) then begin
    print,"adj for " + id1 + " and " + id2 + ":",adj
    openw,lun,id1 + "-" + id2 + ".adj",/get_lun
    printf,lun,adj
    free_lun,lun
endif
slave_c = slave_c - adj
diff_a = master_c - slave_c

; Actual computing
slave_c[w_slave] = 0
master_c[w_master] = 0

print,'Scale_rg in compute_diff :',scale_rg

if ~skip_offset then begin
    slave_c_t = translate_bilinear(slave_c, offset, sclx = sclx,scly = scly,scale = scale_rg)
    w_slave_tr = where(abs(slave_c_t) gt w_limit) ;w_slave_tr = where(slave_c_t eq -9999)
    if apriori then begin
        slave_c_t_apriori = translate_bilinear(slave_c, offset_apriori,sclx = sclx,scly=scly, scale = scale_rg)
        w_slave_a = where(abs(slave_c_t_apriori) gt w_limit) ;w_slave_a = where(slave_c_t_apriori eq -9999)
    endif
endif
diff_a[w_master] = 0
diff_a[w_slave] = 0
if ~skip_offset then begin
;Milillo P. Nov 30 2017 wrong master and slave order
;master_c correspond to id1 which is the earliest in time 
    diff_b = (slave_c_t-master_c)
    diff_b[w_master] = 0
    diff_b[w_slave_tr] = 0
    if apriori then begin 
;Milillo P. Nov 30 2017 wrong master and slave order
;master_c correspond to id1 which is the earliest in time 
        diff_c = (slave_c_t_apriori-master_c)
        diff_c[w_master] = 0
        diff_c[w_slave_a] = 0
    endif
    if ~skip_shapefile then begin
        diff_d = diff_b
        if apriori then diff_e = diff_c
        if keyword_set(shape_is_grounded) then begin
;October 2017 ER correction
            diff_d[w_out] = diff_a[w_out]
            if apriori then diff_e[w_out] = diff_a[w_out]
;end correction
        endif else begin
            diff_lagrange = diff_b
            diff_d = diff_a
            diff_d[w_in] = diff_lagrange[w_in]
            if apriori then begin
                diff_apriori = diff_c
                diff_e = diff_a
                diff_e[w_in] = diff_apriori[w_in]
            endif
        endelse
    endif
endif

; Make sure that we have meters per year
get_n_days,id1,id2,n_days
diff_a *= 365.25 / n_days
if ~skip_offset then begin
    diff_b *= 365.25 / n_days
    if apriori then diff_c *= 365.25 / n_days
    if ~skip_shapefile then begin
        diff_d *= 365.25 / n_days
        if apriori then diff_e *= 365.25 / n_days
    endif
endif

write_file,diff_a,id1 + "-" + id2 + ".dhdt",/verbose
if ~skip_offset then begin
    write_file,diff_b,id1 + "-" + id2 + ".dhdt_lagrange",/verbose
    if apriori then write_file,diff_c,id1 + "-" + id2 + ".dhdt_apriori",/verbose
    if ~skip_shapefile then begin
        write_file,diff_d,id1 + "-" + id2 + ".dhdt_lagrange_shp",/verbose
        if apriori then write_file,diff_e,id1 + "-" + id2 + ".dhdt_apriori_shp",/verbose
    endif
endif

; Delete unwanted parts of the computation (-9999 is unknown value, w_limit is set to 1000)
w = where((abs(slave_c) gt w_limit) or (abs(master_c) gt w_limit) or (~finite(slave_c)) or (~finite(master_c)))
;w = where((slave_c eq -9999) or (master_c eq -9999) or (~finite(slave_c)) or (~finite(master_c)))
diff_a[w] = 0
if ~skip_offset then begin
    w = where((abs(slave_c_t) gt w_limit) or (abs(master_c) gt w_limit) or (~finite(slave_c_t)) or (~finite(master_c)))
    ;w = where((slave_c_t eq -9999) or (master_c eq -9999) or (~finite(slave_c_t)) or (~finite(master_c)))
    diff_b[w] = 0
    if ~skip_shapefile then diff_d[w] = 0
    if apriori then begin
        w = where((abs(slave_c_t_apriori) gt w_limit) or (abs(master_c) gt w_limit) or (~finite(slave_c_t_apriori)) or (~finite(master_c)))
        ;w = where((slave_c_t_apriori eq -9999) or (master_c eq -9999) or (~finite(slave_c_t_apriori)) or (~finite(master_c)))
        diff_c[w] = 0 
        if ~skip_shapefile then diff_e[w] = 0
    endif
endif

diff_a = diff_a < max_dhdt
diff_a = diff_a > min_dhdt
if ~skip_offset then begin
    diff_b = diff_b < max_dhdt
    diff_b = diff_b > min_dhdt
    if apriori then begin
        diff_c = diff_c < max_dhdt
        diff_c = diff_c > min_dhdt
    endif
    if ~skip_shapefile then begin
        diff_d = diff_d < max_dhdt
        diff_d = diff_d > min_dhdt
        if apriori then begin
            diff_e = diff_e < max_dhdt
            diff_e = diff_e > min_dhdt
        endif
    endif
endif

write_file,diff_a,id1 + "-" + id2 + ".dhdt_cleaned",/verbose
if ~skip_offset then begin
    write_file,diff_b,id1 + "-" + id2 + ".dhdt_cleaned_lagrange",/verbose
    if apriori then write_file,diff_c,id1 + "-" + id2 + ".dhdt_cleaned_apriori",/verbose
    if ~skip_shapefile then begin
        write_file,diff_d,id1 + "-" + id2 + ".dhdt_cleaned_lagrange_shp",/verbose
        if apriori then write_file,diff_e,id1 + "-" + id2 + ".dhdt_cleaned_apriori_shp",/verbose
    endif
endif

;stop

; Save difference as image
names = [id1 + "-" + id2 + ".dhdt_cleaned", $
;         id1 + "-" + id2 +".dhdt_cleaned_lagrange", $
         id1 + "-" + id2  +".dhdt_cleaned_apriori", $
;         id1 + "-" + id2 + ".dhdt_cleaned_lagrange_shp", $
         id1 + "-" + id2 + ".dhdt_cleaned_apriori_shp"]

foreach name,names do begin
    if stregex(name, 'shp', /bool) and skip_shapefile then continue
    if stregex(name, 'cleaned_', /bool) and skip_offset then continue
    if stregex(name, 'apriori', /bool) and ~apriori then continue
    if ~keyword_set(geotiff) then begin
        plot_contour,name,paramfile=id1 + "-" + id2 + ".off_apriori.par",save_img=name, $
                 title="Height difference for " + id1 + " and " + id2, $
                 xtitle= "East-West (m)", ytitle="South-North (m)", $
                 cbtitle="Height difference (m)", ct_num=70, n_levels=n_levels, $
                 min_trunc=min_dhdt, max_trunc=max_dhdt, /white
    endif else begin
        plot_contour,name,paramfile=id1 + "-" + id2 + ".off_apriori.par",save_img=name, $
                 title="Height difference for " + id1 + " and " + id2, $
                 xtitle= "East-West (m)", ytitle="South-North (m)", $
                 cbtitle="Height difference (m)", ct_num=70, n_levels=n_levels, $
                 min_trunc=min_dhdt, max_trunc=max_dhdt, /white, $
                 /geotiff, id1=id1, post_north=post_north, post_east=post_east
    endelse
endforeach

; Print the parameters that were used for this procedure
msg = "compute_diff,'" + id1 + "','" + id2 + "','" + shapefile_loc + "'," + string(scale_rg, format="(I0)") + "," + string(scale_line, format="(I0)")
msg += ",min_dhdt=" + string(min_dhdt, format="(I0)") + ",max_dhdt=" + string(max_dhdt, format="(I0)") + ",n_levels=" + string(n_levels, format="(I0)") 
msg += ",sclx=" + string(sclx, format="(I2)")+ ",scly=" + string(scly, format="(I2)")
if keyword_set(shape_is_grounded) then msg += ",/shape_is_grounded"
if keyword_set(shapefile_meter) then msg += ",/shapefile_meter"
if keyword_set(antarctica) then msg += ",/antarctica"
if keyword_set(skip_offset) then msg += ",/skip_offset"
if keyword_set(scale_skip_offset) then msg += ",/skip_offset"
if keyword_set(geotiff) then msg += ",/geotiff,post_north=" + string(post_north, format="(I0)") + ",post_east=" + string(post_east, format="(I0)")
if keyword_set(apriori) then msg += ",/apriori"
if keyword_set(testing) then msg += ",/testing"
write_file,msg,"compute_diff.par",/verbose,/content

end
