; Combine different height differences into a single picture

pro combine_diff,dic,dem_json_file,suffix_folder=suffix_folder,res_file=res_file,reinitialize=reinitialize
; id_d should be a dictionary with at least 8 keys, named id11,id12, id21,id22, id31,id32, id41,id42
;     containing the ids used in the create_offmap function
; dem_json_file (str): path to dems.json file
; suffix_folder (str): default '0000'
; res_file (str): default 'combined_diff'

; TODO: get the number of keys in diff_d to make the code more flexible

; We assume the files are in subdirectories
if ~exist(suffix_folder) then suffix_folder = '0000'
if ~exist(res_file) then res_file = 'combined_dhdt'
    
dim = n_elements(dic)

diff_d = dictionary()
for i=1,dim do begin
    num = string(i, format='(I0)')
    fold = num + "_offmap-" + dic['diff' + num] + "-" + suffix_folder + "/"
    my_diff = load_image(fold + dic['diff' + num] + ".dhdt_cleaned")
    diff_d['diff' + num] = my_diff
endfor
;for i=1,4 do begin
;    num = string(i, format='(I0)')
;    id1 = id_d['id' + num + '1']
;    id2 = id_d['id' + num + '2']
;    fold = num + '_offmap-' + id1 + '-' + id2 + '-' + suffix_folder + '/'
;    my_diff = load_image(fold + id1 + '-' + id2 + '.dhdt_cleaned')
;    diff_d['diff' + num] = my_diff
;endfor

dems = load_json(dem_json_file)
n_img = n_elements(dems)

; Determining dimensions
xpositions = lonarr(4)
for i=0,3 do xpositions[i] = dems[i, "pos_x"]
begin_east = min(xpositions)
for i=0,3 do xpositions[i] += 2*dems[i, "x_size"]
end_east = max(xpositions)

ypositions = lonarr(4)
for i=0,3 do ypositions[i] = dems[i, "pos_y"]
end_north = max(ypositions)
for i=0,3 do ypositions[i] -= 2*dems[i, "y_size"]
begin_north = min(ypositions)

length_e = end_east - begin_east
length_n = end_north - begin_north

width = length_e / 50 + 1
lines = length_n / 50 + 1

new_img = fltarr(width, lines)
;print,"new_img, width:",width," lines:",lines

mymin = 0 ; mymin is bound to be negative
const = 10000 ; For overlapping
for i=0,n_img-1 do begin
    my_diff = diff_d["diff" + string(i+1, format="(I0)")]
    partial_img = reverse(my_diff, 2) + const
    partial_img[where(~finite(partial_img))] = 0 ; converts NaNs into 0
    ;print,"x:",(dems[i, "pos_x"] + 2 * dems[i, "x_size"] - begin_east) / 50 - (dems[i, "pos_x"] - begin_east) / 50
    ;print,"y:",(dems[i, "pos_y"] - begin_north) / 50 - (dems[i, "pos_y"] - 2 * dems[i, "y_size"] - begin_north) / 50
    ;help,partial_img
    if keyword_set(reinitialize) then begin
        new_img[(dems[i, "pos_x"] - begin_east) / 50:(dems[i, "pos_x"] + 2 * dems[i, "x_size"] - begin_east) / 50 - 2, $
                (dems[i, "pos_y"] - 2 * dems[i, "y_size"] - begin_north) / 50:(dems[i, "pos_y"] - begin_north) / 50 - 8] $
        = 0
    endif
    new_img[(dems[i, "pos_x"] - begin_east) / 50:(dems[i, "pos_x"] + 2 * dems[i, "x_size"] - begin_east) / 50 - 2, $
            (dems[i, "pos_y"] - 2 * dems[i, "y_size"] - begin_north) / 50:(dems[i, "pos_y"] - begin_north) / 50 - 8] $
        += partial_img
    ; -2 et -8 temporary, this is a bug that needs fixing
    mymin = min([mymin, min(my_diff)])
    ;print,cgPercentiles(diff_d["diff" + string(i+1, format="(I0)")], percent=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99])
endfor

; Deal with overlapping
for i=0,n_img-2 do begin
    w = where(new_img gt ((const+mymin) * (n_img - i)))
    new_img[w] = new_img[w] / (n_img - i)
endfor
w = where(new_img gt (const+2*mymin))
new_img[w] = new_img[w] - const

new_img[where(new_img gt 10)] = 10
new_img[where(new_img lt -10)] = -10

; Write image
openw,lun,res_file,/get_lun
printf,lun,new_img
free_lun,lun

; Write parameters, so that we can use load_image more easily
openw,lun,res_file + ".par", /get_lun
printf,lun,"width: " + string(width, format="(I0)")
printf,lun,"nlines: " + string(lines, format="(I0)")
free_lun,lun

print,""
print,"File written: " + res_file
print,"File written: " + res_file + ".par"
;print,res_file + " = load_image('" + res_file + "', par='" + res_file + ".par')"
;print,"winjer," + string(width, format="(I0)") + "," + string(lines, format="(I0)")
;print,"loadct,70"
;print,"tvscl," + res_file

end
