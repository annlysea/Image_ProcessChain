; Procedure to save images as a geotiff

pro data2geotiff_arn,datafile,id1,width,lines,post_north,post_east

print,"data2geotiff_arn,datafile:",datafile

set_result_demgcpar,id1,width,lines,datafile,post_north,post_east

dem_par_name = datafile + ".DEM_gc_par"
tifname = datafile + ".tif"

; Now we launch the GAMMA function
; 2 is for float
command = "data2geotiff " + dem_par_name + " " + datafile + " 2 " + tifname + " -9999"
print, command
spawn, command

end
