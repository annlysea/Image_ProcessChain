; Procedure to retrieve the vertices of a shapefile

pro get_shapefile,shpname,var,px,py,is,name=name,meters=meters,antarctica=antarctica,first_part=first_part,testing=testing
; shpname: location of file
; var: number, to get the right shape inside of the shapefile, or string if name is set
; px, py: points defining the polygon. These are variables that will be set by the procedure
; is: the shapefile as a variable
; name (kw): to chose the shape inside the shapefile with the name instead of the id
; meters (kw): leave empty to translate lat/lon into meters. Set to keep meters
; first_part (kw): set if you only want the first part 

if keyword_set(antarctica) then hemis = 's' else hemis = 'n'

is = shp2idl(shpname)

if keyword_set(name) then begin
    w = where(is.name eq var)
endif else begin
    w = where(is.id eq var)
endelse
i = w[0]

if keyword_set(testing) then begin
    print,"n_parts:",is.n_parts[i]
    print,"i:",i
    print,"parts:",is.parts
    help,is.parts
    n_parts_min = (i eq 0)? 0: total(is.n_parts[0:i-1])
    print,"n_parts_min:",n_parts_min
    my_parts = reform(is.parts[n_parts_min:n_parts_min+is.n_parts[i]-1])
    print,"my_parts:",my_parts
    print,"n_vertices:",is.n_vertices[i]
endif

if keyword_set(first_part) then begin
    n_parts_min = (i eq 0)? 0: total(is.n_parts[0:i-1])
    my_parts = reform(is.parts[n_parts_min:n_parts_min+is.n_parts[i]-1])
    vert_number = my_parts[1] -1
endif else begin
    vert_number = is.n_vertices[i] -1
endelse

print,vert_number

N_VERTICES_min = (i eq 0)? 0: total(is.N_VERTICES[0:i-1])
lon = reform(is.vertices[0,N_VERTICES_min:N_VERTICES_min+vert_number])
lat = reform(is.vertices[1,N_VERTICES_min:N_VERTICES_min+vert_number])
;lon = reform(is.vertices[0,N_VERTICES_min:N_VERTICES_min+is.N_VERTICES[i]-1])
;lat = reform(is.vertices[1,N_VERTICES_min:N_VERTICES_min+is.N_VERTICES[i]-1])

if keyword_set(meters) then begin
    px = lon
    py = lat
endif else begin
    mapll,lat,lon,hemis,px,py
endelse

end
