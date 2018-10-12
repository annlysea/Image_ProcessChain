; Function to return a mask, according to a shapefile of iceshelves

;Modified by ER Oct. 2017. Lots of confusing points ...

pro shp2mask,px_d,py_d,id1,id2,paramfile,mask_in,mask_out,w_in,w_out,scale_rg,scale_line
; px_d, py_d: points defining the polygons, from the get_shapes procedure
; id1, id2: ids to link to the images
; paramfile: DEM_gc_par, to get positions of the image
; mask_in, mask_out: (result) variables that contain 0 or 1 depending on the position. Can be displayed via tvscl.
; w_in, w_out: (result) same information as mask_in and mask_out, only in the form of the result of the where function, to be used as a mask


slave = load_image(id2 + ".dat", parfile=id2 + ".DEM_gc_par", /bin)
master = load_image(id1 + ".dat", parfile=id1 + ".DEM_gc_par", /bin)

;Correction ER Oct. 2017
sz = size(slave)
width = sz[1] / scale_rg
length = sz[2] / scale_line
;end correction 

;get_width_lines,id1,id2,width,length

mask_in = intarr(width, length)
mask_out = intarr(width, length)

; We need to convert pixels into meters for the containspoints method to work.
north = long(read_keyword(paramfile, 'corner_north'))
east = long(read_keyword(paramfile, 'corner_east'))
post = long(read_keyword(paramfile, 'post_east'))

;Correction ER Oct. 2017
post_north = - scale_line*post
post_east = scale_rg*post
;end correction 

x = (findgen(width) * post_east + east)#(fltarr(length)+1)
y = (fltarr(width)+1)#(findgen(length) * post_north + north)

foreach val,px_d,key do begin

    px = px_d[key]
    py = py_d[key]

    obj = obj_new("IDLanROI", px, py)

    mask_in += obj->containspoints(x,y)
    
    obj_destroy,obj
endforeach

mask_in = mask_in < 1
mask_out = ~mask_in

; Where is a really weird function
w_in = where(mask_in eq 1)
w_out = where(mask_out eq 1)

end
