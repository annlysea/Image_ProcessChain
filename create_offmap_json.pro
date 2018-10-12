; Procedure to launch multiple offmap computations

pro create_offmap_json,jsonfile,directory_name,skip_offmap=skip_offmap

json = load_json(jsonfile)
n_locations = n_elements(json)

if keyword_set(skip_offmap) then begin
    cd, current=current
    goto, goto_skip_offmap
endif

if file_test(directory_name, /directory) then file_delete, directory_name, /recursive
file_mkdir, directory_name
cd, directory_name, current=current
print,"Created " + directory_name
file_copy,current + "/" + jsonfile, jsonfile
print,"Jsonfile '" + jsonfile + "' copied into the directory."

for i=0,n_locations-1 do begin
    dems_l = json[i, "dems"]
    n_dems = n_elements(dems_l)

    for j=0,n_dems-1 do begin
        cd, current + "/" + directory_name ; create_offmap changes the working directory
        print,""
        print,"New offmap:"
        create_offmap, $
            dems_l[j, "master"] + "_dem.tif", dems_l[j, "slave"] + "_dem.tif", $
            dems_l[j, "id1"], dems_l[j, "id2"], $
            json[i, "pos_x"], json[i, "pos_y"], $
            json[i, "x_size"], json[i, "y_size"], $
            json[i, "nproc"], $
            json[i, "xoff"], json[i, "yoff"], $
            json[i, "rgspac"], json[i, "line_spac"], $
            json[i, "rgstep"], json[i, "line_step"], $
            filter=json[i, "filter"], $
            sz_filter=json[i, "sz_filter"], $
            ampcor_loc="/home/arnaud/", $
            tif_loc=current + "/", $
            prefix=string(i+1, format="(I0)") + "_", $
            shapefile_loc=json[i, "shapefile_loc"], $,$
            ;shapefile_var=json[i, "shapefile_var"], $
            min_meltrate=json[i, "min_meltrate"], $
            max_meltrate=json[i, "max_meltrate"], $
            comp=json[i, "comp"], $
            apriori=json[i, "apriori"], $
            antarctica=json[i, "antarctica"], $
            shape_is_grounded=json[i, "shape_is_grounded"], $
            ;shapefile_name=json[i, "shapefile_name"], $
            shapefile_meter=json[i, "shapefile_meter"], $
            skip_offset=json[i, "skip_offset"]
    endfor
endfor

cd, current + "/" + directory_name
goto_skip_offmap:

; Now we can work on the created offmaps
;for i=0,n_locations-1 do begin
;    dic = dictionary()
;    dems_l = json[i, "dems"]
;    n_dems = n_elements(dems_l)
;    for j=0,n_dems-1 do begin
;        dic['id' + string(j+1, format='(I0)') + '1'] = dems_l[j, 'id1']
;        dic['id' + string(j+1, format='(I0)') + '2'] = dems_l[j, 'id2']
;        print,"i=",i," j=",j," year=",strmid(dems_l[j, 'id1'], 0,4)," folder=",string(i+1, format='(I0)') + "_" + dems_l[j, 'id1'] + "-" + dems_l[j, 'id2'] + "-0000"
;        my_year = strmid(dems_l[j, 'id1'], 0,4)
;        w = where('year' + my_year eq years_d.keys(), c)
;        if ~c then print,"years_d['year" + my_year + "'] didn't exist before."
;        years_d['year' + my_year] = dictionary()
;    endfor
;    delvar,years_d
;    ; Is the next line ok? We should loop over the years, not the locations
;    ;combine_diff,dic,jsonfile,res_file='combined_diff_' + string(i+1, format="(I0)")
;    print,"dic:"
;    print,dic
;    delvar,dic
;endfor

years_d = dictionary()
for i=0,n_locations-1 do begin
    dems_l = json[i, "dems"]
    n_dems = n_elements(dems_l)
    for j=0,n_dems-1 do begin
        year1 = strmid(dems_l[j, 'id1'],0,4)
        year2 = strmid(dems_l[j, 'id2'],0,4)
        year = "year_" + year1 + "_" + year2
        ;ids = string(i+1, format="(I0)") + "_" + dems_l[j, 'id1'] + "-" + dems_l[j, 'id2'] + "-0000"
        ids = dems_l[j, 'id1'] + "-" + dems_l[j, 'id2']
        w = where(year eq years_d.keys(), c)
        if c then years_d[year] = append(years_d[year], ids) else years_d[year] = append([], ids)
    endfor
endfor

foreach y, years_d, key do begin
    dic = dictionary()
    foreach n, y, i do dic["diff" + string(i+1, format="(I0)")] = n
    combine_diff,dic,jsonfile,res_file='combined_diff_' + key
endforeach

cd, current

end
