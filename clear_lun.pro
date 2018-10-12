; Procedure to close all open files if necessary

pro clear_lun

for i=1,128 do begin
    free_lun,i
endfor

end
