; Use the predict_tide script in IDL

pro predict_tide,lat,lon,date1,date2,output
; parameters
; lat/lon
; two dates
; output: result

; We have to work entirely in the folder where the predict_tide script is located
script_loc = '/home/arnaud/OTPS2/'
cd, script_loc, current=curd

if ~exist(lat) then lat = 81.3884
if ~exist(lon) then lon = -63.0957
if ~exist(date1) then date1 = '2014 04 25 12 0 0'
if ~exist(date2) then date2 = '2015 04 12 12 0 0'

; Writing parameters
openw,lun,'predict_tide.lat_lon_time',/get_lun
printf,lun,lat,lon,' ',date1
printf,lun,lat,lon,' ',date2
free_lun,lun

openw,lun,'predict_tide.setup'
printf,lun,'DATA/Model_AOTIM5'
printf,lun,'predict_tide.lat_lon_time'
printf,lun,'z'
printf,lun,''
printf,lun,''
printf,lun,''
printf,lun,'1'
printf,lun,'predict_tide.output'
free_lun,lun

; Launching script
spawn,'./predict_tide < predict_tide.setup'

; Move to original directory
file_move,['predict_tide.lat_lon_time', 'predict_tide.setup', 'predict_tide.output'], curd, /overwrite
cd, curd

; Read results
output = strarr(file_lines('predict_tide.output'))
openr,lun,'predict_tide.output',/get_lun
readf,lun,output
free_lun,lun

help,output & print,output
sz = n_elements(output)
print,"sz-3:",sz-3,"sz-1:",sz-1
sp1 = strsplit(output[6], /extract)
sp2 = strsplit(output[7], /extract)

z1 = sp1[4]
z2 = sp2[4]



end
