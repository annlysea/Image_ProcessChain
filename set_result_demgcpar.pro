; Procedure to create the result DEM_gc_par, in order to allow the creation of geotiffs

pro set_result_demgcpar,id1,width,lines,datafile,post_north,post_east

print,"set_result_demgcpar,datafile:",datafile

name_res = datafile +  ".DEM_gc_par"
name_par = id1 + ".DEM_gc_par"

if file_test(name_res) then return

content=strarr(file_lines(name_par))
openr,1,name_par
readf,1,content
close,1

content[0] = "title: " + datafile + ".tif"
content[5] = "width:     " + string(width, format='(F16.0)')
content[6] = "nlines:     " + string(lines, format='(F16.0)')
content[9] = "post_north:     " + string(post_north, format='(F16.3)') + " m"
content[9] = "post_north:     " + string(post_north, format='(F16.3)') + " m"
content[10] = "post_east:     " + string(post_east, format='(F16.3)') + " m"

openw,1,name_res
mysize=size(content, /dimensions)
for i=0,mysize[0]-1 do printf,1,content[i]
close,1
delvar, content

end
