; Function to return a mask, according to a grounding line.

pro gl2mask,px,py,id1,id2,paramfile,mask_in,mask_out,w_in,w_out,scale_rg,scale_line
; px, py: points defining the polygon
; img: image, as a 2d-array
; id1, id2: ids to link to the images
; paramfile: DEM_gc_par, to get positions of the image
; mask_in, mask_out: (result) variables that contain 0 or 1 depending on the position. Can be displayed via tvscl.
; w_in, w_out: (result) same information as mask_in and mask_out, only in the form of the result of the where function, to be used as a mask

get_width_lines,id1,id2,width,length
img = fltarr(width,length)

obj = obj_new("IDLanROI", px, py)

mask_in = intarr(width, length)
mask_out = intarr(width, length)

; We need to convert pixels into meters for the containspoints method to work.
north = long(read_keyword(paramfile, 'corner_north'))
east = long(read_keyword(paramfile, 'corner_east'))

; 1 pixel = 50 meters
post_north = - scale_line
post_east = scale_rg

; We use the containspoints method to determine what is in the mask
x = (findgen(width) * post_east + east)#(fltarr(length)+1)
y = (fltarr(width)+1)#(findgen(length) * post_north + north)

mask_in = obj->containspoints(x,y)
mask_out = ~mask_in

; Where is a really weird function
w_in = where(mask_in eq 1)
w_out = where(mask_out eq 1)

obj_destroy,obj
end
