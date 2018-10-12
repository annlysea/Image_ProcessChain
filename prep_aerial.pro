pro prep_aerial,id1
; idl function prepare 
    
    print,id1+".slf"
    print,file_test(id1+".slf")
    if (~file_test(id1 + ".slf")) then begin
        print,"File not found, creating link for " + id1 + ".slf"
        file_link, id1 + ".dat", id1 + ".slf"
    endif
    cd,current=pwd
    
    ; print,"Current directory: " + pwd

    ;pwd0 = strsplit(pwd,'/', /extract)
    ;pwd = '/'
    ;for i=0,3 do pwd = pwd + pwd0[i]+'/'
    ;print,pwd

   ; file1 = id1+'.tif'
    
   ; if not file_test(id1+'.PS.tif') then $
   ;     spawn,'gdalwarp -t_srs EPSG:3413 -tr 2.0 2.0 '+file1+' '+id1+'.PS.tif'

    ;file1 = id1+'.PS.tif'
    ;geotiff2gc_par_ps,file1
    ;spawn,'mv DEM_gc_par '+id1+'.DEM_gc_par'

    ;a=read_tiff(file1)
    ;openw,1,id1+'.slf',/swap_if_little
    ;writeu,1,float(a)
    ;close,1

    ; Preparing the date
    year = strmid(id1,0,4)
    month = strmid(id1,4,2)
    day = strmid(id1,6,2)


    geo=load_geo_param(gc=id1+".DEM_gc_par")
    p1 = load_isp_param()
    p1.title = id1
    p1.sensor = 'AERIAL_PHOTO'
    p1.date[0] = year
    p1.date[1] = month
    p1.date[2] = day
    p1.npix = geo.npix
    p1.nrec = geo.nrec
    p1.xnlook = 1
    p1.ynlook = 1
    p1.image_format = 'FLOAT'
    p1.image_geometry = 'GROUND_RANGE'
    p1.range_scale_factor = 1.
    p1.azimuth_scale_factor = 1.
    p1.rgsp = geo.posting
    p1.azsp = geo.posting
    write_isp_param,id1+'.par',p1

    spawn,'multi_look_MLI '+id1+'.slf '+id1+'.par '+id1+'.mli '+id1+'.mli.par 10 10'
    spawn,'raspwr '+id1+'.mli '+strcompress(p1.npix/10,/r)+' - - - - 1 1'

    gradient_lsat,id1

    fin:     
end
