; Procedure to retrieve every shape in a shapefile

pro get_shapes,shpname,px_d,py_d,meters=meters,antarctica=antarctica,first=first

if keyword_set(antarctica) then hemis = 's' else hemis = 'n'
if ~keyword_set(first) then first = 0

if ~exist(shpname) then shpname = '/u/pennell-z0/eric/acharola/gl-iceshelf/Greenland_Iceshelf_Basins_2016_PS_v1.4.shp'

is = shp2idl(shpname)

vert_prev = 0
part_prev = 0

if ~exist(px_d) then px_d = dictionary()
if ~exist(py_d) then py_d = dictionary()

foreach vert,is.n_vertices,i do begin ; foreach shape in shapefile
    if first then begin
        n_parts = is.n_parts[i]
        my_parts = reform(is.parts[part_prev: part_prev + n_parts - 1])
        if n_parts gt 1 then num_vert = my_parts[1] else num_vert = vert
    endif else num_vert = vert
    
    lon = reform(is.vertices[0, vert_prev: vert_prev + num_vert -1])
    lat = reform(is.vertices[1, vert_prev: vert_prev + num_vert -1])
    if keyword_set(meters) then begin
        px = lon
        py = lat
    endif else begin
        mapll,lat,lon,hemis,px,py
    endelse

    px_d["key" + string(i, format="(I0)")] = px
    py_d["key" + string(i, format="(I0)")] = py
    vert_prev += vert
    if first then part_prev += n_parts
endforeach

end
